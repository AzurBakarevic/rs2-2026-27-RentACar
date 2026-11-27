import 'package:json_annotation/json_annotation.dart';

part 'payment_intent.g.dart';

@JsonSerializable(createToJson: false)
class PaymentIntent {
  final int reservationId;
  final String clientSecret;
  final String publishableKey;
  final double amount;

  PaymentIntent({
    required this.reservationId,
    required this.clientSecret,
    required this.publishableKey,
    required this.amount,
  });

  factory PaymentIntent.fromJson(Map<String, dynamic> json) => _$PaymentIntentFromJson(json);
}
