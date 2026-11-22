import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models/brand.dart';
import '../models/vehicle_model.dart';
import '../providers/brand_provider.dart';
import '../providers/vehicle_model_provider.dart';
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

/// Nova marka iz forme koja je bira; vraća sačuvanu marku ili `null`.
Future<Brand?> showNewBrandDialog(BuildContext context) async {
  final provider = context.read<BrandProvider>();
  Brand? created;
  final saved = await showReferenceDataDialog(
    context,
    title: 'Nova marka',
    initialValue: {'name': ''},
    onSave: (values) async {
      created = await provider.insert(values);
    },
  );
  return saved ? created : null;
}

/// Novi model za već odabranu marku; vraća sačuvani model ili `null`.
Future<VehicleModel?> showNewVehicleModelDialog(
  BuildContext context, {
  required int brandId,
  required Widget brandName,
}) async {
  final provider = context.read<VehicleModelProvider>();
  VehicleModel? created;
  final saved = await showReferenceDataDialog(
    context,
    title: 'Novi model',
    initialValue: {'name': ''},
    extraFields: [
      InputDecorator(decoration: const InputDecoration(labelText: 'Marka', enabled: false), child: brandName),
    ],
    onSave: (values) async {
      created = await provider.insert({...values, 'brandId': brandId});
    },
  );
  return saved ? created : null;
}
