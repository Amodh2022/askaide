import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/account_type.dart';
import '../../domain/entities/user.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

/// Data Transfer Object for the user. Maps the (loosely-typed) backend JSON and
/// converts to the domain [User]. Run `dart run build_runner build` to generate
/// the `.freezed.dart` / `.g.dart` parts.
@freezed
class UserModel with _$UserModel {
  const UserModel._();

  const factory UserModel({
    @JsonKey(name: '_id') String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? image,
    String? accountType,
    // Backend has used both `schoolId` and `school`; accept either.
    @JsonKey(readValue: _readSchoolId) String? schoolId,
    String? className,
    String? userName,
    String? grade,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  User toEntity() => User(
        id: id ?? '',
        firstName: firstName ?? 'Learner',
        lastName: lastName,
        email: email,
        image: image,
        accountType: AccountType.fromApi(accountType),
        schoolId: schoolId,
        className: className,
        userName: userName,
        grade: grade,
      );
}

/// Reads the school id from either `schoolId` or the legacy `school` key.
/// When the value is a populated object, prefer its `_id`.
Object? _readSchoolId(Map json, String key) {
  final v = json['schoolId'] ?? json['school'];
  if (v is Map) return v['_id'] ?? v['id'];
  return v;
}
