/// Data-layer exceptions.
///
/// These exist so that data sources can fail in a typed way without knowing
/// anything about the domain. A data source never constructs a `Failure` —
/// that is the repository's job, because only the repository knows whether a
/// missing cache entry is an error at all (often it is just "no data yet").
sealed class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// Transport-level problem: timeout, connection refused, TLS failure.
final class NetworkException extends AppException {
  const NetworkException(super.message);
}

/// The server responded with a non-2xx status.
final class HttpException extends AppException {
  const HttpException(super.message, {required this.statusCode, this.errorCode});

  final int statusCode;

  /// Machine-readable business reason from the response body, when present.
  /// This is what becomes [BusinessFailure.code] upstream.
  final String? errorCode;
}

/// The response was 2xx but its shape did not match the contract.
///
/// Worth a dedicated type: this is always a bug (ours or the backend's), never
/// a user-facing condition, and it should be loud in logs and silent in the UI.
final class ParseException extends AppException {
  const ParseException(super.message);
}

/// Local database read/write failed.
final class CacheException extends AppException {
  const CacheException(super.message);
}
