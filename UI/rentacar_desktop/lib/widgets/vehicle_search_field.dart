import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:material_ui/material_ui.dart';

import '../models/vehicle.dart';
import '../providers/vehicle_provider.dart';
import '../utils/api_client_exception.dart';
import '../utils/form_validators.dart';

/// Vozilo kako se prikazuje u formi, npr. „Volkswagen Golf (A12-K-345)”.
String vehicleLabel(Vehicle vehicle) => '${vehicle.name} (${vehicle.registrationNumber})';

/// Polje forme za odabir vozila: kucanjem se traži po marki, modelu ili registraciji na serveru,
/// jer vozila može biti više nego što stane u jednu stranicu (upute 8.2). Vrijednost polja je Id vozila.
class VehicleSearchField extends StatelessWidget {
  const VehicleSearchField({super.key, required this.name, required this.provider, this.initialLabel});

  final String name;
  final VehicleProvider provider;

  /// Tekst za vozilo iz [FormBuilder.initialValue] (kod izmjene).
  final String? initialLabel;

  @override
  Widget build(BuildContext context) {
    return FormBuilderField<int>(
      name: name,
      validator: requiredValue('Vozilo je obavezno.'),
      builder: (field) => _VehicleAutocomplete(field: field, provider: provider, initialLabel: initialLabel),
    );
  }
}

class _VehicleAutocomplete extends StatefulWidget {
  const _VehicleAutocomplete({required this.field, required this.provider, this.initialLabel});

  final FormFieldState<int> field;
  final VehicleProvider provider;
  final String? initialLabel;

  @override
  State<_VehicleAutocomplete> createState() => _VehicleAutocompleteState();
}

class _VehicleAutocompleteState extends State<_VehicleAutocomplete> {
  static const Duration _debounce = Duration(milliseconds: 300);

  late final TextEditingController _controller = TextEditingController(text: widget.initialLabel ?? '');
  late String? _selectedLabel = widget.initialLabel;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final field = widget.field as FormBuilderFieldState<FormBuilderField<int>, int>;
    return Autocomplete<Vehicle>(
      focusNode: field.effectiveFocusNode,
      textEditingController: _controller,
      displayStringForOption: vehicleLabel,
      optionsBuilder: _search,
      onSelected: (vehicle) {
        _selectedLabel = vehicleLabel(vehicle);
        field.didChange(vehicle.id);
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) => TextField(
        controller: controller,
        focusNode: focusNode,
        decoration: InputDecoration(
          labelText: 'Vozilo',
          hintText: 'po marki, modelu ili registraciji',
          errorText: field.errorText,
          suffixIcon: const Icon(Icons.search),
        ),
        onChanged: (text) {
          // Izmijenjen tekst više ne odgovara odabranom vozilu.
          if (text != _selectedLabel && field.value != null) {
            field.didChange(null);
          }
        },
        onSubmitted: (_) => onFieldSubmitted(),
      ),
    );
  }

  Future<Iterable<Vehicle>> _search(TextEditingValue value) async {
    final text = value.text.trim();
    if (text.isEmpty || value.text == _selectedLabel) {
      return const [];
    }

    // Zahtjev ide tek kad se prestane kucati; Autocomplete sam odbacuje zakašnjele odgovore.
    await Future<void>.delayed(_debounce);
    if (!mounted || _controller.text.trim() != text) {
      return const [];
    }

    try {
      final result = await widget.provider.get(filter: {'text': text, 'pageSize': 10});
      return result.items ?? const [];
    } on ApiClientException {
      // Lista ostaje prazna; greška pri spremanju forme će se prikazati iznad polja.
      return const [];
    }
  }
}
