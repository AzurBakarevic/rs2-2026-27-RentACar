import 'package:material_ui/material_ui.dart';

import '../models/reservation.dart';
import '../utils/app_theme.dart';
import 'status_badge.dart';

/// Status rezervacije u boji kao na skici „Rezervacije”.
class ReservationStatusBadge extends StatelessWidget {
  const ReservationStatusBadge(this.status, {super.key});

  final ReservationStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, background) = switch (status) {
      ReservationStatus.pending => (AppColors.warning, AppColors.warningBackground),
      ReservationStatus.confirmed => (AppColors.confirmed, AppColors.confirmedBackground),
      ReservationStatus.completed => (AppColors.success, AppColors.successBackground),
      ReservationStatus.cancelled => (AppColors.error, AppColors.errorBackground),
    };
    return StatusPill(
      label: status.label,
      color: color,
      background: background,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      fontSize: 14,
    );
  }
}
