import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../layouts/master_screen.dart';
import '../models/equipment.dart';
import '../providers/equipment_provider.dart';
import '../utils/form_validators.dart';
import '../utils/formatters.dart';
import '../utils/utils_widgets.dart';
import '../widgets/crud_list_view.dart';
import '../widgets/data_table_card.dart';
import '../widgets/form_dialog.dart';
import '../widgets/status_badge.dart';

class EquipmentScreen extends StatelessWidget {
  const EquipmentScreen({super.key});

  static const String title = 'Dodatna oprema';

  @override
  Widget build(BuildContext context) {
    return MasterScreen(
      title: title,
      child: CrudListView<Equipment>(
        provider: context.read<EquipmentProvider>(),
        idOf: (item) => item.id,
        labels: CrudListLabels(
          searchHint: 'po nazivu',
          newItem: 'Nova oprema',
          deleteQuestion: (item) => 'Da li želite obrisati opremu „${item.name}”?',
          saved: 'Oprema je sačuvana.',
          deleted: 'Oprema je obrisana.',
        ),
        columns: const [
          TableColumnDef('Naziv', flex: 2),
          TableColumnDef('Cijena po danu'),
          TableColumnDef('Raspoloživa količina'),
          TableColumnDef('Status'),
        ],
        cells: (item) => [
          Text(item.name),
          Text(formatMoney(item.pricePerDay)),
          Text('${item.quantity}'),
          StatusBadge(active: item.isActive, activeLabel: 'Aktivna', inactiveLabel: 'Neaktivna'),
        ],
        openForm: _openForm,
        deleteBlockedReason: (item) => item.deleteBlockedReason,
      ),
    );
  }

  static Future<bool> _openForm(BuildContext context, Equipment? item) {
    final provider = context.read<EquipmentProvider>();
    return showFormDialog(
      context,
      title: item == null ? 'Nova oprema' : 'Izmjena opreme',
      focusField: 'name',
      initialValue: {
        'name': item?.name ?? '',
        'pricePerDay': item == null ? '' : formatDecimalInput(item.pricePerDay),
        'quantity': item == null ? '' : '${item.quantity}',
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
        FormBuilderTextField(
          name: 'pricePerDay',
          decoration: const InputDecoration(labelText: 'Cijena po danu', suffixText: 'KM'),
          validator: decimalValidator(
            requiredMessage: 'Cijena po danu je obavezna.',
            decimalsMessage: 'Cijena po danu može imati najviše dvije decimale.',
            range: (value) => value < 0
                ? 'Cijena po danu ne može biti negativna.'
                : value > 1000
                    ? 'Cijena po danu može biti najviše 1000 KM.'
                    : null,
          ),
          valueTransformer: parseDecimal,
          onSubmitted: (_) => submit(),
        ),
        FormBuilderTextField(
          name: 'quantity',
          decoration: const InputDecoration(labelText: 'Raspoloživa količina'),
          validator: integerValidator(
            requiredMessage: 'Količina je obavezna.',
            min: 0,
            max: 1000,
            rangeMessage: 'Količina mora biti između 0 i 1000.',
          ),
          valueTransformer: (value) => int.tryParse(value?.trim() ?? ''),
          onSubmitted: (_) => submit(),
        ),
        FormBuilderSwitch(
          name: 'isActive',
          title: Text('Aktivna (nudi se prilikom rezervacije)'),
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
}
