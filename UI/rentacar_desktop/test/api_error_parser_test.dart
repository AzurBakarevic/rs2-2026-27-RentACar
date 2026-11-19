import 'package:flutter_test/flutter_test.dart';
import 'package:rentacar_desktop/providers/base_provider.dart';
import 'package:rentacar_desktop/utils/api_client_exception.dart';

void main() {
  group('ApiErrorParser', () {
    test('greške validacije idu uz polja forme (camelCase)', () {
      final error = ApiErrorParser.fromResponse(
        400,
        '{"message":"Naziv je obavezan.","errors":{"Name":["Naziv je obavezan."],"BrandId":["Marka ne postoji."]}}',
        'opća poruka',
      );

      expect(error.message, 'Naziv je obavezan.');
      expect(error.fieldErrors, {'name': 'Naziv je obavezan.', 'brandId': 'Marka ne postoji.'});
    });

    test('poslovno pravilo (clientError) nije greška polja', () {
      final error = ApiErrorParser.fromResponse(
        400,
        '{"message":"Marka se koristi.","errors":{"clientError":["Marka se koristi."]}}',
        'opća poruka',
      );

      expect(error.message, 'Marka se koristi.');
      expect(error.fieldErrors, isEmpty);
    });

    test('tijelo koje nije JSON daje opću poruku', () {
      final error = ApiErrorParser.fromResponse(502, '<html>Bad gateway</html>', 'Došlo je do greške na serveru.');

      expect(error.message, 'Došlo je do greške na serveru.');
      expect(error.statusCode, 502);
    });
  });

  test('prazne vrijednosti filtera se ne šalju', () {
    final parameters = BaseProvider.getQueryParameters({
      'name': '  ',
      'brandId': null,
      'page': 2,
      'includeTotalCount': true,
    });

    expect(parameters, {'page': '2', 'includeTotalCount': 'true'});
  });
}
