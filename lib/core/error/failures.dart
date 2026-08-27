/// Domain-level error vocabulary.
///
/// Design note: the data layer throws [AppException]s; a mapper converts them
/// into these [Failure]s at the repository boundary. Everything above the
/// repository speaks only [Failure] — no Dio types, no SQL errors, no HTTP
/// status codes leak upward.
///
/// Why a sealed class and not an enum: failures carry payloads (a retry-after
/// duration, a server-supplied message, the offending field). Dart 3 sealed
/// classes give exhaustive `switch` in the UI without a default branch, so
/// adding a new failure type becomes a compile error at every call site that
/// must handle it.
sealed class Failure {
  const Failure({this.message});

  /// Human-readable text, when the source produced one worth showing.
  /// The presentation layer decides whether to trust it — never show raw
  /// server text for security-sensitive flows.
  final String? message;
}

/// No usable connection, request timed out, DNS failure, socket closed.
/// Retryable by definition — the request never reached a decision.
final class NetworkFailure extends Failure {
  const NetworkFailure({super.message});
}

/// Server answered, but with 5xx. The request may or may not have been applied,
/// which is exactly why write operations need idempotency keys.
final class ServerFailure extends Failure {
  const ServerFailure({super.message, this.statusCode});

  final int? statusCode;
}

/// 401/403 — the session is gone or insufficient. The app must re-authenticate
/// rather than retry.
final class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({super.message});
}

/// The server rejected the request on business grounds and named a reason.
///
/// [code] is the machine-readable reason (e.g. `CARD_EXPIRED`). The UI switches
/// on the code, not on [message] — server text changes without notice and is
/// often not localized.
final class BusinessFailure extends Failure {
  const BusinessFailure({required this.code, super.message});

  final String code;
}

/// Local storage failed: disk full, corrupted database, migration error.
/// Distinct from [NetworkFailure] because the recovery is different — retrying
/// will not help, the cache needs to be rebuilt.
final class CacheFailure extends Failure {
  const CacheFailure({super.message});
}

/// Anything we failed to classify. Kept deliberately narrow: every occurrence
/// in production logs is a signal that the mapper is missing a case.
final class UnknownFailure extends Failure {
  const UnknownFailure({super.message, this.cause});

  final Object? cause;
}
