import 'package:json_annotation/json_annotation.dart';

import 'reservation.dart';

part 'payment_transaction.g.dart';

@JsonSerializable(createToJson: false)
class PaymentTransaction {
  final int paymentId;
  final PaymentStatus status;
  final double amount;
  final DateTime transactionAt;
  final int reservationId;
  final DateTime pickupAt;
  final DateTime returnAt;
  final String vehicleName;

  PaymentTransaction({
    required this.paymentId,
    required this.status,
    required this.amount,
    required this.transactionAt,
    required this.reservationId,
    required this.pickupAt,
    required this.returnAt,
    required this.vehicleName,
  });

  bool get isRefund => status == PaymentStatus.refunded;

  factory PaymentTransaction.fromJson(Map<String, dynamic> json) => _$PaymentTransactionFromJson(json);
}
