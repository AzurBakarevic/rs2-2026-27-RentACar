// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reservation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Reservation _$ReservationFromJson(Map<String, dynamic> json) => Reservation(
  id: (json['id'] as num).toInt(),
  pickupAt: DateTime.parse(json['pickupAt'] as String),
  returnAt: DateTime.parse(json['returnAt'] as String),
  rentalDays: (json['rentalDays'] as num).toInt(),
  vehiclePrice: (json['vehiclePrice'] as num).toDouble(),
  seasonalSurcharge: (json['seasonalSurcharge'] as num).toDouble(),
  equipmentPrice: (json['equipmentPrice'] as num).toDouble(),
  totalPrice: (json['totalPrice'] as num).toDouble(),
  status: $enumDecode(_$ReservationStatusEnumMap, json['status']),
  createdAt: DateTime.parse(json['createdAt'] as String),
  isPaid: json['isPaid'] as bool,
  paymentDeadline: DateTime.parse(json['paymentDeadline'] as String),
  cancellationReason: json['cancellationReason'] as String?,
  hasReview: json['hasReview'] as bool,
  vehicleId: (json['vehicleId'] as num).toInt(),
  vehicleName: json['vehicleName'] as String,
  vehicleRegistrationNumber: json['vehicleRegistrationNumber'] as String,
  vehicleCategoryName: json['vehicleCategoryName'] as String,
  vehicleHasImage: json['vehicleHasImage'] as bool,
  allowedActions: (json['allowedActions'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  actionBlockedReasons: Map<String, String>.from(
    json['actionBlockedReasons'] as Map,
  ),
  equipment: (json['equipment'] as List<dynamic>?)
      ?.map((e) => ReservationEquipment.fromJson(e as Map<String, dynamic>))
      .toList(),
  payment: json['payment'] == null
      ? null
      : ReservationPayment.fromJson(json['payment'] as Map<String, dynamic>),
  statusHistory: (json['statusHistory'] as List<dynamic>?)
      ?.map((e) => ReservationStatusChange.fromJson(e as Map<String, dynamic>))
      .toList(),
);

const _$ReservationStatusEnumMap = {
  ReservationStatus.pending: 1,
  ReservationStatus.confirmed: 2,
  ReservationStatus.completed: 3,
  ReservationStatus.cancelled: 4,
};

ReservationEquipment _$ReservationEquipmentFromJson(
  Map<String, dynamic> json,
) => ReservationEquipment(
  equipmentId: (json['equipmentId'] as num).toInt(),
  equipmentName: json['equipmentName'] as String,
  quantity: (json['quantity'] as num).toInt(),
  pricePerDay: (json['pricePerDay'] as num).toDouble(),
  totalPrice: (json['totalPrice'] as num).toDouble(),
);

ReservationPayment _$ReservationPaymentFromJson(Map<String, dynamic> json) =>
    ReservationPayment(
      status: $enumDecode(_$PaymentStatusEnumMap, json['status']),
      amount: (json['amount'] as num).toDouble(),
      paidAt: json['paidAt'] == null
          ? null
          : DateTime.parse(json['paidAt'] as String),
      refundedAt: json['refundedAt'] == null
          ? null
          : DateTime.parse(json['refundedAt'] as String),
    );

const _$PaymentStatusEnumMap = {
  PaymentStatus.pending: 1,
  PaymentStatus.paid: 2,
  PaymentStatus.refunded: 3,
  PaymentStatus.cancelled: 4,
};

ReservationStatusChange _$ReservationStatusChangeFromJson(
  Map<String, dynamic> json,
) => ReservationStatusChange(
  oldStatus: $enumDecodeNullable(_$ReservationStatusEnumMap, json['oldStatus']),
  newStatus: $enumDecode(_$ReservationStatusEnumMap, json['newStatus']),
  reason: json['reason'] as String?,
  changedAt: DateTime.parse(json['changedAt'] as String),
  changedByUserId: (json['changedByUserId'] as num?)?.toInt(),
);
