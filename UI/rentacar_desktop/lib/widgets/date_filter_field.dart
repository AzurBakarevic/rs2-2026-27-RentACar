import 'package:material_ui/material_ui.dart';

import '../utils/app_theme.dart';
import '../utils/formatters.dart';

/// Filter po jednom datumu iznad tabele (skica „Servis vozila”); `x` briše odabrani datum.
class DateFilterField extends StatelessWidget {
  const DateFilterField({super.key, required this.value, required this.onChanged, this.hintText = 'Datum'});

  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _pick(context),
        child: InputDecorator(
          isEmpty: value == null,
          decoration: InputDecoration(
            hintText: hintText,
            isDense: true,
            contentPadding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
            suffixIcon: value == null
                ? const Icon(Icons.calendar_today_outlined, color: AppColors.textMuted)
                : IconButton(
                    tooltip: 'Ukloni datum',
                    icon: const Icon(Icons.close),
                    onPressed: () => onChanged(null),
                  ),
          ),
          child: Text(value == null ? '' : formatDate(value!), style: const TextStyle(fontSize: 16)),
        ),
      ),
    );
  }

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: value ?? now,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 5, 12, 31),
    );
    if (picked != null) {
      onChanged(picked);
    }
  }
}
