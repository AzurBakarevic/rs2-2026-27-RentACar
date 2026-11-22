import 'package:material_ui/material_ui.dart';

import '../utils/app_theme.dart';

/// Polje za povezani zapis s dugmetom „+” za dodavanje bez napuštanja forme (upute 6).
class FieldWithAddButton extends StatelessWidget {
  const FieldWithAddButton({
    super.key,
    required this.field,
    required this.tooltip,
    required this.onAdd,
    this.blockedReason,
  });

  final Widget field;
  final String tooltip;
  final VoidCallback onAdd;

  /// Razlog zbog kojeg dodavanje trenutno nije moguće ili `null`.
  final String? blockedReason;

  @override
  Widget build(BuildContext context) {
    return Row(
      // Dugme ostaje uz polje i kad se ispod polja prikaže poruka.
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: field),
        const SizedBox(width: 4),
        SizedBox(
          width: 40,
          height: 48,
          child: IconButton(
            tooltip: blockedReason ?? tooltip,
            color: AppColors.primary,
            icon: const Icon(Icons.add),
            onPressed: blockedReason == null ? onAdd : null,
          ),
        ),
      ],
    );
  }
}
