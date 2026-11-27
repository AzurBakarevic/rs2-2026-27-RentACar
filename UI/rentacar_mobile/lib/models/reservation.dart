import 'package:json_annotation/json_annotation.dart';

part 'reservation.g.dart';

enum ReservationStatus {
  @JsonValue(1)
  pending('Na čekanju'),
  @JsonValue(2)
  confirmed('Potvrđena'),
  @JsonValue(3)
  completed('Završena'),
  @JsonValue(4)
  cancelled('Otkazana');

  const ReservationStatus(this.label);

  final String label;
}

enum PaymentStatus {
  @JsonValue(1)
  pending,
  @JsonValue(2)
  paid,
  @JsonValue(3)
  refunded,
  @JsonValue(4)
  cancelled,
}

enum ReservationAction {
  pay('Pay'),
  cancel('Cancel'),
  review('Review');

  const ReservationAction(this.apiName);

  final String apiName;
}

@JsonSerializable(createToJson: false)
class Reservation {
  final int id;
  final DateTime pickupAt;
  final DateTime returnAt;
  final int rentalDays;
  final double vehiclePrice;
  final double seasonalSurcharge;
  final double equipmentPrice;
  final double totalPrice;
  final ReservationStatus status;
  final DateTime createdAt;
  final bool isPaid;
  final DateTime paymentDeadline;
  final String? cancellationReason;
  final bool hasReview;
  final int vehicleId;
  final String vehicleName;
  final String vehicleRegistrationNumber;
  final String vehicleCategoryName;
  final bool vehicleHasImage;
  final List<String> allowedActions;
  final Map<String, String> actionBlockedReasons;
  final List<ReservationEquipment>? equipment;
  final ReservationPayment? payment;
  final List<ReservationStatusChange>? statusHistory;

  Reservation({
    required this.id,
    required this.pickupAt,
    required this.returnAt,
    required this.rentalDays,
    required this.vehiclePrice,
    required this.seasonalSurcharge,
    required this.equipmentPrice,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
    required this.isPaid,
    required this.paymentDeadline,
    this.cancellationReason,
    required this.hasReview,
    required this.vehicleId,
    required this.vehicleName,
    required this.vehicleRegistrationNumber,
    required this.vehicleCategoryName,
    required this.vehicleHasImage,
    required this.allowedActions,
    required this.actionBlockedReasons,
    this.equipment,
    this.payment,
    this.statusHistory,
  });

  bool can(ReservationAction action) => allowedActions.contains(action.apiName);

  String? blockedReason(ReservationAction action) => actionBlockedReasons[action.apiName];

  bool get isRefunded => payment?.status == PaymentStatus.refunded;

  ReservationStatusChange? get cancellation =>
      statusHistory?.where((x) => x.newStatus == ReservationStatus.cancelled).lastOrNull;

  factory Reservation.fromJson(Map<String, dynamic> json) => _$ReservationFromJson(json);
}

@JsonSerializable(createToJson: false)
class ReservationEquipment {
  final int equipmentId;
  final String equipmentName;
  final int quantity;
  final double pricePerDay;
  final double totalPrice;

  ReservationEquipment({
    required this.equipmentId,
    required this.equipmentName,
    required this.quantity,
    required this.pricePerDay,
    required this.totalPrice,
  });

  factory ReservationEquipment.fromJson(Map<String, dynamic> json) => _$ReservationEquipmentFromJson(json);
}

@JsonSerializable(createToJson: false)
class ReservationPayment {
  final PaymentStatus status;
  final double amount;
  final DateTime? paidAt;
  final DateTime? refundedAt;

  ReservationPayment({required this.status, required this.amount, this.paidAt, this.refundedAt});

  factory ReservationPayment.fromJson(Map<String, dynamic> json) => _$ReservationPaymentFromJson(json);
}

@JsonSerializable(createToJson: false)
class ReservationStatusChange {
  final ReservationStatus? oldStatus;
  final ReservationStatus newStatus;
  final String? reason;
  final DateTime changedAt;
  final int? changedByUserId;

  ReservationStatusChange({
    this.oldStatus,
    required this.newStatus,
    this.reason,
    required this.changedAt,
    this.changedByUserId,
  });

  factory ReservationStatusChange.fromJson(Map<String, dynamic> json) => _$ReservationStatusChangeFromJson(json);
}
