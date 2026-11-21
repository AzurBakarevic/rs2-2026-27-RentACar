// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vehicle_maintenance.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VehicleMaintenance _$VehicleMaintenanceFromJson(Map<String, dynamic> json) =>
    VehicleMaintenance(
      id: (json['id'] as num).toInt(),
      startAt: DateTime.parse(json['startAt'] as String),
      endAt: DateTime.parse(json['endAt'] as String),
      description: json['description'] as String,
      cost: (json['cost'] as num).toDouble(),
      vehicleId: (json['vehicleId'] as num).toInt(),
      vehicleName: json['vehicleName'] as String,
      vehicleRegistrationNumber: json['vehicleRegistrationNumber'] as String,
    );

Map<String, dynamic> _$VehicleMaintenanceToJson(VehicleMaintenance instance) =>
    <String, dynamic>{
      'id': instance.id,
      'startAt': instance.startAt.toIso8601String(),
      'endAt': instance.endAt.toIso8601String(),
      'description': instance.description,
      'cost': instance.cost,
      'vehicleId': instance.vehicleId,
      'vehicleName': instance.vehicleName,
      'vehicleRegistrationNumber': instance.vehicleRegistrationNumber,
    };
