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
  userId: (json['userId'] as num).toInt(),
  userFullName: json['userFullName'] as String,
  userHasImage: json['userHasImage'] as bool,
  vehicleId: (json['vehicleId'] as num).toInt(),
  vehicleName: json['vehicleName'] as String,
  vehicleRegistrationNumber: json['vehicleRegistrationNumber'] as String,
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

Map<String, dynamic> _$ReservationToJson(Reservation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'pickupAt': instance.pickupAt.toIso8601String(),
      'returnAt': instance.returnAt.toIso8601String(),
      'rentalDays': instance.rentalDays,
      'vehiclePrice': instance.vehiclePrice,
      'seasonalSurcharge': instance.seasonalSurcharge,
      'equipmentPrice': instance.equipmentPrice,
      'totalPrice': instance.totalPrice,
      'status': _$ReservationStatusEnumMap[instance.status]!,
      'createdAt': instance.createdAt.toIso8601String(),
      'isPaid': instance.isPaid,
      'paymentDeadline': instance.paymentDeadline.toIso8601String(),
      'cancellationReason': instance.cancellationReason,
      'userId': instance.userId,
      'userFullName': instance.userFullName,
      'userHasImage': instance.userHasImage,
      'vehicleId': instance.vehicleId,
      'vehicleName': instance.vehicleName,
      'vehicleRegistrationNumber': instance.vehicleRegistrationNumber,
      'vehicleHasImage': instance.vehicleHasImage,
      'allowedActions': instance.allowedActions,
      'actionBlockedReasons': instance.actionBlockedReasons,
      'equipment': instance.equipment,
      'payment': instance.payment,
      'statusHistory': instance.statusHistory,
    };

const _$ReservationStatusEnumMap = {
  ReservationStatus.pending: 1,
  ReservationStatus.confirmed: 2,
  ReservationStatus.completed: 3,
  ReservationStatus.cancelled: 4,
};

ReservationEquipment _$ReservationEquipmentFromJson(
  Map<String, dynamic> json,
) => ReservationEquipment(
  equipmentName: json['equipmentName'] as String,
  quantity: (json['quantity'] as num).toInt(),
  pricePerDay: (json['pricePerDay'] as num).toDouble(),
  totalPrice: (json['totalPrice'] as num).toDouble(),
);

Map<String, dynamic> _$ReservationEquipmentToJson(
  ReservationEquipment instance,
) => <String, dynamic>{
  'equipmentName': instance.equipmentName,
  'quantity': instance.quantity,
  'pricePerDay': instance.pricePerDay,
  'totalPrice': instance.totalPrice,
};

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

Map<String, dynamic> _$ReservationPaymentToJson(ReservationPayment instance) =>
    <String, dynamic>{
      'status': _$PaymentStatusEnumMap[instance.status]!,
      'amount': instance.amount,
      'paidAt': instance.paidAt?.toIso8601String(),
      'refundedAt': instance.refundedAt?.toIso8601String(),
    };

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
  changedByName: json['changedByName'] as String?,
);

Map<String, dynamic> _$ReservationStatusChangeToJson(
  ReservationStatusChange instance,
) => <String, dynamic>{
  'oldStatus': _$ReservationStatusEnumMap[instance.oldStatus],
  'newStatus': _$ReservationStatusEnumMap[instance.newStatus]!,
  'reason': instance.reason,
  'changedAt': instance.changedAt.toIso8601String(),
  'changedByName': instance.changedByName,
};
