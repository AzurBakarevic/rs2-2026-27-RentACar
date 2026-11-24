import 'package:json_annotation/json_annotation.dart';

part 'review.g.dart';

@JsonSerializable()
class Review {
  final int id;
  final int rating;
  final String? comment;
  final DateTime createdAt;
  final int reservationId;

  final int userId;
  final String userFullName;
  final bool userHasImage;

  final int vehicleId;
  final String vehicleName;
  final String vehicleRegistrationNumber;
  final bool vehicleHasImage;

  Review({
    required this.id,
    required this.rating,
    this.comment,
    required this.createdAt,
    required this.reservationId,
    required this.userId,
    required this.userFullName,
    required this.userHasImage,
    required this.vehicleId,
    required this.vehicleName,
    required this.vehicleRegistrationNumber,
    required this.vehicleHasImage,
  });

  factory Review.fromJson(Map<String, dynamic> json) => _$ReviewFromJson(json);

  Map<String, dynamic> toJson() => _$ReviewToJson(this);
}
