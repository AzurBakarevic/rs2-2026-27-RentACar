import 'package:json_annotation/json_annotation.dart';

import 'named_entity.dart';

part 'fuel_type.g.dart';

@JsonSerializable(createToJson: false)
class FuelType implements NamedEntity {
  @override
  final int id;
  @override
  final String name;

  FuelType({required this.id, required this.name});

  factory FuelType.fromJson(Map<String, dynamic> json) => _$FuelTypeFromJson(json);
}
