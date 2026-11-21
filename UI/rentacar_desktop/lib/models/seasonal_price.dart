import 'package:json_annotation/json_annotation.dart';

part 'seasonal_price.g.dart';

/// Period (oba datuma uključena) u kojem se cijena najma uvećava za zadani procenat.
@JsonSerializable()
class SeasonalPrice {
  final int id;
  final String name;

  /// API šalje samo datum (npr. "2026-06-01"), pa je ovo ponoć lokalnog dana.
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
