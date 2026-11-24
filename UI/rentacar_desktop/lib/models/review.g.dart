// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Review _$ReviewFromJson(Map<String, dynamic> json) => Review(
  id: (json['id'] as num).toInt(),
  rating: (json['rating'] as num).toInt(),
  comment: json['comment'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
  reservationId: (json['reservationId'] as num).toInt(),
  userId: (json['userId'] as num).toInt(),
  userFullName: json['userFullName'] as String,
  userHasImage: json['userHasImage'] as bool,
  vehicleId: (json['vehicleId'] as num).toInt(),
  vehicleName: json['vehicleName'] as String,
  vehicleRegistrationNumber: json['vehicleRegistrationNumber'] as String,
  vehicleHasImage: json['vehicleHasImage'] as bool,
);

Map<String, dynamic> _$ReviewToJson(Review instance) => <String, dynamic>{
  'id': instance.id,
  'rating': instance.rating,
  'comment': instance.comment,
  'createdAt': instance.createdAt.toIso8601String(),
  'reservationId': instance.reservationId,
  'userId': instance.userId,
  'userFullName': instance.userFullName,
  'userHasImage': instance.userHasImage,
  'vehicleId': instance.vehicleId,
  'vehicleName': instance.vehicleName,
  'vehicleRegistrationNumber': instance.vehicleRegistrationNumber,
  'vehicleHasImage': instance.vehicleHasImage,
};
