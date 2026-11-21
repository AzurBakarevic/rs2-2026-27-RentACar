import 'package:flutter_test/flutter_test.dart';
import 'package:rentacar_desktop/utils/form_validators.dart';
import 'package:rentacar_desktop/utils/formatters.dart';

void main() {
  group('prikaz', () {
    test('iznos i procenat kao na skicama', () {
      expect(formatMoney(70), '70,00 KM');
      expect(formatMoney(1234.5), '1.234,50 KM');
      expect(formatIncrease(20), '+20%');
      expect(formatIncrease(12.5), '+12,5%');
    });

    test('datum za API i dan u sedmici', () {
      final date = DateTime(2026, 11, 2);
      expect(toApiDate(date), '2026-11-02');
      expect(formatDate(date), '02.11.2026');
      expect(formatWeekday(date), 'Pon');
      expect(formatWeekday(DateTime(2026, 11, 8)), 'Ned');
    });

    test('vrijednost za polje forme bez suvišnih nula', () {
      expect(formatDecimalInput(70), '70');
      expect(formatDecimalInput(70.5), '70,5');
      expect(parseDecimal('70,50'), 70.5);
      expect(parseDecimal(' 70.50 '), 70.5);
      expect(parseDecimal(''), isNull);
    });

    test('tri oblika množine', () {
      String form(int n) => pluralBs(n, 'rezervacija', 'rezervacije', 'rezervacija');
      expect(form(1), 'rezervacija');
      expect(form(3), 'rezervacije');
      expect(form(5), 'rezervacija');
      expect(form(11), 'rezervacija');
      expect(form(12), 'rezervacija');
      expect(form(21), 'rezervacija');
      expect(form(22), 'rezervacije');
    });
  });

  group('validatori (iste poruke kao na backendu)', () {
    final price = decimalValidator(
      requiredMessage: 'obavezno',
      decimalsMessage: 'decimale',
      range: (value) => value <= 0 ? 'veće od 0' : null,
    );

    test('decimalni broj', () {
      expect(price(''), 'obavezno');
      expect(price('abc'), 'Unesite broj, npr. 70,50.');
      expect(price('1e5'), 'Unesite broj, npr. 70,50.');
      expect(price('70,505'), 'decimale');
      expect(price('-5'), 'veće od 0');
      expect(price('70,50'), isNull);
      expect(price('70'), isNull);
    });

    test('cijeli broj u rasponu', () {
      final seats = integerValidator(requiredMessage: 'obavezno', min: 1, max: 9, rangeMessage: 'raspon');
      expect(seats(' '), 'obavezno');
      expect(seats('2,5'), 'Unesite cijeli broj.');
      expect(seats('10'), 'raspon');
      expect(seats('5'), isNull);
    });
  });
}
