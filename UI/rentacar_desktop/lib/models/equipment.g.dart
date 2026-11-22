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
  isActive: json['isActive'] as bool,
  deleteBlockedReason: json['deleteBlockedReason'] as String?,
);

Map<String, dynamic> _$EquipmentToJson(Equipment instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'pricePerDay': instance.pricePerDay,
  'quantity': instance.quantity,
  'isActive': instance.isActive,
  'deleteBlockedReason': instance.deleteBlockedReason,
};
