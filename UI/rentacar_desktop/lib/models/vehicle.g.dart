// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vehicle.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Vehicle _$VehicleFromJson(Map<String, dynamic> json) => Vehicle(
  id: (json['id'] as num).toInt(),
  registrationNumber: json['registrationNumber'] as String,
  productionYear: (json['productionYear'] as num).toInt(),
  seatCount: (json['seatCount'] as num).toInt(),
  description: json['description'] as String?,
  pricePerDay: (json['pricePerDay'] as num).toDouble(),
  isActive: json['isActive'] as bool,
  createdAt: DateTime.parse(json['createdAt'] as String),
  hasImage: json['hasImage'] as bool,
  brandId: (json['brandId'] as num).toInt(),
  brandName: json['brandName'] as String,
  vehicleModelId: (json['vehicleModelId'] as num).toInt(),
  vehicleModelName: json['vehicleModelName'] as String,
  categoryId: (json['categoryId'] as num).toInt(),
  categoryName: json['categoryName'] as String,
  fuelTypeId: (json['fuelTypeId'] as num).toInt(),
  fuelTypeName: json['fuelTypeName'] as String,
  transmissionTypeId: (json['transmissionTypeId'] as num).toInt(),
  transmissionTypeName: json['transmissionTypeName'] as String,
  averageRating: (json['averageRating'] as num?)?.toDouble(),
  reviewCount: (json['reviewCount'] as num).toInt(),
);

Map<String, dynamic> _$VehicleToJson(Vehicle instance) => <String, dynamic>{
  'id': instance.id,
  'registrationNumber': instance.registrationNumber,
  'productionYear': instance.productionYear,
  'seatCount': instance.seatCount,
  'description': instance.description,
  'pricePerDay': instance.pricePerDay,
  'isActive': instance.isActive,
  'createdAt': instance.createdAt.toIso8601String(),
  'hasImage': instance.hasImage,
  'brandId': instance.brandId,
  'brandName': instance.brandName,
  'vehicleModelId': instance.vehicleModelId,
  'vehicleModelName': instance.vehicleModelName,
  'categoryId': instance.categoryId,
  'categoryName': instance.categoryName,
  'fuelTypeId': instance.fuelTypeId,
  'fuelTypeName': instance.fuelTypeName,
  'transmissionTypeId': instance.transmissionTypeId,
  'transmissionTypeName': instance.transmissionTypeName,
  'averageRating': instance.averageRating,
  'reviewCount': instance.reviewCount,
};
