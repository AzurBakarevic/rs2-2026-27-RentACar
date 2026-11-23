import 'package:json_annotation/json_annotation.dart';

part 'vehicle_maintenance.g.dart';

@JsonSerializable()
class VehicleMaintenance {
  final int id;
  final DateTime startAt;
  final DateTime endAt;
  final String description;
  final double cost;
  final int vehicleId;

  final String vehicleName;
  final String vehicleRegistrationNumber;
  final bool vehicleHasImage;

  VehicleMaintenance({
    required this.id,
    required this.startAt,
    required this.endAt,
    required this.description,
    required this.cost,
    required this.vehicleId,
    required this.vehicleName,
    required this.vehicleRegistrationNumber,
    required this.vehicleHasImage,
  });

  factory VehicleMaintenance.fromJson(Map<String, dynamic> json) => _$VehicleMaintenanceFromJson(json);

  Map<String, dynamic> toJson() => _$VehicleMaintenanceToJson(this);
}
