import 'package:json_annotation/json_annotation.dart';

part 'equipment.g.dart';

@JsonSerializable()
class Equipment {
  final int id;
  final String name;
  final double pricePerDay;

  final int quantity;

  final bool isActive;

  final String? deleteBlockedReason;

  Equipment({
    required this.id,
    required this.name,
    required this.pricePerDay,
    required this.quantity,
    required this.isActive,
    this.deleteBlockedReason,
  });

  factory Equipment.fromJson(Map<String, dynamic> json) => _$EquipmentFromJson(json);

  Map<String, dynamic> toJson() => _$EquipmentToJson(this);
}
