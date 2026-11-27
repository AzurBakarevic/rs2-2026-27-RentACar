import 'package:flutter_test/flutter_test.dart';
import 'package:rentacar_mobile/models/app_notification.dart';
import 'package:rentacar_mobile/models/payment_transaction.dart';
import 'package:rentacar_mobile/models/recommendation.dart';
import 'package:rentacar_mobile/models/reservation.dart';

Map<String, dynamic> transactionJson(int status) => {
      'paymentId': 12,
      'status': status,
      'amount': 225.0,
      'transactionAt': '2026-10-08T08:32:00Z',
      'reservationId': 7,
      'pickupAt': '2026-10-12T07:00:00Z',
      'returnAt': '2026-10-15T07:00:00Z',
      'vehicleName': 'Volkswagen Golf',
      'userId': 3,
      'userFullName': 'Haris Hadžić',
    };

void main() {
  test('notifikacija se čita iz API odgovora i označava kao pročitana', () {
    final notification = AppNotification.fromJson({
      'id': 5,
      'title': 'Rezervacija potvrđena',
      'message': 'Rezervacija vozila Volkswagen Golf je potvrđena.',
      'isRead': false,
      'createdAt': '2026-10-08T10:15:00Z',
    });

    expect(notification.isRead, isFalse);
    expect(notification.createdAt, DateTime.utc(2026, 10, 8, 10, 15));

    final read = notification.asRead();
    expect(read.isRead, isTrue);
    expect(read.id, 5);
    expect(read.title, notification.title);
    expect(read.message, notification.message);
    expect(read.createdAt, notification.createdAt);
  });

  test('transakcija razlikuje uplatu i povrat', () {
    final paid = PaymentTransaction.fromJson(transactionJson(2));
    final refund = PaymentTransaction.fromJson(transactionJson(3));

    expect(paid.status, PaymentStatus.paid);
    expect(paid.isRefund, isFalse);
    expect(refund.status, PaymentStatus.refunded);
    expect(refund.isRefund, isTrue);
    expect(refund.amount, 225.0);
    expect(refund.vehicleName, 'Volkswagen Golf');
    expect(refund.pickupAt, DateTime.utc(2026, 10, 12, 7));
  });

  test('preporuka spaja marku i model u naziv vozila', () {
    final recommendation = Recommendation.fromJson({
      'vehicleId': 4,
      'brandName': 'Hyundai',
      'vehicleModelName': 'Tucson',
      'categoryName': 'SUV',
      'pricePerDay': 110,
      'hasImage': true,
      'type': 1,
      'explanation': 'Preporučeno na osnovu vašeg najma vozila Volkswagen Golf.',
    });

    expect(recommendation.vehicleName, 'Hyundai Tucson');
    expect(recommendation.pricePerDay, 110.0);
    expect(recommendation.explanation, contains('Volkswagen Golf'));
  });
}
