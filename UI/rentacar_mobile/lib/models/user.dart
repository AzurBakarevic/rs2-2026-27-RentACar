import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable(createToJson: false)
class User {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String username;
  final String? driverLicenseNumber;
  final DateTime? driverLicenseValidUntil;
  final bool hasProfileImage;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.username,
    this.driverLicenseNumber,
    this.driverLicenseValidUntil,
    required this.hasProfileImage,
  });

  String get fullName => '$firstName $lastName';

  bool get hasDriverLicense => driverLicenseNumber != null && driverLicenseValidUntil != null;

  User withProfileImage(bool value) => User(
        id: id,
        firstName: firstName,
        lastName: lastName,
        email: email,
        phoneNumber: phoneNumber,
        username: username,
        driverLicenseNumber: driverLicenseNumber,
        driverLicenseValidUntil: driverLicenseValidUntil,
        hasProfileImage: value,
      );

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
