import 'package:material_ui/material_ui.dart';

import '../models/reservation.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, required this.foreground, required this.background});

  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: TextStyle(color: foreground, fontSize: 13, fontWeight: FontWeight.w700)),
    );
  }
}

class ReservationStatusBadge extends StatelessWidget {
  const ReservationStatusBadge(this.status, {super.key});

  final ReservationStatus status;

  @override
  Widget build(BuildContext context) {
    final (foreground, background) = switch (status) {
      ReservationStatus.pending => (AppColors.warning, AppColors.warningBackground),
      ReservationStatus.confirmed => (AppColors.confirmed, AppColors.confirmedBackground),
      ReservationStatus.completed => (AppColors.success, AppColors.successBackground),
      ReservationStatus.cancelled => (AppColors.error, AppColors.errorBackground),
    };
    return StatusBadge(label: status.label, foreground: foreground, background: background);
  }
}

class PaymentStatusBadge extends StatelessWidget {
  const PaymentStatusBadge(this.reservation, {super.key});

  final Reservation reservation;

  @override
  Widget build(BuildContext context) {
    if (reservation.isRefunded) {
      return const StatusBadge(label: 'Vraćeno', foreground: AppColors.confirmed, background: AppColors.confirmedBackground);
    }
    if (reservation.isPaid) {
      return const StatusBadge(label: 'Plaćeno', foreground: AppColors.success, background: AppColors.successBackground);
    }
    return const StatusBadge(label: 'Nije plaćeno', foreground: AppColors.warning, background: AppColors.warningBackground);
  }
}

class DateBadge extends StatelessWidget {
  const DateBadge(this.date, {super.key, this.width = 88});

  final DateTime date;
  final double width;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(fontSize: 15, color: AppColors.primary);
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
      decoration: BoxDecoration(color: AppColors.avatarBackground, borderRadius: BorderRadius.circular(14)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(formatWeekdayShort(date), style: style),
          Text(
            '${date.toLocal().day}',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.primary, height: 1.2),
          ),
          FittedBox(fit: BoxFit.scaleDown, child: Text(formatMonthName(date), style: style)),
        ],
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  const InfoCard({super.key, required this.child, this.padding = const EdgeInsets.all(16)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 10),
      child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark)),
    );
  }
}

class AmountRow extends StatelessWidget {
  const AmountRow({super.key, required this.label, required this.amount, this.isTotal = false});

  final String label;
  final double amount;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: isTotal ? 19 : 16,
      fontWeight: isTotal ? FontWeight.w700 : FontWeight.w400,
      color: AppColors.textDark,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          const SizedBox(width: 12),
          Text(formatMoney(amount), style: style),
        ],
      ),
    );
  }
}
