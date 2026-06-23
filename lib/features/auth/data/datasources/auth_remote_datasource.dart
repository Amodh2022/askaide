import 'dart:math';

import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/network/endpoints.dart';
import '../../domain/entities/signup_data.dart';
import '../models/auth_response_model.dart';

abstract class AuthRemoteDataSource {
  Future<AuthResponseModel> login(String email, String password);
  Future<void> sendOtp(String email);
  Future<AuthResponseModel> signup(SignupData data);
  Future<void> requestPasswordReset(String email);
  Future<void> resetPassword(String password, String confirmPassword, String token);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl(this._dio);
  final Dio _dio;

  Map<String, dynamic> _asMap(Response res) {
    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    throw ServerException('Unexpected response', statusCode: res.statusCode);
  }

  /// The backend accepts an email *or* username in the `userName` field.
  @override
  Future<AuthResponseModel> login(String email, String password) async {
    final res = await _dio.post(
      Endpoints.login,
      data: {'userName': email, 'password': password},
    );
    return AuthResponseModel.fromJson(_asMap(res));
  }

  @override
  Future<void> sendOtp(String email) =>
      _dio.post(Endpoints.sendOtp, data: {'email': email});

  /// Mirrors the frontend: derives a `userName` from the email and sends the
  /// full signup payload (name + userName + credentials + otp).
  @override
  Future<AuthResponseModel> signup(SignupData data) async {
    final prefix = data.email.split('@').first.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final userName = '$prefix${Random().nextInt(100)}';
    final res = await _dio.post(Endpoints.signup, data: {
      'name': data.name,
      'userName': userName,
      'email': data.email,
      'password': data.password,
      'confirmPassword': data.confirmPassword,
      'otp': data.otp,
      'accountType': data.accountType,
    });
    return AuthResponseModel.fromJson(_asMap(res));
  }

  @override
  Future<void> requestPasswordReset(String email) =>
      _dio.post(Endpoints.resetPasswordToken, data: {'email': email});

  @override
  Future<void> resetPassword(
    String password,
    String confirmPassword,
    String token,
  ) =>
      _dio.post(Endpoints.resetPassword, data: {
        'token': token,
        'newPassword': password,
        'confirmPassword': confirmPassword,
      });
}
