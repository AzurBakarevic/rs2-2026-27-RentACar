import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models/reservation.dart';
import '../providers/profile_provider.dart';
import '../providers/reservation_provider.dart';
import '../utils/api_client_exception.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/utils_widgets.dart';
import '../widgets/detail_row.dart';
import '../widgets/form_page.dart';
import '../widgets/notice_box.dart';
import '../widgets/reservation_widgets.dart';
import 'reservation_payment_screen.dart';
import 'review_create_screen.dart';

class ReservationDetailsScreen extends StatefulWidget {
  const ReservationDetailsScreen({super.key, required this.reservationId, this.initial});

  final int reservationId;
  final Reservation? initial;

  @override
  State<ReservationDetailsScreen> createState() => _ReservationDetailsScreenState();
}

class _ReservationDetailsScreenState extends State<ReservationDetailsScreen> {
  late Reservation? _reservation = widget.initial;
  bool _isLoading = true;
  bool _isCancelling = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final reservation = _reservation;
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            children: [
              const ScreenHeader(title: 'Detalji rezervacije'),
              SizedBox(height: 20, child: _isLoading && reservation != null ? const LinearProgressIndicator() : null),
              if (reservation == null) ..._buildPlaceholder() else ..._buildContent(reservation),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPlaceholder() {
    final error = _error;
    if (error == null) {
      return const [Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))];
    }
    return [
      const SizedBox(height: 24),
      Text(error, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted, fontSize: 16)),
      const SizedBox(height: 12),
      Center(child: OutlinedButton(onPressed: _load, child: const Text('Pokušaj ponovo'))),
    ];
  }

  List<Widget> _buildContent(Reservation reservation) {
    final equipment = reservation.equipment;
    final history = reservation.statusHistory ?? [];
    final cancellation = _cancellationNotice(reservation);
    return [
      NoticeBox(message: _error, bottomSpacing: 16),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DateBadge(reservation.pickupAt),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        reservation.vehicleName,
                        style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: AppColors.textDark),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ReservationStatusBadge(reservation.status),
                  ],
                ),
                const SizedBox(height: 10),
                Text(reservation.vehicleCategoryName, style: const TextStyle(fontSize: 16, color: AppColors.textDark)),
                const SizedBox(height: 8),
                Text(
                  reservation.vehicleRegistrationNumber,
                  style: const TextStyle(fontSize: 16, color: AppColors.textDark),
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 20),
      DetailRow(
        icon: Icons.calendar_today_outlined,
        label: 'Preuzimanje',
        value: formatDateTime(reservation.pickupAt),
        isFirst: true,
      ),
      DetailRow(icon: Icons.event_available_outlined, label: 'Vraćanje', value: formatDateTime(reservation.returnAt)),
      DetailRow(icon: Icons.schedule, label: 'Trajanje', value: formatDays(reservation.rentalDays)),
      DetailRow(
        icon: Icons.add_circle_outline,
        label: 'Oprema',
        value: equipment == null
            ? '…'
            : equipment.isEmpty
                ? 'Bez opreme'
                : equipment.map((x) => '${x.equipmentName} × ${x.quantity}').join('\n'),
      ),
      DetailRow(
        icon: Icons.payments_outlined,
        label: 'Ukupno',
        value: formatMoney(reservation.totalPrice),
        trailing: PaymentStatusBadge(reservation),
      ),
      if (cancellation != null) ...[
        const SizedBox(height: 20),
        NoticeBox(message: cancellation, type: NoticeType.warning, bottomSpacing: 0),
      ],
      if (history.isNotEmpty) ...[
        const SectionTitle('Historija statusa'),
        for (final change in history) _HistoryRow(change: change),
      ],
      const SizedBox(height: 24),
      ..._buildActions(reservation),
    ];
  }

  List<Widget> _buildActions(Reservation reservation) {
    final busy = _isCancelling;
    final cancelBlocked = reservation.blockedReason(ReservationAction.cancel);
    return [
      if (reservation.can(ReservationAction.pay)) ...[
        NoticeBox(
          message: 'Rezervacija još nije plaćena. Platite je do ${formatTime(reservation.paymentDeadline)}, '
              'inače se automatski otkazuje.',
          type: NoticeType.info,
          bottomSpacing: 12,
        ),
        FilledButton(onPressed: busy ? null : () => _openPayment(reservation), child: const Text('Plati rezervaciju')),
        const SizedBox(height: 16),
      ],
      if (reservation.can(ReservationAction.review)) ...[
        FilledButton(onPressed: () => _openReview(reservation), child: const Text('Ostavi recenziju')),
        const SizedBox(height: 16),
      ],
      if (reservation.hasReview)
        const Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: Text(
            'Za ovaj najam ste već ostavili recenziju. Hvala!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: AppColors.textMuted),
          ),
        ),
      if (reservation.can(ReservationAction.cancel)) ...[
        OutlinedButton(
          onPressed: busy ? null : () => _cancel(reservation),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.error,
            side: const BorderSide(color: AppColors.error, width: 1.5),
          ),
          child: busy
              ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
              : const Text('Otkaži rezervaciju'),
        ),
        const SizedBox(height: 12),
        const Text(
          'Otkazivanje je moguće do 24 sata prije preuzimanja, uz povrat punog iznosa.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: AppColors.textMuted),
        ),
      ] else if (cancelBlocked != null)
        Text(
          cancelBlocked,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
        ),
    ];
  }

  String? _cancellationNotice(Reservation reservation) {
    final change = reservation.cancellation;
    if (reservation.status != ReservationStatus.cancelled || change == null) {
      return null;
    }

    final currentUserId = context.watch<ProfileProvider>().profile?.id;
    final title = switch (change) {
      ReservationStatusChange(changedByUserId: null) => 'Rezervacija je automatski otkazana.',
      ReservationStatusChange(:final changedByUserId) when changedByUserId == currentUserId =>
        'Otkazali ste rezervaciju.',
      ReservationStatusChange(oldStatus: ReservationStatus.pending) => 'Agencija je odbila rezervaciju.',
      _ => 'Agencija je otkazala rezervaciju.',
    };

    final reason = change.reason;
    return [
      title,
      if (reason != null && reason.trim().isNotEmpty) 'Razlog: $reason',
      if (reservation.isRefunded) 'Uplaćeni iznos je vraćen na vašu karticu.',
    ].join('\n');
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final reservation = await context.read<ReservationProvider>().getById(widget.reservationId);
      if (mounted) {
        setState(() {
          _reservation = reservation;
          _error = null;
        });
      }
    } on ApiClientException catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError(unexpectedResponseError);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      setState(() => _error = message);
    }
  }

  Future<void> _openPayment(Reservation reservation) async {
    final paid = await Navigator.of(context).push<Reservation>(
      MaterialPageRoute(
        builder: (_) => ReservationPaymentScreen(reservation: reservation, openDetailsAfterPayment: false),
      ),
    );
    if (!mounted) {
      return;
    }
    if (paid != null) {
      setState(() => _reservation = paid);
    } else {
      await _load();
    }
  }

  Future<void> _openReview(Reservation reservation) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ReviewCreateScreen(reservation: reservation)),
    );
    if (saved == true && mounted) {
      await _load();
    }
  }

  Future<void> _cancel(Reservation reservation) async {
    final content = reservation.isPaid
        ? 'Da li ste sigurni da želite otkazati rezervaciju? '
            'Uplaćeni iznos od ${formatMoney(reservation.totalPrice)} bit će vraćen na vašu karticu.'
        : 'Da li ste sigurni da želite otkazati rezervaciju?';
    final confirmed = await confirmDialog(
      context,
      title: 'Otkazivanje rezervacije',
      content: content,
      confirmLabel: 'Otkaži rezervaciju',
      destructive: true,
    );
    if (!confirmed || !mounted) {
      return;
    }

    setState(() => _isCancelling = true);
    try {
      final cancelled = await context.read<ReservationProvider>().cancel(reservation.id);
      if (mounted) {
        setState(() {
          _reservation = cancelled;
          _error = null;
        });
        showSnack(context, 'Rezervacija je otkazana.');
      }
    } on ApiClientException catch (e) {
      await _load();
      _showError(e.message);
    } catch (_) {
      _showError(unexpectedResponseError);
    } finally {
      if (mounted) {
        setState(() => _isCancelling = false);
      }
    }
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.change});

  final ReservationStatusChange change;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(change.newStatus.label, style: const TextStyle(fontSize: 16, color: AppColors.textDark)),
          ),
          Text(formatDateTime(change.changedAt), style: const TextStyle(fontSize: 15, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}
