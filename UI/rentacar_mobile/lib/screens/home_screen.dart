import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../layouts/master_screen.dart';
import '../models/recommendation.dart';
import '../models/reservation.dart';
import '../models/search_result.dart';
import '../providers/notification_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/recommendation_provider.dart';
import '../providers/reservation_provider.dart';
import '../utils/api_client_exception.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/utils_widgets.dart';
import '../widgets/notice_box.dart';
import '../widgets/recommendation_card.dart';
import 'notification_list_screen.dart';
import 'recommendation_list_screen.dart';
import 'reservation_details_screen.dart';
import 'reservation_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const String title = 'Početna';
  static const int recommendationPreviewCount = 2;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final ReservationProvider _reservations;

  int? _activeCount;
  Reservation? _nextPickup;
  List<Recommendation> _recommendations = [];
  bool _isLoading = true;
  String? _error;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _reservations = context.read<ReservationProvider>()..addListener(_load);
    _load();
  }

  @override
  void dispose() {
    _reservations.removeListener(_load);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firstName = context.watch<ProfileProvider>().profile?.firstName;
    final unreadCount = context.watch<NotificationProvider>().unreadCount;
    final preview = _recommendations.take(HomeScreen.recommendationPreviewCount).toList();
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  tooltip: NotificationListScreen.title,
                  onPressed: () => MasterScreen.openTab(context, NotificationListScreen.title),
                  icon: Badge.count(
                    count: unreadCount,
                    isLabelVisible: unreadCount > 0,
                    backgroundColor: AppColors.error,
                    child: const Icon(Icons.notifications_outlined, size: 30, color: AppColors.textDark),
                  ),
                ),
              ),
              Text(
                firstName == null ? 'Zdravo!' : 'Zdravo, $firstName!',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textDark),
              ),
              const SizedBox(height: 8),
              const Text(
                'Spremni za sljedeće putovanje?',
                style: TextStyle(fontSize: 17, color: AppColors.textMuted),
              ),
              const _SectionHeader('Pregled'),
              if (_error != null) ...[
                NoticeBox(message: _error, bottomSpacing: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(onPressed: _load, child: const Text('Pokušaj ponovo')),
                ),
                const SizedBox(height: 8),
              ],
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: _buildActiveCard()),
                    const SizedBox(width: 16),
                    Expanded(child: _buildNextPickupCard()),
                  ],
                ),
              ),
              _SectionHeader(
                'Preporučena vozila',
                trailing: _recommendations.length > HomeScreen.recommendationPreviewCount
                    ? TextButton(onPressed: _openRecommendations, child: const Text('Pogledaj sve'))
                    : null,
              ),
              if (preview.isEmpty)
                Text(
                  _isLoading ? 'Učitavanje preporuka...' : emptyRecommendationsMessage,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 16),
                )
              else
                for (final recommendation in preview)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: RecommendationCard(
                      recommendation: recommendation,
                      onTap: () => openRecommendedVehicle(context, recommendation),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveCard() {
    final count = _activeCount;
    return _StatCard(
      label: 'Aktivne rezervacije',
      onTap: () => MasterScreen.openTab(context, ReservationListScreen.title),
      child: Text(
        count == null ? '–' : '$count',
        style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: AppColors.primary),
      ),
    );
  }

  Widget _buildNextPickupCard() {
    final reservation = _nextPickup;
    if (reservation == null) {
      return _StatCard(
        label: 'Sljedeće preuzimanje',
        child: Text(
          _activeCount == null ? '–' : 'Nema zakazanih preuzimanja.',
          style: const TextStyle(fontSize: 15, color: AppColors.textMuted),
        ),
      );
    }
    return _StatCard(
      label: 'Sljedeće preuzimanje',
      onTap: () => _openReservation(reservation),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            reservation.vehicleName,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textDark),
          ),
          const SizedBox(height: 6),
          Text(formatDateTime(reservation.pickupAt), style: const TextStyle(fontSize: 15, color: AppColors.textDark)),
        ],
      ),
    );
  }

  Future<void> _refresh() async {
    context.read<NotificationProvider>().refresh();
    await _load();
  }

  Future<void> _load() async {
    final requestId = ++_requestId;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final recommendationProvider = context.read<RecommendationProvider>();
    try {
      final activeFuture = _reservations.get(filter: {'isActive': true, 'pageSize': 1, 'includeTotalCount': true});
      final upcomingFuture = _reservations.get(filter: {'isActive': true, 'isUpcoming': true, 'pageSize': 1});
      final recommendationsFuture = recommendationProvider.getRecommendations();
      await Future.wait<Object>([activeFuture, upcomingFuture, recommendationsFuture]);

      final SearchResult<Reservation> active = await activeFuture;
      final SearchResult<Reservation> upcoming = await upcomingFuture;
      final recommendations = await recommendationsFuture;
      if (!mounted || requestId != _requestId) {
        return;
      }
      setState(() {
        _activeCount = active.totalCount ?? active.items?.length ?? 0;
        _nextPickup = upcoming.items?.firstOrNull;
        _recommendations = recommendations;
      });
    } on UnauthorizedException catch (_) {
      return;
    } on ApiClientException catch (e) {
      _showError(requestId, e.message);
    } catch (_) {
      _showError(requestId, unexpectedResponseError);
    } finally {
      if (mounted && requestId == _requestId) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(int requestId, String message) {
    if (mounted && requestId == _requestId) {
      setState(() => _error = message);
    }
  }

  void _openReservation(Reservation reservation) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReservationDetailsScreen(reservationId: reservation.id, initial: reservation),
      ),
    );
  }

  void _openRecommendations() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RecommendationListScreen(initial: _recommendations)),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text, {this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final trailingWidget = trailing;
    return Padding(
      padding: EdgeInsets.only(top: 24, bottom: trailingWidget == null ? 12 : 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark),
            ),
          ),
          ?trailingWidget,
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.child, this.onTap});

  final String label;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 15, color: AppColors.textMuted)),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
