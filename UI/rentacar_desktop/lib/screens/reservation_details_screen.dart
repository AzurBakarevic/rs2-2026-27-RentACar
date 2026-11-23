import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../layouts/master_screen.dart';
import '../models/reservation.dart';
import '../providers/reservation_provider.dart';
import '../providers/vehicle_provider.dart';
import '../utils/api_client_exception.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/utils_widgets.dart';
import '../widgets/data_table_card.dart';
import '../widgets/form_close_button.dart';
import '../widgets/reservation_action_button.dart';
import '../widgets/reservation_status_badge.dart';
import '../widgets/user_avatar.dart';
import 'reservation_action_dialog.dart';
import 'reservation_list_screen.dart';
import 'vehicle_list_screen.dart';

class ReservationDetailsScreen extends StatefulWidget {
  const ReservationDetailsScreen({super.key, required this.reservationId});

  final int reservationId;

  @override
  State<ReservationDetailsScreen> createState() => _ReservationDetailsScreenState();
}

class _ReservationDetailsScreenState extends State<ReservationDetailsScreen> {
  Reservation? _reservation;
  String? _error;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final reservation = await context.read<ReservationProvider>().getById(widget.reservationId);
      if (mounted) {
        setState(() {
          _reservation = reservation;
          _isLoading = false;
        });
      }
    } on UnauthorizedException catch (_) {
    } on ApiClientException catch (e) {
      _showError(e.message);
    } catch (e) {
      debugPrint('Neočekivan odgovor za detalje rezervacije: $e');
      _showError('Odgovor servera nije moguće pročitati.');
    }
  }

  void _showError(String message) {
    if (mounted) {
      setState(() {
        _error = message;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MasterScreen(
      title: 'Detalji rezervacije',
      menuLabel: ReservationListScreen.title,
      child: Stack(
        children: [
          Positioned.fill(child: _buildBody()),
          Positioned(
            top: 8,
            right: 16,
            child: FormCloseButton(isSaving: false, onClose: () => Navigator.maybePop(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.error)),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: _load, child: const Text('Pokušaj ponovo')),
            ],
          ),
        ),
      );
    }

    final reservation = _reservation;
    if (reservation == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 24, 64, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(reservation),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildRental(reservation)),
              const SizedBox(width: 24),
              Expanded(child: _buildPayment(reservation)),
            ],
          ),
          const SizedBox(height: 24),
          const _SectionTitle('Dodatna oprema'),
          _buildEquipment(reservation.equipment ?? []),
          const SizedBox(height: 24),
          const _SectionTitle('Historija statusa'),
          _buildHistory(reservation.statusHistory ?? []),
        ],
      ),
    );
  }

  Widget _buildHeader(Reservation reservation) {
    return Row(
      children: [
        VehicleImage(
          vehicleId: reservation.vehicleId,
          hasImage: reservation.vehicleHasImage,
          provider: context.read<VehicleProvider>(),
          width: 168,
          height: 104,
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                reservation.vehicleName,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textDark),
              ),
              Text(
                reservation.vehicleRegistrationNumber,
                style: const TextStyle(fontSize: 16, color: AppColors.textMuted),
              ),
              const SizedBox(height: 12),
              ReservationStatusBadge(reservation.status),
            ],
          ),
        ),
        const SizedBox(width: 24),
        SizedBox(width: 320, child: _isLoading ? const LinearProgressIndicator() : _buildActions(reservation)),
      ],
    );
  }

  Widget _buildActions(Reservation reservation) {
    const hintStyle = TextStyle(fontSize: 14, color: AppColors.textMuted);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            for (final action in reservation.actions)
              ReservationActionButton(
                reservation: reservation,
                action: action,
                onPressed: () => _perform(reservation, action),
              ),
          ],
        ),
        for (final action in reservation.actions)
          if (reservation.blockedReason(action) case final reason?)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(reason, textAlign: TextAlign.end, style: hintStyle),
            ),
        if (reservation.status.isFinal)
          Text(
            'Rezervacija sa statusom „${reservation.status.label}” se više ne može mijenjati.',
            textAlign: TextAlign.end,
            style: hintStyle,
          ),
      ],
    );
  }

  Widget _buildRental(Reservation reservation) {
    final days = reservation.rentalDays;
    return _InfoCard(
      title: 'Najam',
      children: [
        _InfoRow(
          icon: Icons.person_outline,
          label: 'Korisnik',
          value: reservation.userFullName,
          leading: UserAvatar(userId: reservation.userId, hasImage: reservation.userHasImage),
        ),
        _InfoRow(icon: Icons.event_available_outlined, label: 'Preuzimanje', value: formatDateTime(reservation.pickupAt)),
        _InfoRow(icon: Icons.event_outlined, label: 'Vraćanje', value: formatDateTime(reservation.returnAt)),
        _InfoRow(icon: Icons.schedule, label: 'Trajanje', value: '$days ${pluralBs(days, 'dan', 'dana', 'dana')}'),
        _InfoRow(icon: Icons.edit_calendar_outlined, label: 'Kreirana', value: formatDateTime(reservation.createdAt)),
        if (reservation.cancellationReason case final reason?)
          _InfoRow(icon: Icons.info_outline, label: 'Razlog', value: reason),
      ],
    );
  }

  Widget _buildPayment(Reservation reservation) {
    final payment = reservation.payment;
    return _InfoCard(
      title: 'Obračun i uplata',
      children: [
        _InfoRow(
          icon: Icons.directions_car_outlined,
          label: 'Cijena vozila',
          value: formatMoney(reservation.vehiclePrice),
        ),
        _InfoRow(icon: Icons.trending_up, label: 'Sezonski dodatak', value: formatMoney(reservation.seasonalSurcharge)),
        _InfoRow(icon: Icons.add_box_outlined, label: 'Oprema', value: formatMoney(reservation.equipmentPrice)),
        _InfoRow(
          icon: Icons.payments_outlined,
          label: 'Ukupno',
          value: formatMoney(reservation.totalPrice),
          emphasized: true,
        ),
        const Divider(height: 24, color: AppColors.border),
        _InfoRow(
          icon: Icons.credit_card,
          label: 'Stanje uplate',
          value: payment?.status.label ?? 'Nije plaćeno',
          color: payment?.status == PaymentStatus.paid ? AppColors.success : null,
          emphasized: true,
        ),
        if (payment != null)
          _InfoRow(icon: Icons.receipt_long_outlined, label: 'Iznos uplate', value: formatMoney(payment.amount)),
        if (payment?.paidAt case final paidAt?)
          _InfoRow(icon: Icons.check_circle_outline, label: 'Plaćeno', value: formatDateTime(paidAt)),
        if (payment?.refundedAt case final refundedAt?)
          _InfoRow(icon: Icons.undo, label: 'Vraćeno', value: formatDateTime(refundedAt)),
        if (!reservation.isPaid && reservation.status == ReservationStatus.pending)
          _InfoRow(
            icon: Icons.hourglass_empty,
            label: 'Rok za plaćanje',
            value: formatDateTime(reservation.paymentDeadline),
          ),
      ],
    );
  }

  Widget _buildEquipment(List<ReservationEquipment> equipment) {
    return DataTableCard(
      columns: const [
        TableColumnDef('Naziv', flex: 2),
        TableColumnDef('Količina'),
        TableColumnDef('Cijena po danu'),
        TableColumnDef('Ukupno'),
      ],
      rows: [
        for (final item in equipment)
          [
            Text(item.equipmentName),
            Text('${item.quantity}'),
            Text(formatMoney(item.pricePerDay)),
            Text(formatMoney(item.totalPrice)),
          ],
      ],
      emptyText: 'Bez dodatne opreme.',
    );
  }

  Widget _buildHistory(List<ReservationStatusChange> history) {
    return DataTableCard(
      columns: const [
        TableColumnDef('Vrijeme', flex: 3),
        TableColumnDef('Promjena', flex: 4),
        TableColumnDef('Izvršio', flex: 3),
        TableColumnDef('Razlog', flex: 4),
      ],
      rows: [
        for (final change in history)
          [
            Text(formatDateTime(change.changedAt)),
            Text(switch (change.oldStatus) {
              null => 'Kreirana (${change.newStatus.label})',
              final old => '${old.label} → ${change.newStatus.label}',
            }),
            Text(change.changedByName ?? 'Sistem'),
            Text(change.reason ?? '–'),
          ],
      ],
      emptyText: 'Nema zapisa o promjenama.',
    );
  }

  Future<void> _perform(Reservation reservation, ReservationAction action) async {
    final done = await showReservationActionDialog(context, reservation, action);
    if (!mounted) {
      return;
    }
    if (done) {
      showSnack(context, reservationActionDone(action));
    }
    await _load();
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [_SectionTitle(title), ...children]),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.leading,
    this.color,
    this.emphasized = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Widget? leading;
  final Color? color;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textMuted),
          const SizedBox(width: 8),
          SizedBox(width: 148, child: Text(label, style: const TextStyle(fontSize: 15, color: AppColors.textMuted))),
          if (leading case final widget?) ...[widget, const SizedBox(width: 8)],
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 15,
                color: color ?? AppColors.textDark,
                fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
