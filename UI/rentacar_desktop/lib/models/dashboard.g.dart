// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Dashboard _$DashboardFromJson(Map<String, dynamic> json) => Dashboard(
  vehicleCount: (json['vehicleCount'] as num).toInt(),
  customerCount: (json['customerCount'] as num).toInt(),
  activeReservationCount: (json['activeReservationCount'] as num).toInt(),
  awaitingConfirmationCount: (json['awaitingConfirmationCount'] as num).toInt(),
  reservationsPerDay: (json['reservationsPerDay'] as List<dynamic>)
      .map((e) => DailyReservationCount.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$DashboardToJson(Dashboard instance) => <String, dynamic>{
  'vehicleCount': instance.vehicleCount,
  'customerCount': instance.customerCount,
  'activeReservationCount': instance.activeReservationCount,
  'awaitingConfirmationCount': instance.awaitingConfirmationCount,
  'reservationsPerDay': instance.reservationsPerDay,
};

DailyReservationCount _$DailyReservationCountFromJson(
  Map<String, dynamic> json,
) => DailyReservationCount(
  date: DateTime.parse(json['date'] as String),
  count: (json['count'] as num).toInt(),
);

Map<String, dynamic> _$DailyReservationCountToJson(
  DailyReservationCount instance,
) => <String, dynamic>{
  'date': instance.date.toIso8601String(),
  'count': instance.count,
};
