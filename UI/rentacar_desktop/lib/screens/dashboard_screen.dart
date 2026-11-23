import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../layouts/master_screen.dart';
import '../models/dashboard.dart';
import '../providers/dashboard_provider.dart';
import '../utils/api_client_exception.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  static const String title = 'Dashboard';

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Dashboard? _dashboard;
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
      final dashboard = await context.read<DashboardProvider>().get();
      if (mounted) {
        setState(() {
          _dashboard = dashboard;
          _isLoading = false;
        });
      }
    } on UnauthorizedException catch (_) {
    } on ApiClientException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MasterScreen(title: DashboardScreen.title, child: _buildBody());
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.error)),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _load, child: const Text('Pokušaj ponovo')),
          ],
        ),
      );
    }

    final dashboard = _dashboard!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(64, 48, 64, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _StatCard(icon: Icons.directions_car_outlined, label: 'Ukupno vozila', value: dashboard.vehicleCount),
              const SizedBox(width: 32),
              _StatCard(icon: Icons.people_outline, label: 'Ukupno korisnika', value: dashboard.customerCount),
              const SizedBox(width: 32),
              _StatCard(
                icon: Icons.calendar_month_outlined,
                label: 'Aktivne rezervacije',
                value: dashboard.activeReservationCount,
              ),
              const SizedBox(width: 32),
              _StatCard(
                icon: Icons.hourglass_empty,
                label: 'Rezervacije na čekanju',
                value: dashboard.awaitingConfirmationCount,
                tooltip: 'Plaćene rezervacije koje čekaju potvrdu administratora',
              ),
            ],
          ),
          const SizedBox(height: 48),
          const Text(
            'Rezervacije po danima – zadnjih 7 dana',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textDark),
          ),
          const SizedBox(height: 32),
          Expanded(child: _ReservationsChart(days: dashboard.reservationsPerDay)),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.icon, required this.label, required this.value, this.tooltip});

  final IconData icon;
  final String label;
  final int value;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, size: 44, color: AppColors.primary),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(fontSize: 18, color: AppColors.textMuted)),
          const SizedBox(height: 8),
          Text(
            '$value',
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.textDark),
          ),
        ],
      ),
    );
    return Expanded(child: tooltip == null ? card : Tooltip(message: tooltip, child: card));
  }
}

class _ReservationsChart extends StatelessWidget {
  const _ReservationsChart({required this.days});

  final List<DailyReservationCount> days;

  @override
  Widget build(BuildContext context) {
    final maxCount = days.fold<int>(0, (current, day) => max(current, day.count));
    final interval = _gridInterval(maxCount);
    final maxY = max(interval * 4, ((maxCount * 1.15) / interval).ceil() * interval).toDouble();

    return BarChart(
      BarChartData(
        maxY: maxY,
        alignment: BarChartAlignment.spaceAround,
        borderData: FlBorderData(
          show: true,
          border: const Border(bottom: BorderSide(color: AppColors.border)),
        ),
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: interval.toDouble(),
          getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.border, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 48,
              interval: interval.toDouble(),
              getTitlesWidget: (value, meta) => SideTitleWidget(
                meta: meta,
                child: Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 16, color: AppColors.textMuted),
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 56,
              getTitlesWidget: (value, meta) {
                final day = days[value.toInt()];
                return SideTitleWidget(
                  meta: meta,
                  child: Column(
                    children: [
                      Text(formatWeekday(day.date), style: const TextStyle(fontSize: 16, color: AppColors.textMuted)),
                      Text(
                        formatDate(day.date).substring(0, 6),
                        style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => AppColors.textDark,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final day = days[group.x];
              final count = day.count;
              return BarTooltipItem(
                '${formatDate(day.date)}\n$count ${pluralBs(count, 'rezervacija', 'rezervacije', 'rezervacija')}',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              );
            },
          ),
        ),
        barGroups: [
          for (var i = 0; i < days.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: days[i].count.toDouble(),
                  color: AppColors.primary,
                  width: 72,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                ),
              ],
            ),
        ],
      ),
    );
  }

  static int _gridInterval(int maxCount) {
    if (maxCount <= 4) {
      return 1;
    }
    final rough = maxCount / 4;
    final magnitude = pow(10, (log(rough) / ln10).floor()).toInt();
    for (final step in [1, 2, 3, 5, 10]) {
      if (step * magnitude >= rough) {
        return step * magnitude;
      }
    }
    return 10 * magnitude;
  }
}
