import 'package:json_annotation/json_annotation.dart';

part 'dashboard.g.dart';

@JsonSerializable()
class Dashboard {
  final int vehicleCount;
  final int customerCount;
  final int activeReservationCount;
  final int awaitingConfirmationCount;

  final List<DailyReservationCount> reservationsPerDay;

  Dashboard({
    required this.vehicleCount,
    required this.customerCount,
    required this.activeReservationCount,
    required this.awaitingConfirmationCount,
    required this.reservationsPerDay,
  });

  factory Dashboard.fromJson(Map<String, dynamic> json) => _$DashboardFromJson(json);

  Map<String, dynamic> toJson() => _$DashboardToJson(this);
}

@JsonSerializable()
class DailyReservationCount {
  final DateTime date;
  final int count;

  DailyReservationCount({required this.date, required this.count});

  factory DailyReservationCount.fromJson(Map<String, dynamic> json) => _$DailyReservationCountFromJson(json);

  Map<String, dynamic> toJson() => _$DailyReservationCountToJson(this);
}
