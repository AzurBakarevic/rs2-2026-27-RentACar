import 'package:flutter_form_builder/flutter_form_builder.dart';

import 'api_client_exception.dart';

void clearServerErrors(FormBuilderState form) {
  for (final field in form.fields.values) {
    field.validate(clearCustomError: true, focusOnInvalid: false);
  }
}

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

void focusFirstError(FormBuilderState form, String fallbackField) {
  final field = form.fields.values.where((f) => f.hasError).firstOrNull ?? form.fields[fallbackField];
  field?.focus();
}
