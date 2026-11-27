// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reservation_calculation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReservationCalculation _$ReservationCalculationFromJson(
  Map<String, dynamic> json,
) => ReservationCalculation(
  rentalDays: (json['rentalDays'] as num).toInt(),
  vehiclePricePerDay: (json['vehiclePricePerDay'] as num).toDouble(),
  vehiclePrice: (json['vehiclePrice'] as num).toDouble(),
  seasonalSurcharge: (json['seasonalSurcharge'] as num).toDouble(),
  equipmentPrice: (json['equipmentPrice'] as num).toDouble(),
  totalPrice: (json['totalPrice'] as num).toDouble(),
  equipment: (json['equipment'] as List<dynamic>)
      .map((e) => ReservationEquipment.fromJson(e as Map<String, dynamic>))
      .toList(),
);
