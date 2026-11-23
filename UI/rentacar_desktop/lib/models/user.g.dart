// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
  id: (json['id'] as num).toInt(),
  firstName: json['firstName'] as String,
  lastName: json['lastName'] as String,
  email: json['email'] as String,
  phoneNumber: json['phoneNumber'] as String,
  username: json['username'] as String,
  driverLicenseNumber: json['driverLicenseNumber'] as String?,
  driverLicenseValidUntil: json['driverLicenseValidUntil'] == null
      ? null
      : DateTime.parse(json['driverLicenseValidUntil'] as String),
  isActive: json['isActive'] as bool,
  createdAt: DateTime.parse(json['createdAt'] as String),
  hasProfileImage: json['hasProfileImage'] as bool,
  roleId: (json['roleId'] as num).toInt(),
  roleName: json['roleName'] as String,
  activeReservationCount: (json['activeReservationCount'] as num).toInt(),
  deleteBlockedReason: json['deleteBlockedReason'] as String?,
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'id': instance.id,
  'firstName': instance.firstName,
  'lastName': instance.lastName,
  'email': instance.email,
  'phoneNumber': instance.phoneNumber,
  'username': instance.username,
  'driverLicenseNumber': instance.driverLicenseNumber,
  'driverLicenseValidUntil': instance.driverLicenseValidUntil
      ?.toIso8601String(),
  'isActive': instance.isActive,
  'createdAt': instance.createdAt.toIso8601String(),
  'hasProfileImage': instance.hasProfileImage,
  'roleId': instance.roleId,
  'roleName': instance.roleName,
  'activeReservationCount': instance.activeReservationCount,
  'deleteBlockedReason': instance.deleteBlockedReason,
};
