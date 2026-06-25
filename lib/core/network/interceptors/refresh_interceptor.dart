import 'package:dio/dio.dart';

import '../../constants/app_constants.dart';
import '../../storage/secure_storage_service.dart';
import '../endpoints.dart';

/// Transparently refreshes an expired access token, mirroring the web client's
/// axios interceptor.
///
/// On a `401` whose body carries `error: "tokenExpired"`, it calls
/// `/authenticate/refresh` with the stored refresh token, persists the new
/// token pair, and replays the original request. Concurrent requests that fail
/// while a refresh is already in flight wait on the same single-flight future
/// instead of triggering a stampede of refresh calls.
///
/// Any other `401` (missing/invalid token, revoked refresh) is passed through
/// to the [ErrorInterceptor], which performs the forced logout.
class RefreshInterceptor extends Interceptor {
  RefreshInterceptor(this._storage);

  final SecureStorageService _storage;

  /// Reference to the main client, set by [DioClient] once it is built. Used to
  /// replay the original request with the refreshed token.
  late final Dio dio;

  /// Bare client (no interceptors) used for the refresh call itself, so the
  /// refresh request never recurses through this interceptor.
  final Dio _refreshDio = Dio(
    BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: AppConstants.httpTimeout,
      receiveTimeout: AppConstants.httpTimeout,
      sendTimeout: AppConstants.httpTimeout,
      contentType: 'application/json',
      headers: {'Accept': 'application/json'},
    ),
  );

  /// Single-flight guard: the in-progress refresh, shared by all callers that
  /// hit a `tokenExpired` while it is running. Resolves to the new access
  /// token, or `null` if the refresh failed.
  Future<String?>? _refreshing;

  static const _retriedFlag = 'refresh_retried';

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final isExpired = err.response?.statusCode == 401 &&
        _errorCode(err.response) == 'tokenExpired';
    final alreadyRetried = options.extra[_retriedFlag] == true;
    final isRefreshCall = options.path.contains(Endpoints.refresh);

    if (!isExpired || alreadyRetried || isRefreshCall) {
      return handler.next(err);
    }

    final newToken = await (_refreshing ??= _refresh());
    // Clear the guard so a later expiry can refresh again.
    _refreshing = null;

    if (newToken == null || newToken.isEmpty) {
      // Refresh failed — let the ErrorInterceptor force the logout.
      return handler.next(err);
    }

    try {
      options
        ..extra[_retriedFlag] = true
        ..headers['Authorization'] = 'Bearer $newToken';
      final response = await dio.fetch<dynamic>(options);
      return handler.resolve(response);
    } on DioException catch (e) {
      return handler.next(e);
    }
  }

  /// Performs the refresh call. Returns the new access token, or `null` on any
  /// failure (clearing the stored tokens so the next 401 falls through to the
  /// forced logout).
  Future<String?> _refresh() async {
    final refreshToken = await _storage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return null;

    try {
      final res = await _refreshDio.post<dynamic>(
        Endpoints.refresh,
        data: {'refreshToken': refreshToken},
      );
      final data = res.data;
      if (data is! Map || data['success'] != true) return null;

      final tokens = data['tokens'];
      if (tokens is! Map) return null;
      final accessToken = tokens['accessToken']?.toString();
      final newRefresh = tokens['refreshToken']?.toString();
      if (accessToken == null || accessToken.isEmpty) return null;

      await _storage.writeToken(accessToken);
      if (newRefresh != null && newRefresh.isNotEmpty) {
        await _storage.writeRefreshToken(newRefresh);
      }
      return accessToken;
    } catch (_) {
      await _storage.clear();
      return null;
    }
  }

  String? _errorCode(Response? response) {
    final data = response?.data;
    if (data is Map) return data['error']?.toString();
    return null;
  }
}
