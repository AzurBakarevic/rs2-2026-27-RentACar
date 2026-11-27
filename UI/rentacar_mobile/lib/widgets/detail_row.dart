import 'package:material_ui/material_ui.dart';

import '../utils/app_theme.dart';

class DetailRow extends StatelessWidget {
  const DetailRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
    this.isFirst = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    const side = BorderSide(color: AppColors.border);
    final trailingWidget = trailing;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: Border(top: isFirst ? side : BorderSide.none, bottom: side),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 16),
          Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 16, color: AppColors.textDark),
            ),
          ),
          if (trailingWidget != null) ...[const SizedBox(width: 10), trailingWidget],
        ],
      ),
    );
  }
}
