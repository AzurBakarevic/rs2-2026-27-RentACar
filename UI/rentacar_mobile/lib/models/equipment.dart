import 'package:json_annotation/json_annotation.dart';

part 'equipment.g.dart';

@JsonSerializable(createToJson: false)
class Equipment {
  final int id;
  final String name;
  final double pricePerDay;
  final int quantity;

  Equipment({required this.id, required this.name, required this.pricePerDay, required this.quantity});

  factory Equipment.fromJson(Map<String, dynamic> json) => _$EquipmentFromJson(json);
}
