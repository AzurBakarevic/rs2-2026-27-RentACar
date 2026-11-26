import 'package:material_ui/material_ui.dart';

import '../models/named_entity.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';

class VehicleFilter {
  const VehicleFilter({this.fuelTypeId, this.transmissionTypeId, this.minPrice, this.maxPrice});

  final int? fuelTypeId;
  final int? transmissionTypeId;
  final double? minPrice;
  final double? maxPrice;

  int get activeCount =>
      (fuelTypeId == null ? 0 : 1) +
      (transmissionTypeId == null ? 0 : 1) +
      (minPrice == null && maxPrice == null ? 0 : 1);
}

class VehicleFilterSheet extends StatefulWidget {
  const VehicleFilterSheet({
    super.key,
    required this.initial,
    required this.fuelTypes,
    required this.transmissionTypes,
  });

  final VehicleFilter initial;
  final List<NamedEntity> fuelTypes;
  final List<NamedEntity> transmissionTypes;

  @override
  State<VehicleFilterSheet> createState() => _VehicleFilterSheetState();
}

class _VehicleFilterSheetState extends State<VehicleFilterSheet> {
  late int? _fuelTypeId = widget.initial.fuelTypeId;
  late int? _transmissionTypeId = widget.initial.transmissionTypeId;
  late final TextEditingController _minPrice = TextEditingController(text: _toInput(widget.initial.minPrice));
  late final TextEditingController _maxPrice = TextEditingController(text: _toInput(widget.initial.maxPrice));
  String? _priceError;

  @override
  void dispose() {
    _minPrice.dispose();
    _maxPrice.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Filteri', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textDark)),
          const SizedBox(height: 20),
          const _Label('Vrsta goriva'),
          _buildChoices(widget.fuelTypes, _fuelTypeId, (id) => setState(() => _fuelTypeId = id)),
          const SizedBox(height: 20),
          const _Label('Vrsta mjenjača'),
          _buildChoices(widget.transmissionTypes, _transmissionTypeId, (id) => setState(() => _transmissionTypeId = id)),
          const SizedBox(height: 20),
          const _Label('Cijena po danu (KM)'),
          Row(
            children: [
              Expanded(child: _buildPriceField(_minPrice, 'Od', TextInputAction.next)),
              const SizedBox(width: 12),
              Expanded(child: _buildPriceField(_maxPrice, 'Do', TextInputAction.done)),
            ],
          ),
          if (_priceError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_priceError!, style: const TextStyle(color: AppColors.error, fontSize: 14)),
            ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, const VehicleFilter()),
                  child: const Text('Poništi'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: FilledButton(onPressed: _apply, child: const Text('Primijeni'))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChoices(List<NamedEntity> items, int? selectedId, ValueChanged<int?> onChanged) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(label: const Text('Sve'), selected: selectedId == null, onSelected: (_) => onChanged(null)),
        for (final item in items)
          ChoiceChip(label: Text(item.name), selected: selectedId == item.id, onSelected: (_) => onChanged(item.id)),
      ],
    );
  }

  Widget _buildPriceField(TextEditingController controller, String label, TextInputAction action) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: action,
      decoration: InputDecoration(labelText: label),
    );
  }

  void _apply() {
    final minText = _minPrice.text.trim();
    final maxText = _maxPrice.text.trim();
    final min = parseDecimal(minText);
    final max = parseDecimal(maxText);

    String? error;
    if ((minText.isNotEmpty && (min == null || min < 0)) || (maxText.isNotEmpty && (max == null || max < 0))) {
      error = 'Unesite ispravnu cijenu.';
    } else if (min != null && max != null && min > max) {
      error = 'Najniža cijena ne može biti veća od najviše.';
    }

    if (error != null) {
      setState(() => _priceError = error);
      return;
    }

    Navigator.pop(
      context,
      VehicleFilter(fuelTypeId: _fuelTypeId, transmissionTypeId: _transmissionTypeId, minPrice: min, maxPrice: max),
    );
  }

  static String _toInput(double? value) => value == null ? '' : formatDecimalInput(value);
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark)),
    );
  }
}
