import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../layouts/master_screen.dart';
import '../models/seasonal_price.dart';
import '../providers/seasonal_price_provider.dart';
import '../utils/form_validators.dart';
import '../utils/formatters.dart';
import '../utils/utils_widgets.dart';
import '../widgets/crud_list_view.dart';
import '../widgets/data_table_card.dart';
import '../widgets/form_dialog.dart';
import '../widgets/status_badge.dart';

/// Sezonske cijene (prijava: „Upravljanje sezonskim cijenama”): periodi u kojima se cijena najma
/// uvećava za zadani procenat. Preklapanje dviju aktivnih sezona odbija backend.
class SeasonalPriceScreen extends StatelessWidget {
  const SeasonalPriceScreen({super.key});

  static const String title = 'Sezonske cijene';

  @override
  Widget build(BuildContext context) {
    return MasterScreen(
      title: title,
      child: CrudListView<SeasonalPrice>(
        provider: context.read<SeasonalPriceProvider>(),
        idOf: (item) => item.id,
        labels: CrudListLabels(
          searchHint: 'po nazivu',
          newItem: 'Nova sezonska cijena',
          deleteQuestion: (item) => 'Da li želite obrisati sezonsku cijenu „${item.name}”?',
          saved: 'Sezonska cijena je sačuvana.',
          deleted: 'Sezonska cijena je obrisana.',
        ),
        columns: const [
          TableColumnDef('Naziv', flex: 2),
          TableColumnDef('Od'),
          TableColumnDef('Do'),
          TableColumnDef('Uvećanje cijene'),
          TableColumnDef('Status'),
        ],
        cells: (item) => [
          Text(item.name),
          Text(formatDate(item.startDate)),
          Text(formatDate(item.endDate)),
          Text(formatIncrease(item.increasePercentage)),
          StatusBadge(active: item.isActive, activeLabel: 'Aktivna', inactiveLabel: 'Neaktivna'),
        ],
        openForm: _openForm,
      ),
    );
  }

  static Future<bool> _openForm(BuildContext context, SeasonalPrice? item) {
    final provider = context.read<SeasonalPriceProvider>();
    final formKey = GlobalKey<FormBuilderState>();
    return showFormDialog(
      context,
      title: item == null ? 'Nova sezonska cijena' : 'Izmjena sezonske cijene',
      formKey: formKey,
      focusField: 'name',
      initialValue: {
        'name': item?.name ?? '',
        'startDate': item?.startDate,
        'endDate': item?.endDate,
        'increasePercentage': item == null ? '' : formatDecimalInput(item.increasePercentage),
        'isActive': item?.isActive ?? true,
      },
      buildFields: (submit) => [
        FormBuilderTextField(
          name: 'name',
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Naziv'),
          validator: requiredText(
            'Naziv je obavezan.',
            maxLength: 100,
            maxLengthMessage: 'Naziv može imati najviše 100 znakova.',
          ),
          valueTransformer: (value) => value?.trim(),
          onSubmitted: (_) => submit(),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _dateField(
                name: 'startDate',
                label: 'Od',
                validator: requiredValue('Datum početka je obavezan.'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _dateField(
                name: 'endDate',
                label: 'Do',
                validator: (value) {
                  if (value == null) {
                    return 'Datum završetka je obavezan.';
                  }
                  final start = formKey.currentState?.fields['startDate']?.value as DateTime?;
                  return start != null && value.isBefore(start)
                      ? 'Datum završetka ne može biti prije datuma početka.'
                      : null;
                },
              ),
            ),
          ],
        ),
        FormBuilderTextField(
          name: 'increasePercentage',
          decoration: const InputDecoration(labelText: 'Uvećanje cijene', suffixText: '%'),
          validator: decimalValidator(
            requiredMessage: 'Uvećanje cijene je obavezno.',
            decimalsMessage: 'Uvećanje cijene može imati najviše dvije decimale.',
            range: (value) => value <= 0
                ? 'Uvećanje cijene mora biti veće od 0 %.'
                : value > 100
                    ? 'Uvećanje cijene može biti najviše 100 %.'
                    : null,
          ),
          valueTransformer: parseDecimal,
          onSubmitted: (_) => submit(),
        ),
        FormBuilderSwitch(
          name: 'isActive',
          title: Text('Aktivna (uračunava se u cijenu najma)'),
          decoration: plainFieldDecoration,
        ),
      ],
      onSave: (values) async {
        if (item == null) {
          await provider.insert(values);
        } else {
          await provider.update(item.id, values);
        }
      },
    );
  }

  // Samo datum; oba datuma su uključena u period (od 20.12. do 05.01.).
  static Widget _dateField({
    required String name,
    required String label,
    required String? Function(DateTime?) validator,
  }) {
    return FormBuilderDateTimePicker(
      name: name,
      inputType: InputType.date,
      format: DateFormat('dd.MM.yyyy'),
      decoration: InputDecoration(labelText: label, suffixIcon: const Icon(Icons.calendar_today_outlined)),
      validator: validator,
      valueTransformer: (value) => value == null ? null : toApiDate(value),
    );
  }
}
