import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/app_constants.dart';

/// Contract for sensitive-value persistence — primarily the JWT access and
/// refresh tokens. Consumers (Dio, the interceptors, [AuthRepositoryImpl])
/// depend on this abstraction rather than the concrete storage package so the
/// flow can be mocked in tests and the backing store swapped without churn.
abstract class SecureStorageService {
  Future<void> writeToken(String token);
  Future<String?> readToken();
  Future<void> deleteToken();

  Future<void> writeRefreshToken(String token);
  Future<String?> readRefreshToken();
  Future<void> deleteRefreshToken();

  /// Clears both the access and refresh tokens (logout / forced sign-out).
  Future<void> clear();

  Future<bool> get hasToken;
}

/// Thin wrapper over [FlutterSecureStorage]. Keeps key names in one place and
/// isolates the rest of the app from the storage package.
class SecureStorageServiceImpl implements SecureStorageService {
  SecureStorageServiceImpl(this._storage);

  final FlutterSecureStorage _storage;

  static const _aOptions = AndroidOptions(encryptedSharedPreferences: true);

  @override
  Future<void> writeToken(String token) =>
      _storage.write(key: AppConstants.kJwtToken, value: token, aOptions: _aOptions);

  @override
  Future<String?> readToken() =>
      _storage.read(key: AppConstants.kJwtToken, aOptions: _aOptions);

  @override
  Future<void> deleteToken() =>
      _storage.delete(key: AppConstants.kJwtToken, aOptions: _aOptions);

  @override
  Future<void> writeRefreshToken(String token) => _storage.write(
      key: AppConstants.kRefreshToken, value: token, aOptions: _aOptions);

  @override
  Future<String?> readRefreshToken() =>
      _storage.read(key: AppConstants.kRefreshToken, aOptions: _aOptions);

  @override
  Future<void> deleteRefreshToken() =>
      _storage.delete(key: AppConstants.kRefreshToken, aOptions: _aOptions);

  @override
  Future<void> clear() async {
    await deleteToken();
    await deleteRefreshToken();
  }

  @override
  Future<bool> get hasToken async => (await readToken())?.isNotEmpty ?? false;
}
