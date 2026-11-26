import 'package:flutter_test/flutter_test.dart';
import 'package:rentacar_mobile/models/user.dart';
import 'package:rentacar_mobile/utils/formatters.dart';
import 'package:rentacar_mobile/utils/user_validators.dart';

void main() {
  group('podaci korisnika (isto pravilo kao na serveru)', () {
    test('ime i prezime su obavezni i imaju najviše 50 znakova', () {
      expect(validateFirstName('  '), 'Ime je obavezno.');
      expect(validateLastName('a' * 51), 'Prezime može imati najviše 50 znakova.');
      expect(validateFirstName('Amar'), isNull);
    });

    test('e-mail, telefon i korisničko ime', () {
      expect(validateEmail('amar.hodzic'), 'E-mail nije ispravnog formata.');
      expect(validateEmail(' amar@example.com '), isNull);
      expect(validatePhone('061 111 222'), isNull);
      expect(validatePhone('061'), 'Broj telefona nije ispravnog formata.');
      expect(validateUsername('am'), 'Korisničko ime mora imati između 3 i 50 znakova.');
      expect(validateUsername('amar.hodžić'), startsWith('Korisničko ime smije sadržavati'));
      expect(validateUsername('amar.hodzic'), isNull);
    });

    test('lozinka, potvrda i kod za reset', () {
      expect(validatePassword('1234567'), 'Lozinka mora imati između 8 i 100 znakova.');
      expect(validatePassword('12345678'), isNull);
      expect(passwordConfirmValidator(() => '12345678')('12345679'), 'Lozinke se ne podudaraju.');
      expect(passwordConfirmValidator(() => '12345678')('12345678'), isNull);
      expect(validateResetCode('12345'), 'Kod mora imati 6 cifara.');
      expect(validateResetCode('12a456'), 'Kod mora imati 6 cifara.');
      expect(validateResetCode('123456'), isNull);
    });

    test('broj i datum vozačke dozvole unose se zajedno', () {
      expect(validateDriverLicenseNumber('', hasValidUntil: true), 'Unesite broj vozačke dozvole.');
      expect(validateDriverLicenseNumber('', hasValidUntil: false), isNull);
      expect(validateDriverLicenseValidUntil(null, hasNumber: true), 'Unesite datum do kojeg važi vozačka dozvola.');
      expect(validateDriverLicenseValidUntil(DateTime(2030), hasNumber: true), isNull);
    });
  });

  test('profil iz odgovora servera (datum dozvole bez vremena)', () {
    final user = User.fromJson({
      'id': 2,
      'firstName': 'Amar',
      'lastName': 'Hodžić',
      'email': 'amar@example.com',
      'phoneNumber': '061 111 222',
      'username': 'amar.hodzic',
      'driverLicenseNumber': 'B1234567',
      'driverLicenseValidUntil': '2030-05-01',
      'hasProfileImage': false,
      'roleName': 'Korisnik',
    });

    expect(user.fullName, 'Amar Hodžić');
    expect(user.hasDriverLicense, isTrue);
    expect(formatDate(user.driverLicenseValidUntil!), '01.05.2030');
    expect(toApiDate(user.driverLicenseValidUntil!), '2030-05-01');
    expect(user.withProfileImage(true).hasProfileImage, isTrue);
  });
}
