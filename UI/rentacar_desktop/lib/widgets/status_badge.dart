import 'package:material_ui/material_ui.dart';

import '../utils/app_theme.dart';

/// Oznaka statusa u tabeli: zelena „● Aktivno” ili crvena „● Neaktivno”, kao na skicama.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.active, required this.activeLabel, required this.inactiveLabel});

  final bool active;
  final String activeLabel;
  final String inactiveLabel;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.success : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: active ? AppColors.successBackground : AppColors.errorBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(
            active ? activeLabel : inactiveLabel,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
