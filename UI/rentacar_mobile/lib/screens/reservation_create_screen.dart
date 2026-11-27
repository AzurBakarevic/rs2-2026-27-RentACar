import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models/equipment.dart';
import '../models/reservation_calculation.dart';
import '../models/vehicle.dart';
import '../providers/equipment_provider.dart';
import '../providers/reservation_provider.dart';
import '../utils/api_client_exception.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/rental_period.dart';
import '../utils/utils_widgets.dart';
import '../widgets/date_time_field.dart';
import '../widgets/form_page.dart';
import '../widgets/notice_box.dart';
import '../widgets/reservation_widgets.dart';
import '../widgets/vehicle_widgets.dart';
import 'reservation_payment_screen.dart';

class ReservationCreateScreen extends StatefulWidget {
  const ReservationCreateScreen({super.key, required this.vehicle, required this.period});

  final Vehicle vehicle;
  final RentalPeriod period;

  @override
  State<ReservationCreateScreen> createState() => _ReservationCreateScreenState();
}

class _ReservationCreateScreenState extends State<ReservationCreateScreen> {
  static const int _equipmentPageSize = 100;
  static const int _maxEquipmentQuantity = 20;
  static const int _bookingDaysAhead = 365;
  static const Duration _calculationDelay = Duration(milliseconds: 300);

  late RentalPeriod _period = widget.period;
  final Map<int, int> _quantities = {};

  List<Equipment> _equipment = [];
  bool _isLoadingEquipment = true;
  String? _equipmentError;

  ReservationCalculation? _calculation;
  String? _calculationError;
  bool _isCalculating = false;
  int _calculationId = 0;
  Timer? _calculationTimer;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadEquipment();
    _calculate();
  }

  @override
  void dispose() {
    _calculationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final today = DateUtils.dateOnly(DateTime.now());
    final pickupDate = DateUtils.dateOnly(_period.pickupAt);
    final vehicle = widget.vehicle;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          children: [
            const ScreenHeader(title: 'Rezervacija'),
            const SizedBox(height: 20),
            InfoCard(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  VehicleImage(vehicle: vehicle, width: 96, height: 72),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vehicle.name,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${vehicle.categoryName} · ${formatPricePerDay(vehicle.pricePerDay)}',
                          style: const TextStyle(fontSize: 15, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SectionTitle('Period najma'),
            DateTimeField(
              label: 'Preuzimanje',
              value: _period.pickupAt,
              firstDate: today,
              lastDate: DateTime(today.year, today.month, today.day + _bookingDaysAhead),
              onChanged: (value) => _changePeriod(_period.withPickup(value)),
            ),
            const SizedBox(height: 12),
            DateTimeField(
              label: 'Vraćanje',
              value: _period.returnAt,
              firstDate: pickupDate,
              lastDate: DateTime(pickupDate.year, pickupDate.month, pickupDate.day + RentalPeriod.maxRentalDays),
              onChanged: (value) => _changePeriod(_period.withReturn(value)),
            ),
            const SectionTitle('Dodatna oprema'),
            ..._buildEquipment(),
            const SectionTitle('Obračun'),
            _buildCalculation(),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _canSubmit ? _submit : null,
              child: _isSubmitting
                  ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                  : const Text('Nastavi na plaćanje'),
            ),
          ],
        ),
      ),
    );
  }

  bool get _canSubmit =>
      !_isSubmitting &&
      !_isCalculating &&
      _calculationTimer?.isActive != true &&
      _calculation != null &&
      _calculationError == null;

  List<Widget> _buildEquipment() {
    if (_isLoadingEquipment) {
      return const [Padding(padding: EdgeInsets.all(12), child: Center(child: CircularProgressIndicator()))];
    }

    final error = _equipmentError;
    if (error != null) {
      return [
        Text(error, style: const TextStyle(color: AppColors.textMuted, fontSize: 15)),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(onPressed: _loadEquipment, child: const Text('Pokušaj ponovo')),
        ),
      ];
    }

    if (_equipment.isEmpty) {
      return const [Text('Trenutno nema dodatne opreme.', style: TextStyle(color: AppColors.textMuted, fontSize: 15))];
    }

    return [
      for (final item in _equipment)
        _EquipmentRow(
          equipment: item,
          quantity: _quantities[item.id] ?? 0,
          maxQuantity: item.quantity < _maxEquipmentQuantity ? item.quantity : _maxEquipmentQuantity,
          onChanged: _isSubmitting ? null : (value) => _changeQuantity(item.id, value),
        ),
    ];
  }

  Widget _buildCalculation() {
    final periodError = _period.validate(DateTime.now());
    final error = periodError ?? _calculationError;
    if (error != null) {
      return NoticeBox(message: error, bottomSpacing: 0);
    }

    final calculation = _calculation;
    if (calculation == null) {
      return const Padding(padding: EdgeInsets.all(12), child: Center(child: CircularProgressIndicator()));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: 3, child: _isCalculating ? const LinearProgressIndicator() : null),
        AmountRow(
          label: 'Vozilo (${formatDays(calculation.rentalDays)} × ${formatMoney(calculation.vehiclePricePerDay)})',
          amount: calculation.vehiclePrice,
        ),
        AmountRow(label: 'Sezonski dodatak', amount: calculation.seasonalSurcharge),
        AmountRow(label: 'Dodatna oprema', amount: calculation.equipmentPrice),
        const Divider(height: 20, color: AppColors.border),
        AmountRow(label: 'Ukupno', amount: calculation.totalPrice, isTotal: true),
      ],
    );
  }

  Map<String, dynamic> _request() => ReservationProvider.createRequest(
        vehicleId: widget.vehicle.id,
        pickupAt: _period.pickupAt,
        returnAt: _period.returnAt,
        equipment: _quantities,
      );

  Future<void> _loadEquipment() async {
    setState(() {
      _isLoadingEquipment = true;
      _equipmentError = null;
    });

    try {
      final result = await context.read<EquipmentProvider>().get(filter: {'pageSize': _equipmentPageSize});
      if (!mounted) {
        return;
      }
      setState(() => _equipment = (result.items ?? []).where((x) => x.quantity > 0).toList());
    } on ApiClientException catch (e) {
      _showEquipmentError(e.message);
    } catch (_) {
      _showEquipmentError(unexpectedResponseError);
    } finally {
      if (mounted) {
        setState(() => _isLoadingEquipment = false);
      }
    }
  }

  void _showEquipmentError(String message) {
    if (mounted) {
      setState(() => _equipmentError = 'Dodatna oprema nije učitana. $message');
    }
  }

  void _changePeriod(RentalPeriod period) {
    setState(() => _period = period);
    _scheduleCalculation();
  }

  void _changeQuantity(int equipmentId, int quantity) {
    setState(() => _quantities[equipmentId] = quantity);
    _scheduleCalculation();
  }

  void _scheduleCalculation() {
    _calculationTimer?.cancel();
    _calculationTimer = Timer(_calculationDelay, _calculate);
    setState(() {});
  }

  Future<void> _calculate() async {
    final calculationId = ++_calculationId;
    if (_period.validate(DateTime.now()) != null) {
      setState(() {
        _calculation = null;
        _calculationError = null;
        _isCalculating = false;
      });
      return;
    }

    setState(() => _isCalculating = true);
    try {
      final calculation = await context.read<ReservationProvider>().calculate(_request());
      if (!mounted || calculationId != _calculationId) {
        return;
      }
      setState(() {
        _calculation = calculation;
        _calculationError = null;
      });
    } on ApiClientException catch (e) {
      _showCalculationError(calculationId, e.message);
    } catch (_) {
      _showCalculationError(calculationId, unexpectedResponseError);
    } finally {
      if (mounted && calculationId == _calculationId) {
        setState(() => _isCalculating = false);
      }
    }
  }

  void _showCalculationError(int calculationId, String message) {
    if (!mounted || calculationId != _calculationId) {
      return;
    }
    setState(() {
      _calculation = null;
      _calculationError = message;
    });
  }

  Future<void> _submit() async {
    if (_period.validate(DateTime.now()) != null) {
      setState(() {});
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final reservation = await context.read<ReservationProvider>().insert(_request());
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ReservationPaymentScreen(reservation: reservation)),
      );
    } on ApiClientException catch (e) {
      if (mounted) {
        setState(() {
          _calculation = null;
          _calculationError = e.message;
        });
      }
    } catch (_) {
      if (mounted) {
        showSnack(context, unexpectedResponseError);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}

class _EquipmentRow extends StatelessWidget {
  const _EquipmentRow({
    required this.equipment,
    required this.quantity,
    required this.maxQuantity,
    required this.onChanged,
  });

  final Equipment equipment;
  final int quantity;
  final int maxQuantity;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    final change = onChanged;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(equipment.name, style: const TextStyle(fontSize: 16, color: AppColors.textDark)),
                const SizedBox(height: 2),
                Text(
                  formatPricePerDay(equipment.pricePerDay),
                  style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          _StepButton(
            icon: Icons.remove,
            tooltip: 'Smanji: ${equipment.name}',
            onPressed: change != null && quantity > 0 ? () => change(quantity - 1) : null,
          ),
          SizedBox(
            width: 40,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textDark),
            ),
          ),
          _StepButton(
            icon: Icons.add,
            tooltip: 'Povećaj: ${equipment.name}',
            onPressed: change != null && quantity < maxQuantity ? () => change(quantity + 1) : null,
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.tooltip, required this.onPressed});

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 44,
      child: IconButton.outlined(
        tooltip: tooltip,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: Icon(icon, color: onPressed == null ? AppColors.imagePlaceholderIcon : AppColors.textDark),
      ),
    );
  }
}
