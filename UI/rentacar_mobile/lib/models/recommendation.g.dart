// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recommendation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Recommendation _$RecommendationFromJson(Map<String, dynamic> json) =>
    Recommendation(
      vehicleId: (json['vehicleId'] as num).toInt(),
      brandName: json['brandName'] as String,
      vehicleModelName: json['vehicleModelName'] as String,
      categoryName: json['categoryName'] as String,
      pricePerDay: (json['pricePerDay'] as num).toDouble(),
      hasImage: json['hasImage'] as bool,
      explanation: json['explanation'] as String,
    );
