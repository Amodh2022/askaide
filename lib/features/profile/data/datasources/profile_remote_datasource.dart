import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/network/endpoints.dart';
import '../models/user_model.dart';

abstract class ProfileRemoteDataSource {
  Future<UserModel> getUserDetails();
  Future<UserModel> updateProfile(Map<String, dynamic> changes);
  Future<String> updateDisplayPicture(String filePath);
  Future<void> deleteProfilePhoto();
  Future<void> deleteProfile();
  Future<void> changePassword(String oldPassword, String newPassword);
}

/// Talks to the REST API via Dio. Unwraps the common `{ data: {...} }` /
/// `{ user: {...} }` envelopes the backend uses. Network failures surface as
/// the typed exceptions thrown by the [ErrorInterceptor].
class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  ProfileRemoteDataSourceImpl(this._dio);
  final Dio _dio;

  Map<String, dynamic> _unwrapUser(Response res) {
    final data = res.data;
    if (data is Map<String, dynamic>) {
      final inner = data['data'] ?? data['user'] ?? data['userDetails'] ?? data;
      if (inner is Map<String, dynamic>) return inner;
    }
    throw ServerException('Unexpected response shape', statusCode: res.statusCode);
  }

  @override
  Future<UserModel> getUserDetails() async {
    final res = await _dio.get(Endpoints.getUserDetails);
    return UserModel.fromJson(_unwrapUser(res));
  }

  @override
  Future<UserModel> updateProfile(Map<String, dynamic> changes) async {
    final res = await _dio.put(Endpoints.updateProfile, data: changes);
    return UserModel.fromJson(_unwrapUser(res));
  }

  @override
  Future<String> updateDisplayPicture(String filePath) async {
    final form = FormData.fromMap({
      'displayPicture': await MultipartFile.fromFile(filePath),
    });
    final res = await _dio.put(Endpoints.updateDisplayPicture, data: form);
    final data = res.data;
    if (data is Map && data['image'] != null) return data['image'].toString();
    return _unwrapUser(res)['image']?.toString() ?? '';
  }

  @override
  Future<void> deleteProfilePhoto() =>
      _dio.delete(Endpoints.deleteProfilePhoto);

  @override
  Future<void> deleteProfile() => _dio.delete(Endpoints.deleteProfile);

  @override
  Future<void> changePassword(String oldPassword, String newPassword) =>
      _dio.post(Endpoints.changePassword, data: {
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      });
}
