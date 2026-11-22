import 'package:json_annotation/json_annotation.dart';

part 'vehicle.g.dart';

/// Vozilo bez slike; slika se učitava posebno kad je [hasImage] true (upute 8.2).
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

  /// Razlog zbog kojeg se vozilo ne može obrisati; `null` = može.
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

  /// Marka i model, npr. „Volkswagen Golf”.
  String get name => '$brandName $vehicleModelName';

  factory Vehicle.fromJson(Map<String, dynamic> json) => _$VehicleFromJson(json);

  Map<String, dynamic> toJson() => _$VehicleToJson(this);
}
