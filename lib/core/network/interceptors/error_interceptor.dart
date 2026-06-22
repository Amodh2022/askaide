import 'package:dio/dio.dart';

import '../../error/exceptions.dart';

/// Normalises Dio errors into our typed [Exception]s and, on 401, fires an
/// [onUnauthorized] hook so the app can clear the session and redirect to
/// login. Repositories then translate these exceptions into [Failure]s.
class ErrorInterceptor extends Interceptor {
  ErrorInterceptor({this.onUnauthorized});

  final void Function()? onUnauthorized;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final response = err.response;
    final status = response?.statusCode;

    Exception mapped;
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        mapped = NetworkException('Request timed out. Please try again.');
      case DioExceptionType.connectionError:
        mapped = NetworkException();
      case DioExceptionType.badResponse:
        if (status == 401 || status == 403) {
          onUnauthorized?.call();
          mapped = UnauthorizedException(_message(response) ?? 'Unauthorized');
        } else {
          mapped = ServerException(
            _message(response) ?? 'Server error',
            statusCode: status,
          );
        }
      case DioExceptionType.cancel:
        mapped = ServerException('Request cancelled', statusCode: status);
      default:
        mapped = ServerException(
          _message(response) ?? err.message ?? 'Unexpected error',
          statusCode: status,
        );
    }

    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: mapped,
      ),
    );
  }

  String? _message(Response? response) {
    final data = response?.data;
    if (data is Map) {
      return (data['message'] ?? data['error'] ?? data['msg'])?.toString();
    }
    return null;
  }
}
