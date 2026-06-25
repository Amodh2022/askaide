import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';
import '../storage/secure_storage_service.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';
import 'interceptors/refresh_interceptor.dart';

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

    // The refresh interceptor needs a reference to the client to replay the
    // original request after obtaining a fresh token.
    final refresh = RefreshInterceptor(storage)..dio = dio;

    dio.interceptors.addAll([
      AuthInterceptor(storage),
      refresh,
      ErrorInterceptor(onUnauthorized: onUnauthorized),
    ]);

    // Log every request/response (and errors) to the console in debug builds
    // only, so headers and bodies never leak in release.
    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          request: true,
          requestHeader: true,
          requestBody: true,
          responseHeader: false,
          responseBody: true,
          error: true,
          logPrint: (object) => debugPrint(object.toString()),
        ),
      );
    }

    return dio;
  }
}
