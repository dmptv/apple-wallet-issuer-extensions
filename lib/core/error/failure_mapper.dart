import 'exceptions.dart';
import 'failures.dart';

/// Single place where data-layer exceptions become domain failures.
///
/// Keeping this in one function (rather than scattering try/catch translation
/// across repositories) means there is exactly one file to open when the UI
/// shows the wrong error, and exactly one file to extend when the backend adds
/// a new error contract.
Failure mapExceptionToFailure(Object error) {
  return switch (error) {
    NetworkException(:final message) => NetworkFailure(message: message),
    // 401/403 is not "a server error" — it is a session problem with a
    // completely different recovery path, so it is split out before the
    // generic status-code handling below.
    HttpException(statusCode: 401 || 403, :final message) =>
      UnauthorizedFailure(message: message),
    // A named business reason wins over the status code: `409 CARD_EXPIRED`
    // is a business outcome the UI must handle explicitly, not a transport
    // problem to retry.
    HttpException(:final errorCode?, :final message) =>
      BusinessFailure(code: errorCode, message: message),
    HttpException(:final statusCode, :final message) =>
      ServerFailure(message: message, statusCode: statusCode),
    CacheException(:final message) => CacheFailure(message: message),
    // A parse error is a contract violation. It is deliberately surfaced as
    // "unknown" to the user (there is no useful action) while keeping the
    // cause attached for logging.
    ParseException(:final message) =>
      UnknownFailure(message: message, cause: error),
    _ => UnknownFailure(cause: error),
  };
}
