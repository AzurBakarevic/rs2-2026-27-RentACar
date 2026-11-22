import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../layouts/master_screen.dart';
import '../models/vehicle_maintenance.dart';
import '../providers/vehicle_maintenance_provider.dart';
import '../providers/vehicle_provider.dart';
import '../utils/app_theme.dart';
import '../utils/form_validators.dart';
import '../utils/formatters.dart';
import '../utils/utils_widgets.dart';
import '../widgets/crud_list_view.dart';
import '../widgets/data_table_card.dart';
import '../widgets/date_filter_field.dart';
import '../widgets/form_dialog.dart';
import '../widgets/vehicle_search_field.dart';
import 'vehicle_list_screen.dart';

/// Servis vozila (prijava: „Upravljanje servisima vozila”): pretraga po vozilu ili datumu, dodavanje,
/// izmjena i brisanje. Servis koji se preklapa s rezervacijom ili drugim servisom odbija backend.
class VehicleMaintenanceScreen extends StatefulWidget {
  const VehicleMaintenanceScreen({super.key});

  static const String title = 'Servis vozila';

  @override
  State<VehicleMaintenanceScreen> createState() => _VehicleMaintenanceScreenState();
}

class _VehicleMaintenanceScreenState extends State<VehicleMaintenanceScreen> {
  DateTime? _date;

  // Servisi koji bar dijelom padaju u odabrani dan (od ponoći do ponoći po lokalnom vremenu).
  Map<String, dynamic> get _dateFilter => _date == null
      ? const {}
      : {'from': _date, 'to': DateTime(_date!.year, _date!.month, _date!.day + 1)};

  @override
  Widget build(BuildContext context) {
    final vehicleProvider = context.read<VehicleProvider>();
    return MasterScreen(
      title: VehicleMaintenanceScreen.title,
      child: CrudListView<VehicleMaintenance>(
        provider: context.read<VehicleMaintenanceProvider>(),
        idOf: (item) => item.id,
        searchKey: 'text',
        extraFilter: _dateFilter,
        filters: [DateFilterField(value: _date, onChanged: (value) => setState(() => _date = value))],
        onClearFilters: () => setState(() => _date = null),
        newBlockedReason: () async => await vehicleProvider.hasAny() ? null : 'Prvo dodajte vozilo na ekranu Vozila.',
        labels: CrudListLabels(
          searchHint: 'po vozilu ili registraciji',
          newItem: 'Novi servis',
          deleteQuestion: (item) => 'Da li želite obrisati servis vozila „${item.vehicleName} '
              '(${item.vehicleRegistrationNumber})” od ${formatDate(item.startAt)}?',
          saved: 'Servis je sačuvan.',
          deleted: 'Servis je obrisan.',
        ),
        columns: const [
          TableColumnDef('Vozilo', flex: 2),
          TableColumnDef('Registracija'),
          TableColumnDef('Od'),
          TableColumnDef('Do'),
          TableColumnDef('Opis', flex: 2),
          TableColumnDef('Trošak'),
        ],
        cells: (item) => [
          _VehicleCell(item: item, provider: vehicleProvider),
          Text(item.vehicleRegistrationNumber),
          _DateTimeCell(item.startAt),
          _DateTimeCell(item.endAt),
          Text(item.description, maxLines: 2, overflow: TextOverflow.ellipsis),
          Text(formatMoney(item.cost)),
        ],
        openForm: _openForm,
      ),
    );
  }

  static Future<bool> _openForm(BuildContext context, VehicleMaintenance? item) {
    final provider = context.read<VehicleMaintenanceProvider>();
    final vehicleProvider = context.read<VehicleProvider>();
    final formKey = GlobalKey<FormBuilderState>();
    return showFormDialog(
      context,
      title: item == null ? 'Novi servis' : 'Izmjena servisa',
      formKey: formKey,
      // Greške servera bez polja su o periodu (preklapanje s rezervacijom ili drugim servisom).
      focusField: 'startAt',
      width: 520,
      initialValue: {
        'vehicleId': item?.vehicleId,
        'startAt': item?.startAt.toLocal(),
        'endAt': item?.endAt.toLocal(),
        'description': item?.description ?? '',
        'cost': item == null ? '' : formatDecimalInput(item.cost),
      },
      buildFields: (submit) => [
        VehicleSearchField(
          name: 'vehicleId',
          provider: vehicleProvider,
          initialLabel: item == null ? null : '${item.vehicleName} (${item.vehicleRegistrationNumber})',
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _dateTimeField(
                name: 'startAt',
                label: 'Početak',
                initialTime: const TimeOfDay(hour: 8, minute: 0),
                validator: requiredValue('Početak servisa je obavezan.'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _dateTimeField(
                name: 'endAt',
                label: 'Kraj',
                initialTime: const TimeOfDay(hour: 16, minute: 0),
                validator: (value) {
                  if (value == null) {
                    return 'Kraj servisa je obavezan.';
                  }
                  final start = formKey.currentState?.fields['startAt']?.value as DateTime?;
                  return start != null && !value.isAfter(start) ? 'Kraj servisa mora biti poslije početka.' : null;
                },
              ),
            ),
          ],
        ),
        FormBuilderTextField(
          name: 'description',
          decoration: const InputDecoration(labelText: 'Opis', alignLabelWithHint: true),
          minLines: 2,
          maxLines: 4,
          validator: requiredText(
            'Opis je obavezan.',
            maxLength: 500,
            maxLengthMessage: 'Opis može imati najviše 500 znakova.',
          ),
          valueTransformer: (value) => value?.trim(),
        ),
        FormBuilderTextField(
          name: 'cost',
          decoration: const InputDecoration(labelText: 'Trošak', suffixText: 'KM'),
          validator: decimalValidator(
            requiredMessage: 'Trošak je obavezan.',
            decimalsMessage: 'Trošak može imati najviše dvije decimale.',
            range: (value) => value < 0
                ? 'Trošak ne može biti negativan.'
                : value > 100000
                    ? 'Trošak može biti najviše 100000 KM.'
                    : null,
          ),
          valueTransformer: parseDecimal,
          onSubmitted: (_) => submit(),
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

  // Datum pa vrijeme po lokalnom vremenu; API prima UTC (upute A.4).
  static Widget _dateTimeField({
    required String name,
    required String label,
    required TimeOfDay initialTime,
    required String? Function(DateTime?) validator,
  }) {
    return FormBuilderDateTimePicker(
      name: name,
      inputType: InputType.both,
      format: DateFormat('dd.MM.yyyy HH:mm'),
      initialTime: initialTime,
      decoration: InputDecoration(labelText: label, suffixIcon: const Icon(Icons.calendar_today_outlined)),
      validator: validator,
      valueTransformer: (value) => value?.toUtc().toIso8601String(),
    );
  }
}

/// Slika i naziv vozila u istoj ćeliji (upute 6).
class _VehicleCell extends StatelessWidget {
  const _VehicleCell({required this.item, required this.provider});

  final VehicleMaintenance item;
  final VehicleProvider provider;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Row(
        children: [
          VehicleImage(
            vehicleId: item.vehicleId,
            hasImage: item.vehicleHasImage,
            provider: provider,
            width: 64,
            height: 40,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(item.vehicleName, textAlign: TextAlign.start)),
        ],
      ),
    );
  }
}

/// Datum, a ispod njega vrijeme (servis ne mora trajati cijele dane).
class _DateTimeCell extends StatelessWidget {
  const _DateTimeCell(this.value);

  final DateTime value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(formatDate(value)),
        Text(formatTime(value), style: const TextStyle(fontSize: 14, color: AppColors.textMuted)),
      ],
    );
  }
}
