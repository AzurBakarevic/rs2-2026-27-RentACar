import 'package:flutter_test/flutter_test.dart';
import 'package:rentacar_mobile/models/review.dart';
import 'package:rentacar_mobile/models/vehicle.dart';
import 'package:rentacar_mobile/utils/formatters.dart';
import 'package:rentacar_mobile/utils/rental_period.dart';

void main() {
  group('period najma (isto pravilo kao na serveru)', () {
    final now = DateTime(2026, 12, 1, 14, 30);

    test('početni period je od sutra u 09:00 na tri dana', () {
      final period = RentalPeriod.initial(now);
      expect(period.pickupAt, DateTime(2026, 12, 2, 9));
      expect(period.returnAt, DateTime(2026, 12, 5, 9));
      expect(period.rentalDays, 3);
      expect(period.validate(now), isNull);
    });

    test('svaki započeti period od 24 sata je jedan dan', () {
      final pickupAt = DateTime(2026, 12, 2, 9);
      expect(RentalPeriod(pickupAt: pickupAt, returnAt: DateTime(2026, 12, 3, 9)).rentalDays, 1);
      expect(RentalPeriod(pickupAt: pickupAt, returnAt: DateTime(2026, 12, 3, 10)).rentalDays, 2);
      expect(RentalPeriod(pickupAt: pickupAt, returnAt: DateTime(2026, 12, 4, 9)).rentalDays, 2);
      expect(RentalPeriod(pickupAt: pickupAt, returnAt: DateTime(2026, 12, 2, 10)).rentalDays, 1);
    });

    test('poruke za neispravan period', () {
      final pickupAt = DateTime(2026, 12, 2, 9);
      expect(
        RentalPeriod(pickupAt: DateTime(2026, 12, 1, 14), returnAt: pickupAt).validate(now),
        'Vrijeme preuzimanja mora biti u budućnosti.',
      );
      expect(
        RentalPeriod(pickupAt: pickupAt, returnAt: pickupAt).validate(now),
        'Vrijeme vraćanja mora biti poslije vremena preuzimanja.',
      );
      expect(RentalPeriod(pickupAt: pickupAt, returnAt: DateTime(2027, 1, 1, 9)).validate(now), isNull);
      expect(
        RentalPeriod(pickupAt: pickupAt, returnAt: DateTime(2027, 1, 1, 9, 1)).validate(now),
        'Najam može trajati najviše 30 dana.',
      );
    });

    test('promjena preuzimanja pomjera vraćanje za isti broj dana', () {
      final period = RentalPeriod(pickupAt: DateTime(2026, 12, 2, 9), returnAt: DateTime(2026, 12, 5, 18));
      final moved = period.withPickup(DateTime(2026, 12, 10, 12));
      expect(moved.returnAt, DateTime(2026, 12, 13, 18));

      final sameDay = RentalPeriod(pickupAt: DateTime(2026, 12, 2, 9), returnAt: DateTime(2026, 12, 2, 12));
      expect(sameDay.withPickup(DateTime(2026, 12, 4, 15)).returnAt, DateTime(2026, 12, 5, 15));
    });
  });

  group('prikaz vozila i recenzija', () {
    test('cijena, iznos i ocjena', () {
      expect(formatPricePerDay(70), '70 KM/dan');
      expect(formatPricePerDay(72.5), '72,5 KM/dan');
      expect(formatMoney(1250), '1.250,00 KM');
      expect(formatRating(4.6), '4,6');
      expect(parseDecimal(' 49,90 '), 49.9);
      expect(parseDecimal('abc'), isNull);
    });

    test('vozilo iz odgovora API-ja', () {
      final vehicle = Vehicle.fromJson({
        'id': 1,
        'registrationNumber': 'A12-B-345',
        'productionYear': 2022,
        'seatCount': 5,
        'description': null,
        'pricePerDay': 70,
        'isActive': true,
        'hasImage': true,
        'brandName': 'Volkswagen',
        'vehicleModelName': 'Golf',
        'categoryId': 2,
        'categoryName': 'Kompakt',
        'fuelTypeId': 2,
        'fuelTypeName': 'Dizel',
        'transmissionTypeId': 1,
        'transmissionTypeName': 'Manuelni',
        'averageRating': null,
        'reviewCount': 0,
      });
      expect(vehicle.name, 'Volkswagen Golf');
      expect(vehicle.pricePerDay, 70.0);
      expect(vehicle.averageRating, isNull);
    });

    test('autor recenzije prikazuje se imenom i inicijalom prezimena', () {
      Review review(String name) =>
          Review(id: 1, rating: 4, createdAt: DateTime.utc(2026, 11, 20), userFullName: name);
      expect(review('Selma Begić').authorName, 'Selma B.');
      expect(review('Ana Marija Kovač').authorName, 'Ana K.');
      expect(review('Amar').authorName, 'Amar');
    });
  });
}
