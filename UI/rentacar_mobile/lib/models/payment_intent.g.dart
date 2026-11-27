// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_intent.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaymentIntent _$PaymentIntentFromJson(Map<String, dynamic> json) =>
    PaymentIntent(
      reservationId: (json['reservationId'] as num).toInt(),
      clientSecret: json['clientSecret'] as String,
      publishableKey: json['publishableKey'] as String,
      amount: (json['amount'] as num).toDouble(),
    );
