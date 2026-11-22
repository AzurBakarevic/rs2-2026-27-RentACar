import 'package:json_annotation/json_annotation.dart';

import 'named_entity.dart';

part 'brand.g.dart';

@JsonSerializable()
class Brand implements NamedEntity {
  @override
  final int id;
  @override
  final String name;
  @override
  final String? deleteBlockedReason;

  Brand({required this.id, required this.name, this.deleteBlockedReason});

  factory Brand.fromJson(Map<String, dynamic> json) => _$BrandFromJson(json);

  Map<String, dynamic> toJson() => _$BrandToJson(this);
}
