import 'package:dio/dio.dart';

import '../constants/app_constants.dart';
import '../storage/secure_storage_service.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';

/// Builds the single configured [Dio] instance used by every remote data
/// source. 30s timeouts and the auth + error interceptors are wired here.
class DioClient {
  DioClient._();

  static Dio create({
    required SecureStorageService storage,
    void Function()? onUnauthorized,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: AppConstants.httpTimeout,
        receiveTimeout: AppConstants.httpTimeout,
        sendTimeout: AppConstants.httpTimeout,
        contentType: 'application/json',
        responseType: ResponseType.json,
        headers: {'Accept': 'application/json'},
      ),
    );

    dio.interceptors.addAll([
      AuthInterceptor(storage),
      ErrorInterceptor(onUnauthorized: onUnauthorized),
    ]);

    return dio;
  }
}
