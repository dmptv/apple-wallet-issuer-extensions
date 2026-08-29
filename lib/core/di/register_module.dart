import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../database/app_database.dart';
import '../native/idemia_card_api.g.dart';
import '../native/secure_card_display_api.g.dart';
import '../network/api_client.dart';
import '../network/auth_interceptor.dart';
import '../network/error_interceptor.dart';
import '../network/token_storage.dart';

/// Registrations for types we do not own and therefore cannot annotate.
///
/// This is the composition root in the sense the term is usually meant: the one
/// place where concrete implementations are chosen and wired. Nothing below
/// this file names a concrete class it depends on — everything asks for an
/// interface.
@module
abstract class RegisterModule {
  /// Base URL per environment. Hardcoding it anywhere else is how a staging
  /// URL ends up in a production build.
  @Named('baseUrl')
  @dev
  String get devBaseUrl => 'https://api.staging.example-bank.kz/v1';

  @Named('baseUrl')
  @prod
  String get prodBaseUrl => 'https://api.example-bank.kz/v1';

  @lazySingleton
  AppDatabase get database => AppDatabase();

  /// In-memory for now. Swapping to `flutter_secure_storage` later touches
  /// this line only — every consumer depends on the interface.
  @lazySingleton
  TokenStorage get tokenStorage => InMemoryTokenStorage();

  @lazySingleton
  Dio dio(@Named('baseUrl') String baseUrl, TokenStorage storage) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        // Two separate timeouts, on purpose. A connect timeout should be short
        // — either the server answers quickly or the network is bad. A receive
        // timeout must tolerate slow endpoints (statements, exports) without
        // killing them.
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        // Dio treats non-2xx as an error by default, which is what we want:
        // every failure reaches ErrorInterceptor instead of being handled ad
        // hoc at each call site.
        headers: const {'Accept': 'application/json'},
      ),
    );

    dio.interceptors.addAll([
      AuthInterceptor(
        storage: storage,
        // Uses a bare Dio so a failing refresh cannot recurse back through the
        // auth interceptor. The alternative — flagging the request with
        // `skipAuth` — works too, but a separate client makes the boundary
        // impossible to get wrong later.
        refreshTokens: (refreshToken) => _refresh(baseUrl, refreshToken),
      ),
      // Order matters: error translation runs last so it sees failures the
      // auth interceptor decided not to recover from.
      ErrorInterceptor(),
    ]);

    return dio;
  }

  @lazySingleton
  ApiClient apiClient(Dio dio) => ApiClient(dio);

  /// The Pigeon-generated client for the native IDEMIA bridge. No `Dio`, no
  /// interceptors — this Future crosses a `MethodChannel` to `ios/Runner`, not
  /// the network, so none of the HTTP-layer plumbing above applies to it.
  @lazySingleton
  IdemiaCardHostApi idemiaCardHostApi() => IdemiaCardHostApi();

  @lazySingleton
  SecureCardDisplayHostApi secureCardDisplayHostApi() => SecureCardDisplayHostApi();
}

/// Exchanges a refresh token for a new pair.
///
/// Kept as a free function rather than a service so the auth interceptor has no
/// dependency that could, transitively, depend on the interceptor itself.
Future<AuthTokens> _refresh(String baseUrl, String refreshToken) async {
  final response = await Dio(BaseOptions(baseUrl: baseUrl)).post<Map<String, dynamic>>(
    '/auth/refresh',
    data: {'refreshToken': refreshToken},
  );

  final body = response.data!;
  return AuthTokens(
    accessToken: body['accessToken'] as String,
    // A server that does not rotate the refresh token returns null — keeping
    // the existing one is required, otherwise the session dies on the next
    // refresh. This exact case is easy to miss and expensive to debug.
    refreshToken: body['refreshToken'] as String? ?? refreshToken,
    expiresAt: DateTime.now().add(
      Duration(seconds: body['expiresIn'] as int? ?? 3600),
    ),
  );
}
