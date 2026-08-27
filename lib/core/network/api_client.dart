import 'package:dio/dio.dart';

import '../error/exceptions.dart';

/// Thin wrapper over Dio that data sources talk to.
///
/// Two jobs, and deliberately no more:
///  1. unwrap the typed [AppException] that [ErrorInterceptor] attached, so no
///     data source ever imports `DioException`;
///  2. guarantee the response body has the shape the caller asked for, turning
///     a silent `null`/wrong-type into a loud [ParseException].
///
/// Everything policy-related — base URL, timeouts, headers, auth, logging —
/// lives in the interceptors and in the Dio instance built by the DI module,
/// not here. That keeps this class trivial to reason about and to fake.
class ApiClient {
  const ApiClient(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> getObject(
    String path, {
    Map<String, dynamic>? query,
    CancelToken? cancelToken,
  }) async {
    final data = await _get<dynamic>(path, query: query, cancelToken: cancelToken);
    if (data is! Map<String, dynamic>) {
      throw ParseException('Expected a JSON object at $path, got ${data.runtimeType}');
    }
    return data;
  }

  Future<List<Map<String, dynamic>>> getList(
    String path, {
    Map<String, dynamic>? query,
    CancelToken? cancelToken,
  }) async {
    final data = await _get<dynamic>(path, query: query, cancelToken: cancelToken);
    if (data is! List) {
      throw ParseException('Expected a JSON array at $path, got ${data.runtimeType}');
    }
    // Validating each element here (instead of letting `cast` fail lazily at an
    // arbitrary later point) keeps the stack trace pointing at the request.
    return data.map((e) {
      if (e is! Map<String, dynamic>) {
        throw ParseException('Expected objects in the array at $path');
      }
      return e;
    }).toList(growable: false);
  }

  Future<T> _get<T>(
    String path, {
    Map<String, dynamic>? query,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<T>(
        path,
        queryParameters: query,
        cancelToken: cancelToken,
      );
      final data = response.data;
      if (data == null) {
        throw ParseException('Empty body from $path');
      }
      return data;
    } on DioException catch (e) {
      // ErrorInterceptor always populates `error`; the fallback exists so a
      // misconfigured Dio (interceptor not registered) fails loudly rather than
      // throwing a raw DioException into the domain.
      final inner = e.error;
      if (inner is AppException) throw inner;
      throw NetworkException(e.message ?? 'Request failed');
    }
  }
}
