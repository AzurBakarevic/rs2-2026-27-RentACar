import 'package:json_annotation/json_annotation.dart';

import 'named_entity.dart';

part 'vehicle_model.g.dart';

@JsonSerializable()
class VehicleModel implements NamedEntity {
  @override
  final int id;
  @override
  final String name;
  final int brandId;
  final String brandName;

  VehicleModel({required this.id, required this.name, required this.brandId, required this.brandName});

  factory VehicleModel.fromJson(Map<String, dynamic> json) => _$VehicleModelFromJson(json);

  Map<String, dynamic> toJson() => _$VehicleModelToJson(this);
}
