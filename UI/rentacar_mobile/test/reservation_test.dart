import 'package:flutter_test/flutter_test.dart';
import 'package:rentacar_mobile/models/reservation.dart';
import 'package:rentacar_mobile/providers/reservation_provider.dart';
import 'package:rentacar_mobile/utils/formatters.dart';

Map<String, dynamic> reservationJson({
  int status = 4,
  bool isPaid = true,
  List<String> allowedActions = const [],
  Map<String, String> blocked = const {},
  List<Map<String, dynamic>>? history,
  Map<String, dynamic>? payment,
}) {
  return {
    'id': 7,
    'pickupAt': '2026-10-12T07:00:00Z',
    'returnAt': '2026-10-15T07:00:00Z',
    'rentalDays': 3,
    'vehiclePrice': 210.0,
    'seasonalSurcharge': 0.0,
    'equipmentPrice': 15.0,
    'totalPrice': 225.0,
    'status': status,
    'createdAt': '2026-10-08T08:30:00Z',
    'isPaid': isPaid,
    'paymentDeadline': '2026-10-08T08:45:00Z',
    'cancellationReason': null,
    'hasReview': false,
    'userId': 3,
    'userFullName': 'Test Korisnik',
    'userHasImage': false,
    'vehicleId': 1,
    'vehicleName': 'Volkswagen Golf',
    'vehicleRegistrationNumber': 'A12-K-345',
    'vehicleCategoryName': 'Kompakt',
    'vehicleHasImage': true,
    'allowedActions': allowedActions,
    'actionBlockedReasons': blocked,
    'equipment': [
      {'equipmentId': 2, 'equipmentName': 'Dječija sjedalica', 'quantity': 1, 'pricePerDay': 5.0, 'totalPrice': 15.0},
    ],
    'payment': payment,
    'statusHistory': history,
  };
}

void main() {
  group('model rezervacije', () {
    test('čita odgovor servera s opremom, uplatom i historijom', () {
      final reservation = Reservation.fromJson(reservationJson(
        history: [
          {'oldStatus': null, 'newStatus': 1, 'reason': null, 'changedAt': '2026-10-08T08:30:00Z', 'changedByUserId': 3},
          {
            'oldStatus': 1,
            'newStatus': 4,
            'reason': 'Vozilo je na servisu.',
            'changedAt': '2026-10-08T10:15:00Z',
            'changedByUserId': 1,
          },
        ],
        payment: {'id': 5, 'status': 3, 'amount': 225.0, 'createdAt': '2026-10-08T08:31:00Z', 'paidAt': null},
      ));

      expect(reservation.status, ReservationStatus.cancelled);
      expect(reservation.status.label, 'Otkazana');
      expect(reservation.vehicleCategoryName, 'Kompakt');
      expect(reservation.equipment!.single.equipmentName, 'Dječija sjedalica');
      expect(reservation.isRefunded, isTrue);
      expect(reservation.cancellation!.reason, 'Vozilo je na servisu.');
      expect(reservation.cancellation!.oldStatus, ReservationStatus.pending);
      expect(reservation.pickupAt.isUtc, isTrue);
    });

    test('akcije i razlozi kad akcija nije dozvoljena', () {
      final pending = Reservation.fromJson(
        reservationJson(status: 1, isPaid: false, allowedActions: ['Pay', 'Cancel']),
      );
      expect(pending.can(ReservationAction.pay), isTrue);
      expect(pending.can(ReservationAction.cancel), isTrue);
      expect(pending.can(ReservationAction.review), isFalse);
      expect(pending.cancellation, isNull);

      const reason = 'Rezervaciju je moguće otkazati najkasnije 24 sata prije preuzimanja vozila.';
      final confirmed = Reservation.fromJson(reservationJson(status: 2, blocked: {'Cancel': reason}));
      expect(confirmed.can(ReservationAction.cancel), isFalse);
      expect(confirmed.blockedReason(ReservationAction.cancel), reason);
    });

    test('lista bez opreme i historije (odgovor liste)', () {
      final json = reservationJson(status: 3)
        ..remove('equipment')
        ..remove('statusHistory')
        ..remove('payment');
      final reservation = Reservation.fromJson(json);
      expect(reservation.equipment, isNull);
      expect(reservation.statusHistory, isNull);
      expect(reservation.cancellation, isNull);
      expect(reservation.isRefunded, isFalse);
    });
  });

  group('zahtjev za rezervaciju', () {
    test('šalje vrijeme u UTC i samo opremu s količinom većom od nule', () {
      final pickupAt = DateTime.utc(2026, 12, 2, 8);
      final request = ReservationProvider.createRequest(
        vehicleId: 4,
        pickupAt: pickupAt,
        returnAt: pickupAt.add(const Duration(days: 3)),
        equipment: {1: 2, 2: 0, 3: 1},
      );
      expect(request['vehicleId'], 4);
      expect(request['pickupAt'], '2026-12-02T08:00:00.000Z');
      expect(request['returnAt'], '2026-12-05T08:00:00.000Z');
      expect(request['equipment'], [
        {'equipmentId': 1, 'quantity': 2},
        {'equipmentId': 3, 'quantity': 1},
      ]);
    });
  });

  group('formatiranje', () {
    test('broj dana na bosanskom', () {
      expect(formatDays(1), '1 dan');
      expect(formatDays(2), '2 dana');
      expect(formatDays(3), '3 dana');
      expect(formatDays(5), '5 dana');
      expect(formatDays(11), '11 dana');
      expect(formatDays(21), '21 dan');
      expect(formatDays(30), '30 dana');
    });

    test('period, dan u sedmici i mjesec', () {
      final pickupAt = DateTime(2026, 10, 12, 9);
      expect(formatDateRange(pickupAt, DateTime(2026, 10, 15, 9)), '12.10. – 15.10.2026');
      expect(formatDateRange(DateTime(2026, 12, 30, 9), DateTime(2027, 1, 2, 9)), '30.12.2026 – 02.01.2027');
      expect(formatDateRange(DateTime(2026, 11, 27, 18), DateTime(2026, 11, 27, 20)), '27.11.2026');
      expect(formatWeekdayShort(pickupAt), 'Pon');
      expect(formatWeekdayShort(DateTime(2026, 10, 24)), 'Sub');
      expect(formatWeekdayShort(DateTime(2026, 10, 1)), 'Čet');
      expect(formatMonthName(pickupAt), 'Oktobar');
      expect(formatMonthName(DateTime(2026, 9, 5)), 'Septembar');
    });

    test('odbrojavanje roka za plaćanje', () {
      expect(formatCountdown(const Duration(minutes: 14, seconds: 5)), '14:05');
      expect(formatCountdown(const Duration(seconds: 59)), '00:59');
      expect(formatCountdown(const Duration(seconds: -3)), '00:00');
    });
  });
}
