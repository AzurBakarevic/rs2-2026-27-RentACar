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
  hasProfileImage: json['hasProfileImage'] as bool,
);
