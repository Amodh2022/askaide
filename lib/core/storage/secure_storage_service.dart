import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/app_constants.dart';

/// Thin wrapper over [FlutterSecureStorage] dedicated to sensitive values —
/// primarily the JWT. Keeps key names in one place and isolates the rest of
/// the app from the storage package.
class SecureStorageService {
  SecureStorageService(this._storage);

  final FlutterSecureStorage _storage;

  static const _aOptions = AndroidOptions(encryptedSharedPreferences: true);

  Future<void> writeToken(String token) =>
      _storage.write(key: AppConstants.kJwtToken, value: token, aOptions: _aOptions);

  Future<String?> readToken() =>
      _storage.read(key: AppConstants.kJwtToken, aOptions: _aOptions);

  Future<void> deleteToken() =>
      _storage.delete(key: AppConstants.kJwtToken, aOptions: _aOptions);

  Future<bool> get hasToken async => (await readToken())?.isNotEmpty ?? false;
}
