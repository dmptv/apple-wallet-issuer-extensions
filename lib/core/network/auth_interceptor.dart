import 'package:dio/dio.dart';

import 'token_storage.dart';

/// Signature of the call that exchanges a refresh token for a new pair.
/// Injected rather than hard-wired so the interceptor can be unit-tested with a
/// counting spy, and so the refresh endpoint can use a *separate* Dio instance
/// (see [AuthInterceptor] docs) without a circular dependency.
typedef RefreshTokens = Future<AuthTokens> Function(String refreshToken);

/// Attaches the access token to every request and refreshes it exactly once
/// when several requests hit 401 at the same time.
///
/// ## The single-flight invariant
///
/// Without deduplication, N concurrent requests failing with 401 trigger N
/// refresh calls. That is not just wasteful: with rotating refresh tokens the
/// second call presents an already-consumed token and the whole session is
/// invalidated, logging the user out mid-session.
///
/// The mechanism is [_refreshCall] — a stored in-flight `Future`. The first
/// caller creates it; everyone else awaits the same one.
///
/// ## Why no lock is needed
///
/// A Dart isolate is single-threaded and only yields at an `await`. The check
/// (`if (_refreshCall != null)`) and the assignment (`_refreshCall = ...`) sit
/// between two suspension points with no `await` in between, so no other
/// callback can interleave and the check-then-act is atomic by construction.
/// Move the assignment after an `await` and the race returns immediately.
///
/// (In Swift the same pattern needs an `actor` to serialize access, because
/// tasks there really can run on different threads.)
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this._storage,
    required RefreshTokens refreshTokens,
  })  : _refresh = refreshTokens;

  final TokenStorage _storage;
  final RefreshTokens _refresh;

  /// The in-flight refresh, or null when no refresh is running.
  Future<AuthTokens>? _refreshCall;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Opt-out hatch: the refresh endpoint itself and the login call must not
    // carry (or try to renew) an access token, otherwise a failing refresh
    // recurses into itself.
    if (options.extra[skipAuthKey] == true) {
      return handler.next(options);
    }

    final tokens = await _storage.read();
    if (tokens != null) {
      // Proactive refresh: renewing *before* sending saves a guaranteed-failing
      // round trip. The reactive 401 path below still exists because the server
      // may revoke a token that has not yet expired.
      final fresh = tokens.isExpired() ? await _runRefresh(tokens) : tokens;
      if (fresh != null) {
        options.headers['Authorization'] = 'Bearer ${fresh.accessToken}';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final isAuthError = err.response?.statusCode == 401;
    final alreadyRetried = err.requestOptions.extra[_retriedKey] == true;
    final skipsAuth = err.requestOptions.extra[skipAuthKey] == true;

    // Retry at most once. Without this guard a server that answers 401 to a
    // freshly minted token puts the client in an infinite refresh loop.
    if (!isAuthError || alreadyRetried || skipsAuth) {
      return handler.next(err);
    }

    final current = await _storage.read();
    if (current == null) return handler.next(err);

    final fresh = await _runRefresh(current);
    if (fresh == null) return handler.next(err);

    final retried = err.requestOptions
      ..extra[_retriedKey] = true
      ..headers['Authorization'] = 'Bearer ${fresh.accessToken}';

    try {
      // A separate Dio would be cleaner still; using the same one is safe here
      // only because [_retriedKey] stops the second pass through this method.
      final response = await Dio().fetch<dynamic>(retried);
      handler.resolve(response);
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  /// Runs a refresh, or joins the one already running.
  ///
  /// Returns null when refreshing failed — the caller then lets the original
  /// 401 propagate so the app can route the user to re-authentication.
  Future<AuthTokens?> _runRefresh(AuthTokens current) async {
    // ── critical section: no `await` between the read and the write ──
    final existing = _refreshCall;
    if (existing != null) {
      // Someone else is already refreshing. Wait for *their* result instead of
      // starting a second call. This is the whole point of the interceptor.
      return _awaitQuietly(existing);
    }
    final call = _refresh(current.refreshToken);
    _refreshCall = call;
    // ── end critical section ──

    try {
      final tokens = await call;
      await _storage.write(tokens);
      return tokens;
    } catch (_) {
      // The refresh token is dead: drop the session so the next request does
      // not attempt to use it again.
      await _storage.clear();
      return null;
    } finally {
      // Cleared on both paths. Leaving a failed Future cached would make every
      // later refresh replay the same failure forever.
      _refreshCall = null;
    }
  }

  Future<AuthTokens?> _awaitQuietly(Future<AuthTokens> call) async {
    try {
      return await call;
    } catch (_) {
      return null;
    }
  }

  /// Marks a request as not requiring (or triggering) authentication.
  static const skipAuthKey = 'skip_auth';
  static const _retriedKey = 'retried_after_refresh';
}
