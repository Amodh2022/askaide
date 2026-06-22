import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/auth_session.dart';

part 'auth_response_model.freezed.dart';
part 'auth_response_model.g.dart';

/// Parses the login/signup response. The backend returns the JWT under `token`
/// and may nest the role under `user.accountType`.
@freezed
class AuthResponseModel with _$AuthResponseModel {
  const AuthResponseModel._();

  const factory AuthResponseModel({
    String? token,
    @JsonKey(name: 'accountType') String? accountType,
    Map<String, dynamic>? user,
  }) = _AuthResponseModel;

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseModelFromJson(json);

  AuthSession toEntity() => AuthSession(
        token: token ?? '',
        accountType: accountType ?? (user?['accountType'])?.toString(),
      );
}
