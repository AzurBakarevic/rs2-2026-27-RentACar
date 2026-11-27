import 'package:json_annotation/json_annotation.dart';

import 'reservation.dart';

part 'reservation_calculation.g.dart';

@JsonSerializable(createToJson: false)
class ReservationCalculation {
  final int rentalDays;
  final double vehiclePricePerDay;
  final double vehiclePrice;
  final double seasonalSurcharge;
  final double equipmentPrice;
  final double totalPrice;
  final List<ReservationEquipment> equipment;

  ReservationCalculation({
    required this.rentalDays,
    required this.vehiclePricePerDay,
    required this.vehiclePrice,
    required this.seasonalSurcharge,
    required this.equipmentPrice,
    required this.totalPrice,
    required this.equipment,
  });

  factory ReservationCalculation.fromJson(Map<String, dynamic> json) => _$ReservationCalculationFromJson(json);
}
