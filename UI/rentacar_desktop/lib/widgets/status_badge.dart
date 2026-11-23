import 'package:material_ui/material_ui.dart';

import '../utils/app_theme.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.active, required this.activeLabel, required this.inactiveLabel});

  final bool active;
  final String activeLabel;
  final String inactiveLabel;

  @override
  Widget build(BuildContext context) {
    return StatusPill(
      label: active ? activeLabel : inactiveLabel,
      color: active ? AppColors.success : AppColors.error,
      background: active ? AppColors.successBackground : AppColors.errorBackground,
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    required this.color,
    required this.background,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    this.fontSize,
  });

  final String label;
  final Color color;
  final Color background;
  final EdgeInsets padding;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
