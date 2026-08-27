/// Where access/refresh tokens live.
///
/// Abstracted so that the interceptor never knows whether tokens sit in
/// Keychain, in an encrypted database, or (in tests) in a plain field.
/// In production this would be backed by `flutter_secure_storage`, which maps
/// to Keychain on iOS and EncryptedSharedPreferences on Android.
abstract interface class TokenStorage {
  Future<AuthTokens?> read();
  Future<void> write(AuthTokens tokens);
  Future<void> clear();
}

class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;

  /// A safety margin matters: a token that expires in 200 ms is, for practical
  /// purposes, already expired by the time the request reaches the server.
  bool isExpired({Duration leeway = const Duration(seconds: 30)}) {
    return DateTime.now().add(leeway).isAfter(expiresAt);
  }

  AuthTokens copyWith({
    String? accessToken,
    String? refreshToken,
    DateTime? expiresAt,
  }) {
    return AuthTokens(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}

/// Development stand-in. Deliberately NOT wired into the production DI graph —
/// see `register_module.dart` for how the real implementation is bound.
class InMemoryTokenStorage implements TokenStorage {
  AuthTokens? _tokens;

  InMemoryTokenStorage([this._tokens]);

  @override
  Future<AuthTokens?> read() async => _tokens;

  @override
  Future<void> write(AuthTokens tokens) async => _tokens = tokens;

  @override
  Future<void> clear() async => _tokens = null;
}
