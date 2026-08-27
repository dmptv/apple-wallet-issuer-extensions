import 'package:dio/dio.dart';

import '../error/exceptions.dart';

/// Translates Dio's transport vocabulary into our own [AppException]s.
///
/// The purpose is containment: `DioException` should not appear anywhere above
/// this file. Swapping Dio for `http` or `chopper` later would then touch this
/// interceptor and nothing else.
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final exception = _translate(err);

    // `handler.reject` keeps the failure flowing through Dio's error channel,
    // with our exception attached. Data sources then unwrap `err.error`
    // instead of inspecting Dio types.
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: exception,
      ),
    );
  }

  AppException _translate(DioException err) {
    return switch (err.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        const NetworkException('Request timed out'),
      DioExceptionType.connectionError =>
        const NetworkException('No connection to the server'),
      // A cancelled request is not a failure the user should ever see — it
      // usually means the screen was closed. Still typed, so callers can
      // recognise and silently drop it.
      DioExceptionType.cancel => const NetworkException('Request cancelled'),
      DioExceptionType.badCertificate =>
        const NetworkException('Certificate validation failed'),
      DioExceptionType.badResponse => _fromResponse(err.response),
      DioExceptionType.unknown => NetworkException(err.message ?? 'Network error'),
      // `transformTimeout` covers Dio's request/response transformer step —
      // rare in practice, folded into the generic network bucket rather than
      // given its own user-facing distinction.
      DioExceptionType.transformTimeout =>
        const NetworkException('Request timed out'),
    };
  }

  AppException _fromResponse(Response<dynamic>? response) {
    final status = response?.statusCode ?? 0;
    final body = response?.data;

    // Backends differ in where they put the machine-readable reason. Reading
    // defensively here (rather than decoding into a strict model) keeps a
    // malformed error body from masking the real HTTP status.
    String? errorCode;
    String? message;
    if (body is Map<String, dynamic>) {
      errorCode = body['code'] as String? ?? body['reason'] as String?;
      message = body['message'] as String? ?? body['error'] as String?;
    }

    return HttpException(
      message ?? 'Server returned $status',
      statusCode: status,
      errorCode: errorCode,
    );
  }
}
