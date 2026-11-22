import 'package:json_annotation/json_annotation.dart';

part 'equipment.g.dart';

@JsonSerializable()
class Equipment {
  final int id;
  final String name;
  final double pricePerDay;

  /// Ukupan broj komada koje agencija ima.
  final int quantity;

  /// Neaktivna oprema se ne nudi prilikom rezervacije.
  final bool isActive;

  /// Razlog zbog kojeg se oprema ne može obrisati; `null` = može.
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
