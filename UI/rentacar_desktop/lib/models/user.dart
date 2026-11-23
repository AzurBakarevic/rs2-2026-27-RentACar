import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String username;
  final String? driverLicenseNumber;
  final DateTime? driverLicenseValidUntil;
  final bool isActive;
  final DateTime createdAt;
  final bool hasProfileImage;
  final int roleId;
  final String roleName;
  final int activeReservationCount;

  final String? deleteBlockedReason;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.username,
    this.driverLicenseNumber,
    this.driverLicenseValidUntil,
    required this.isActive,
    required this.createdAt,
    required this.hasProfileImage,
    required this.roleId,
    required this.roleName,
    required this.activeReservationCount,
    this.deleteBlockedReason,
  });

  String get fullName => '$firstName $lastName';

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  Map<String, dynamic> toJson() => _$UserToJson(this);
}
