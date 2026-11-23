import 'package:json_annotation/json_annotation.dart';

part 'vehicle.g.dart';

@JsonSerializable()
class Vehicle {
  final int id;
  final String registrationNumber;
  final int productionYear;
  final int seatCount;
  final String? description;
  final double pricePerDay;
  final bool isActive;
  final DateTime createdAt;
  final bool hasImage;
  final int brandId;
  final String brandName;
  final int vehicleModelId;
  final String vehicleModelName;
  final int categoryId;
  final String categoryName;
  final int fuelTypeId;
  final String fuelTypeName;
  final int transmissionTypeId;
  final String transmissionTypeName;
  final double? averageRating;
  final int reviewCount;

  final String? deleteBlockedReason;

  Vehicle({
    required this.id,
    required this.registrationNumber,
    required this.productionYear,
    required this.seatCount,
    this.description,
    required this.pricePerDay,
    required this.isActive,
    required this.createdAt,
    required this.hasImage,
    required this.brandId,
    required this.brandName,
    required this.vehicleModelId,
    required this.vehicleModelName,
    required this.categoryId,
    required this.categoryName,
    required this.fuelTypeId,
    required this.fuelTypeName,
    required this.transmissionTypeId,
    required this.transmissionTypeName,
    this.averageRating,
    required this.reviewCount,
    this.deleteBlockedReason,
  });

  String get name => '$brandName $vehicleModelName';

  factory Vehicle.fromJson(Map<String, dynamic> json) => _$VehicleFromJson(json);

  Map<String, dynamic> toJson() => _$VehicleToJson(this);
}
