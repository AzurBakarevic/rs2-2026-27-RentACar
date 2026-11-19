import 'package:flutter_form_builder/flutter_form_builder.dart';

import 'api_client_exception.dart';

/// Briše greške koje je ranije vratio server, da bi se forma mogla ponovo poslati.
void clearServerErrors(FormBuilderState form) {
  for (final field in form.fields.values) {
    field.validate(clearCustomError: true, focusOnInvalid: false);
  }
}

/// Greške validacije sa servera prikazuje ispod odgovarajućih polja forme.
/// Vraća poruku koju treba prikazati iznad forme, ili `null` ako su sve greške uz polja.
String? applyServerErrors(FormBuilderState form, ApiClientException error) {
  var allShown = error.fieldErrors.isNotEmpty;
  error.fieldErrors.forEach((name, message) {
    final field = form.fields[name];
    if (field == null) {
      allShown = false;
    } else {
      field.invalidate(message, shouldFocus: false);
    }
  });
  return allShown ? null : error.message;
}

/// Vraća fokus na prvo polje s greškom, a bez njega na [fallbackField].
/// Klik na dugme za slanje skida fokus s polja, pa bi korisnik morao ponovo kliknuti u formu.
void focusFirstError(FormBuilderState form, String fallbackField) {
  final field = form.fields.values.where((f) => f.hasError).firstOrNull ?? form.fields[fallbackField];
  field?.focus();
}
