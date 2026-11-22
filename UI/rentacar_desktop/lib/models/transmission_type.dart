import 'package:json_annotation/json_annotation.dart';

import 'named_entity.dart';

part 'transmission_type.g.dart';

@JsonSerializable()
class TransmissionType implements NamedEntity {
  @override
  final int id;
  @override
  final String name;
  @override
  final String? deleteBlockedReason;

  TransmissionType({required this.id, required this.name, this.deleteBlockedReason});

  factory TransmissionType.fromJson(Map<String, dynamic> json) => _$TransmissionTypeFromJson(json);

  Map<String, dynamic> toJson() => _$TransmissionTypeToJson(this);
}
