// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_transaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaymentTransaction _$PaymentTransactionFromJson(Map<String, dynamic> json) =>
    PaymentTransaction(
      paymentId: (json['paymentId'] as num).toInt(),
      status: $enumDecode(_$PaymentStatusEnumMap, json['status']),
      amount: (json['amount'] as num).toDouble(),
      transactionAt: DateTime.parse(json['transactionAt'] as String),
      reservationId: (json['reservationId'] as num).toInt(),
      pickupAt: DateTime.parse(json['pickupAt'] as String),
      returnAt: DateTime.parse(json['returnAt'] as String),
      vehicleName: json['vehicleName'] as String,
    );

const _$PaymentStatusEnumMap = {
  PaymentStatus.pending: 1,
  PaymentStatus.paid: 2,
  PaymentStatus.refunded: 3,
  PaymentStatus.cancelled: 4,
};
