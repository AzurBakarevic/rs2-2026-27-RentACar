import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:material_ui/material_ui.dart';

import '../utils/utils_widgets.dart';
import '../widgets/form_dialog.dart';

/// Forma za zapis šifarnika: naziv i, po potrebi, dodatna polja (npr. marka modela).
/// Vraća `true` ako je zapis sačuvan.
Future<bool> showReferenceDataDialog(
  BuildContext context, {
  required String title,
  required Map<String, dynamic> initialValue,
  List<Widget> extraFields = const [],
  required Future<void> Function(Map<String, dynamic> values) onSave,
}) {
  return showFormDialog(
    context,
    title: title,
    initialValue: initialValue,
    focusField: 'name',
    buildFields: (submit) => [
      FormBuilderTextField(
        name: 'name',
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Naziv'),
        validator: requiredText(
          'Naziv je obavezan.',
          maxLength: 50,
          maxLengthMessage: 'Naziv može imati najviše 50 znakova.',
        ),
        onSubmitted: (_) => submit(),
      ),
      ...extraFields,
    ],
    onSave: (values) {
      values['name'] = (values['name'] as String).trim();
      return onSave(values);
    },
  );
}
