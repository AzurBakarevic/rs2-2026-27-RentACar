import 'dart:async';

import 'package:flutter_stripe/flutter_stripe.dart'
    show
        FailureCode,
        PaymentSheetAppearance,
        PaymentSheetAppearanceColors,
        SetupPaymentSheetParameters,
        Stripe,
        StripeException;
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models/reservation.dart';
import '../providers/reservation_provider.dart';
import '../utils/api_client_exception.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/utils_widgets.dart';
import '../widgets/form_page.dart';
import '../widgets/notice_box.dart';
import '../widgets/reservation_widgets.dart';
import 'reservation_details_screen.dart';

class ReservationPaymentScreen extends StatefulWidget {
  const ReservationPaymentScreen({super.key, required this.reservation, this.openDetailsAfterPayment = true});

  final Reservation reservation;
  final bool openDetailsAfterPayment;

  @override
  State<ReservationPaymentScreen> createState() => _ReservationPaymentScreenState();
}

class _ReservationPaymentScreenState extends State<ReservationPaymentScreen> {
  static const String _merchantName = 'RentACar';
  static const String _successMessage = 'Plaćanje je uspješno. Rezervacija čeka potvrdu agencije.';

  late Reservation _reservation = widget.reservation;
  Timer? _timer;
  Duration _remaining = Duration.zero;
  bool _isPaying = false;
  String? _error;

  bool get _isExpired => _remaining <= Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(_updateRemaining));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateRemaining() {
    _remaining = _reservation.paymentDeadline.difference(DateTime.now());
    if (_isExpired) {
      _timer?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final reservation = _reservation;
    final equipment = reservation.equipment ?? [];
    final summary = [
      formatDays(reservation.rentalDays),
      for (final item in equipment) '${item.equipmentName} × ${item.quantity}',
    ].join(' · ');

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          children: [
            const ScreenHeader(title: 'Plaćanje rezervacije'),
            const SizedBox(height: 4),
            const SectionTitle('Rezervacija'),
            InfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reservation.vehicleName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${formatDateTime(reservation.pickupAt)} – ${formatDateTime(reservation.returnAt)}',
                    style: const TextStyle(fontSize: 15, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 8),
                  Text(summary, style: const TextStyle(fontSize: 15, color: AppColors.textDark)),
                ],
              ),
            ),
            const SectionTitle('Način plaćanja'),
            const InfoCard(
              child: Row(
                children: [
                  Icon(Icons.credit_card, color: AppColors.primary, size: 28),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text('Kartično plaćanje', style: TextStyle(fontSize: 16, color: AppColors.textDark)),
                  ),
                  Text('Stripe', style: TextStyle(fontSize: 14, color: AppColors.textMuted)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Podaci o kartici unose se u sigurnoj Stripe formi.',
              style: TextStyle(fontSize: 14, color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text('Ukupno za plaćanje', style: TextStyle(fontSize: 16, color: AppColors.textDark)),
                  ),
                  Text(
                    formatMoney(reservation.totalPrice),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            NoticeBox(message: _error, bottomSpacing: 16),
            FilledButton(
              onPressed: _isPaying || _isExpired ? null : _pay,
              child: _isPaying
                  ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                  : const Text('Plati rezervaciju'),
            ),
            const SizedBox(height: 12),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 18, color: AppColors.textMuted),
                SizedBox(width: 8),
                Text('Sigurno plaćanje putem Stripe-a', style: TextStyle(fontSize: 14, color: AppColors.textMuted)),
              ],
            ),
            const SizedBox(height: 20),
            _DeadlineBox(remaining: _remaining, deadline: reservation.paymentDeadline),
          ],
        ),
      ),
    );
  }

  Future<void> _pay() async {
    setState(() {
      _isPaying = true;
      _error = null;
    });

    final provider = context.read<ReservationProvider>();
    try {
      final intent = await provider.createPayment(_reservation.id);
      Stripe.publishableKey = intent.publishableKey;
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: intent.clientSecret,
          merchantDisplayName: _merchantName,
          style: ThemeMode.light,
          appearance: const PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(primary: AppColors.primary),
          ),
        ),
      );
      await Stripe.instance.presentPaymentSheet();

      final paid = await provider.confirmPayment(_reservation.id);
      _finish(paid);
    } on StripeException catch (e) {
      if (!mounted) {
        return;
      }
      if (e.error.code == FailureCode.Canceled) {
        showSnack(context, 'Plaćanje je prekinuto. Možete ga ponoviti dok rok ne istekne.');
      } else {
        final message = e.error.localizedMessage ?? e.error.message;
        setState(() => _error = message ?? 'Plaćanje nije uspjelo. Pokušajte ponovo.');
      }
    } on ApiClientException catch (e) {
      await _handleServerError(provider, e.message);
    } catch (_) {
      await _handleServerError(provider, unexpectedResponseError);
    } finally {
      if (mounted) {
        setState(() => _isPaying = false);
      }
    }
  }

  Future<void> _handleServerError(ReservationProvider provider, String message) async {
    final current = await _tryReload(provider);
    if (current != null && current.isPaid) {
      provider.reservationChanged();
      _finish(current);
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      if (current != null) {
        _reservation = current;
        _updateRemaining();
      }
      _error = message;
    });
  }

  Future<Reservation?> _tryReload(ReservationProvider provider) async {
    try {
      return await provider.getById(_reservation.id);
    } catch (_) {
      return null;
    }
  }

  void _finish(Reservation paid) {
    if (!mounted) {
      return;
    }
    showSnack(context, _successMessage);
    final navigator = Navigator.of(context);
    if (widget.openDetailsAfterPayment) {
      navigator.pushReplacement(
        MaterialPageRoute(builder: (_) => ReservationDetailsScreen(reservationId: paid.id, initial: paid)),
      );
    } else {
      navigator.pop(paid);
    }
  }
}

class _DeadlineBox extends StatelessWidget {
  const _DeadlineBox({required this.remaining, required this.deadline});

  final Duration remaining;
  final DateTime deadline;

  @override
  Widget build(BuildContext context) {
    final expired = remaining <= Duration.zero;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: expired ? AppColors.errorBackground : AppColors.infoBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: expired ? AppColors.error : AppColors.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rok za plaćanje',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark),
                ),
                const SizedBox(height: 6),
                Text(
                  expired
                      ? 'Rok za plaćanje je istekao. Rezervacija koja nije plaćena u roku od 15 minuta se automatski otkazuje.'
                      : 'Rezervaciju je potrebno platiti u roku od 15 minuta, u suprotnom se automatski otkazuje.',
                  style: const TextStyle(fontSize: 15, height: 1.4, color: AppColors.textDark),
                ),
                if (!expired) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Preostalo vrijeme: ${formatCountdown(remaining)} (do ${formatTime(deadline)})',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.primary),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
