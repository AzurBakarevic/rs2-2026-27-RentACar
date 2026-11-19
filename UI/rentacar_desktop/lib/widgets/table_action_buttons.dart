import 'package:material_ui/material_ui.dart';

import '../utils/app_theme.dart';

/// Dugmad za izmjenu i brisanje u koloni „Akcije”.
class TableActionButtons extends StatelessWidget {
  const TableActionButtons({super.key, this.onEdit, this.onDelete});

  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onEdit != null) _ActionButton(icon: Icons.edit_outlined, tooltip: 'Izmijeni', onPressed: onEdit!),
        if (onEdit != null && onDelete != null) const SizedBox(width: 12),
        if (onDelete != null) _ActionButton(icon: Icons.delete_outline, tooltip: 'Obriši', onPressed: onDelete!),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.icon, required this.tooltip, required this.onPressed});

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon),
      color: AppColors.textDark,
      style: IconButton.styleFrom(
        fixedSize: const Size(44, 44),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
    );
  }
}
