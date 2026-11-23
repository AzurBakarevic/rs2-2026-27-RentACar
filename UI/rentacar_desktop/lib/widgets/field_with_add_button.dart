import 'package:material_ui/material_ui.dart';

import '../utils/app_theme.dart';

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

  final String? blockedReason;

  @override
  Widget build(BuildContext context) {
    return Row(
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
