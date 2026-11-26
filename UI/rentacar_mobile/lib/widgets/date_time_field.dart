import 'package:material_ui/material_ui.dart';

import '../utils/app_theme.dart';
import '../utils/formatters.dart';

class DateTimeField extends StatelessWidget {
  const DateTimeField({
    super.key,
    required this.label,
    required this.value,
    required this.firstDate,
    required this.lastDate,
    required this.onChanged,
  });

  final String label;
  final DateTime value;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textMuted)),
        const SizedBox(height: 6),
        Semantics(
          button: true,
          label: label,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _pick(context),
            child: InputDecorator(
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                prefixIcon: Icon(Icons.calendar_today_outlined, size: 20, color: AppColors.textMuted),
                prefixIconConstraints: BoxConstraints(minWidth: 40, minHeight: 20),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(formatDateTime(value), style: const TextStyle(fontSize: 16, color: AppColors.textDark)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pick(BuildContext context) async {
    final first = DateUtils.dateOnly(firstDate);
    final last = DateUtils.dateOnly(lastDate);
    final current = DateUtils.dateOnly(value);
    final initialDate = current.isBefore(first) ? first : (current.isAfter(last) ? last : current);

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: first,
      lastDate: last,
      helpText: '$label: datum',
    );
    if (date == null || !context.mounted) {
      return;
    }

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(value),
      helpText: '$label: vrijeme',
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (time == null) {
      return;
    }

    onChanged(DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }
}
