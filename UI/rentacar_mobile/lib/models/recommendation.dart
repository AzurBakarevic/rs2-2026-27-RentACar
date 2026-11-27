import 'package:json_annotation/json_annotation.dart';

part 'recommendation.g.dart';

@JsonSerializable(createToJson: false)
class Recommendation {
  final int vehicleId;
  final String brandName;
  final String vehicleModelName;
  final String categoryName;
  final double pricePerDay;
  final bool hasImage;
  final String explanation;

  Recommendation({
    required this.vehicleId,
    required this.brandName,
    required this.vehicleModelName,
    required this.categoryName,
    required this.pricePerDay,
    required this.hasImage,
    required this.explanation,
  });

  String get vehicleName => '$brandName $vehicleModelName';

  factory Recommendation.fromJson(Map<String, dynamic> json) => _$RecommendationFromJson(json);
}
