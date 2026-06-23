// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserModelImpl _$$UserModelImplFromJson(Map<String, dynamic> json) =>
    _$UserModelImpl(
      id: json['_id'] as String?,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      email: json['email'] as String?,
      image: json['image'] as String?,
      accountType: json['accountType'] as String?,
      schoolId: _readSchoolId(json, 'schoolId') as String?,
      className: json['className'] as String?,
      userName: json['userName'] as String?,
      grade: json['grade'] as String?,
    );

Map<String, dynamic> _$$UserModelImplToJson(_$UserModelImpl instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'email': instance.email,
      'image': instance.image,
      'accountType': instance.accountType,
      'schoolId': instance.schoolId,
      'className': instance.className,
      'userName': instance.userName,
      'grade': instance.grade,
    };
