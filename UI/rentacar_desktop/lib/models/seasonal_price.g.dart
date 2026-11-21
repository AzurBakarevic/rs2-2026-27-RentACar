// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'seasonal_price.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SeasonalPrice _$SeasonalPriceFromJson(Map<String, dynamic> json) =>
    SeasonalPrice(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      increasePercentage: (json['increasePercentage'] as num).toDouble(),
      isActive: json['isActive'] as bool,
    );

Map<String, dynamic> _$SeasonalPriceToJson(SeasonalPrice instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'startDate': instance.startDate.toIso8601String(),
      'endDate': instance.endDate.toIso8601String(),
      'increasePercentage': instance.increasePercentage,
      'isActive': instance.isActive,
    };
