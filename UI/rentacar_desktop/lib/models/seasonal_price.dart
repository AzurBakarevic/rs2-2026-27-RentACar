import 'package:json_annotation/json_annotation.dart';

part 'seasonal_price.g.dart';

@JsonSerializable()
class SeasonalPrice {
  final int id;
  final String name;

  final DateTime startDate;
  final DateTime endDate;
  final double increasePercentage;
  final bool isActive;

  SeasonalPrice({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.increasePercentage,
    required this.isActive,
  });

  factory SeasonalPrice.fromJson(Map<String, dynamic> json) => _$SeasonalPriceFromJson(json);

  Map<String, dynamic> toJson() => _$SeasonalPriceToJson(this);
}
