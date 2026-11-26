import 'package:json_annotation/json_annotation.dart';

import 'named_entity.dart';

part 'transmission_type.g.dart';

@JsonSerializable(createToJson: false)
class TransmissionType implements NamedEntity {
  @override
  final int id;
  @override
  final String name;

  TransmissionType({required this.id, required this.name});

  factory TransmissionType.fromJson(Map<String, dynamic> json) => _$TransmissionTypeFromJson(json);
}
