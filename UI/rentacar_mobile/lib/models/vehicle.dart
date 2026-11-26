import 'package:json_annotation/json_annotation.dart';

part 'vehicle.g.dart';

@JsonSerializable(createToJson: false)
class Vehicle {
  final int id;
  final int productionYear;
  final int seatCount;
  final String? description;
  final double pricePerDay;
  final bool hasImage;
  final String brandName;
  final String vehicleModelName;
  final int categoryId;
  final String categoryName;
  final int fuelTypeId;
  final String fuelTypeName;
  final int transmissionTypeId;
  final String transmissionTypeName;
  final double? averageRating;
  final int reviewCount;

  Vehicle({
    required this.id,
    required this.productionYear,
    required this.seatCount,
    this.description,
    required this.pricePerDay,
    required this.hasImage,
    required this.brandName,
    required this.vehicleModelName,
    required this.categoryId,
    required this.categoryName,
    required this.fuelTypeId,
    required this.fuelTypeName,
    required this.transmissionTypeId,
    required this.transmissionTypeName,
    this.averageRating,
    required this.reviewCount,
  });

  String get name => '$brandName $vehicleModelName';

  factory Vehicle.fromJson(Map<String, dynamic> json) => _$VehicleFromJson(json);
}
