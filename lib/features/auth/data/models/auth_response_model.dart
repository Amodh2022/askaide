import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/auth_session.dart';

part 'auth_response_model.freezed.dart';

/// Parses the login/signup response. The backend nests the JWTs under a
/// `tokens` object (`{ accessToken, refreshToken, expiresIn }`) and the role
/// under `user.accountType`. Older/top-level shapes are accepted as a fallback.
@freezed
class AuthResponseModel with _$AuthResponseModel {
  const AuthResponseModel._();

  const factory AuthResponseModel({
    String? token,
    String? refreshToken,
    String? accountType,
    Map<String, dynamic>? user,
  }) = _AuthResponseModel;

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    final tokens = json['tokens'];
    String? access;
    String? refresh;
    if (tokens is Map) {
      access = tokens['accessToken']?.toString();
      refresh = tokens['refreshToken']?.toString();
    }
    // Fallbacks for older/flat response shapes.
    access ??= (json['token'] ?? json['accessToken'])?.toString();
    refresh ??= json['refreshToken']?.toString();

    final user =
        json['user'] is Map<String, dynamic> ? json['user'] as Map<String, dynamic> : null;

    return AuthResponseModel(
      token: access,
      refreshToken: refresh,
      accountType: (json['accountType'] ?? user?['accountType'])?.toString(),
      user: user,
    );
  }

  AuthSession toEntity() => AuthSession(
        token: token ?? '',
        refreshToken: refreshToken,
        accountType: accountType ?? (user?['accountType'])?.toString(),
      );
}
