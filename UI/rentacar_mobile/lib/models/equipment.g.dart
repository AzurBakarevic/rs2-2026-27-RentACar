// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'equipment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Equipment _$EquipmentFromJson(Map<String, dynamic> json) => Equipment(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  pricePerDay: (json['pricePerDay'] as num).toDouble(),
  quantity: (json['quantity'] as num).toInt(),
);
