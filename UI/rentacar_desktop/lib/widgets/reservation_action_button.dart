import 'package:material_ui/material_ui.dart';

import '../models/reservation.dart';
import '../utils/app_theme.dart';

class ReservationActionButton extends StatelessWidget {
  const ReservationActionButton({
    super.key,
    required this.reservation,
    required this.action,
    required this.onPressed,
  });

  final Reservation reservation;
  final ReservationAction action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final blockedReason = reservation.blockedReason(action);
    final button = OutlinedButton(
      onPressed: blockedReason == null ? onPressed : null,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textDark,
        minimumSize: const Size(0, 40),
        visualDensity: VisualDensity.standard,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      child: Text(action.label),
    );
    return blockedReason == null ? button : Tooltip(message: blockedReason, child: button);
  }
}
