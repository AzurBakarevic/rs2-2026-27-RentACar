import 'package:json_annotation/json_annotation.dart';

import 'named_entity.dart';

part 'category.g.dart';

@JsonSerializable()
class Category implements NamedEntity {
  @override
  final int id;
  @override
  final String name;

  Category({required this.id, required this.name});

  factory Category.fromJson(Map<String, dynamic> json) => _$CategoryFromJson(json);

  Map<String, dynamic> toJson() => _$CategoryToJson(this);
}
