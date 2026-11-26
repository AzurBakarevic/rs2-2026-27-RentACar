// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vehicle.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Vehicle _$VehicleFromJson(Map<String, dynamic> json) => Vehicle(
  id: (json['id'] as num).toInt(),
  productionYear: (json['productionYear'] as num).toInt(),
  seatCount: (json['seatCount'] as num).toInt(),
  description: json['description'] as String?,
  pricePerDay: (json['pricePerDay'] as num).toDouble(),
  hasImage: json['hasImage'] as bool,
  brandName: json['brandName'] as String,
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
