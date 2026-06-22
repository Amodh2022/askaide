import 'package:dio/dio.dart';

import '../../storage/secure_storage_service.dart';

/// Injects `Authorization: Bearer <token>` on every outgoing request when a
/// JWT is present. Reads from secure storage on each request so a fresh login
/// is picked up without rebuilding the Dio client.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._storage);

  final SecureStorageService _storage;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.readToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
