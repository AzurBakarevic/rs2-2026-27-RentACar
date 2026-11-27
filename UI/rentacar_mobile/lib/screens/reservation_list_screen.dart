import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models/reservation.dart';
import '../providers/reservation_provider.dart';
import '../utils/api_client_exception.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/utils_widgets.dart';
import '../widgets/reservation_widgets.dart';
import 'reservation_details_screen.dart';

enum ReservationListFilter {
  all('Sve', null, 'Nemate nijednu rezervaciju.'),
  active('Aktivne', true, 'Nemate aktivnih rezervacija.'),
  past('Prošle', false, 'Nemate prošlih rezervacija.');

  const ReservationListFilter(this.label, this.isActive, this.emptyMessage);

  final String label;
  final bool? isActive;
  final String emptyMessage;
}

class ReservationListScreen extends StatefulWidget {
  const ReservationListScreen({super.key});

  static const String title = 'Rezervacije';

  @override
  State<ReservationListScreen> createState() => _ReservationListScreenState();
}

class _ReservationListScreenState extends State<ReservationListScreen> {
  static const int _pageSize = 20;
  static const double _loadMoreOffset = 300;

  final ScrollController _scrollController = ScrollController();
  late final ReservationProvider _provider;

  ReservationListFilter _filter = ReservationListFilter.all;
  List<Reservation> _reservations = [];
  int _totalCount = 0;
  int _page = 0;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _loadMoreFailed = false;
  String? _error;
  int _requestId = 0;

  bool get _hasMore => _reservations.length < _totalCount;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _provider = context.read<ReservationProvider>()..addListener(_load);
    _load();
  }

  @override
  void dispose() {
    _provider.removeListener(_load);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: Text(
                'Moje rezervacije',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textDark),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Wrap(
                spacing: 12,
                children: [
                  for (final filter in ReservationListFilter.values)
                    ChoiceChip(
                      label: Text(filter.label),
                      selected: _filter == filter,
                      onSelected: (_) => _selectFilter(filter),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 3,
              child: _isLoading && _reservations.isNotEmpty ? const LinearProgressIndicator() : null,
            ),
            Expanded(child: RefreshIndicator(onRefresh: _load, child: _buildResults())),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    final error = _error;
    if (error != null && _reservations.isEmpty) {
      return _buildMessageList([
        Text(error, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted, fontSize: 16)),
        const SizedBox(height: 12),
        Center(child: OutlinedButton(onPressed: _load, child: const Text('Pokušaj ponovo'))),
      ]);
    }

    if (_reservations.isEmpty) {
      if (_isLoading) {
        return _buildMessageList([const Center(child: CircularProgressIndicator())]);
      }
      return _buildMessageList([
        Text(
          _filter.emptyMessage,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 16),
        ),
      ]);
    }

    return ListView.separated(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      itemCount: _reservations.length + (_hasMore ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        if (index == _reservations.length) {
          return _buildFooter();
        }
        final reservation = _reservations[index];
        return _ReservationCard(reservation: reservation, onTap: () => _openDetails(reservation));
      },
    );
  }

  Widget _buildFooter() {
    if (_loadMoreFailed) {
      return Center(child: TextButton(onPressed: _loadMore, child: const Text('Učitaj još rezervacija')));
    }
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildMessageList(List<Widget> children) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      children: children,
    );
  }

  Map<String, dynamic> _buildFilter(int page) {
    return {'isActive': _filter.isActive, 'page': page, 'pageSize': _pageSize, 'includeTotalCount': true};
  }

  Future<void> _load() async {
    final requestId = ++_requestId;
    setState(() {
      _error = null;
      _isLoading = true;
      _isLoadingMore = false;
      _loadMoreFailed = false;
    });

    try {
      final result = await _provider.get(filter: _buildFilter(1));
      if (!mounted || requestId != _requestId) {
        return;
      }
      setState(() {
        _reservations = result.items ?? [];
        _totalCount = result.totalCount ?? _reservations.length;
        _page = 1;
      });
    } on ApiClientException catch (e) {
      _showLoadError(requestId, e.message);
    } catch (_) {
      _showLoadError(requestId, unexpectedResponseError);
    } finally {
      if (mounted && requestId == _requestId) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showLoadError(int requestId, String message) {
    if (!mounted || requestId != _requestId) {
      return;
    }
    setState(() {
      _reservations = [];
      _totalCount = 0;
      _page = 0;
      _error = message;
    });
  }

  Future<void> _loadMore() async {
    if (_isLoading || _isLoadingMore || !_hasMore) {
      return;
    }

    final requestId = _requestId;
    setState(() {
      _isLoadingMore = true;
      _loadMoreFailed = false;
    });

    try {
      final result = await _provider.get(filter: _buildFilter(_page + 1));
      if (!mounted || requestId != _requestId) {
        return;
      }
      setState(() {
        _reservations = [..._reservations, ...?result.items];
        _totalCount = result.totalCount ?? _totalCount;
        _page++;
      });
    } on ApiClientException catch (e) {
      _showLoadMoreError(requestId, e.message);
    } catch (_) {
      _showLoadMoreError(requestId, unexpectedResponseError);
    } finally {
      if (mounted && requestId == _requestId) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  void _showLoadMoreError(int requestId, String message) {
    if (!mounted || requestId != _requestId) {
      return;
    }
    setState(() => _loadMoreFailed = true);
    showSnack(context, message);
  }

  void _onScroll() {
    if (_loadMoreFailed || !_scrollController.hasClients) {
      return;
    }
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - _loadMoreOffset) {
      _loadMore();
    }
  }

  void _selectFilter(ReservationListFilter filter) {
    if (filter == _filter) {
      return;
    }
    setState(() {
      _filter = filter;
      _reservations = [];
      _totalCount = 0;
    });
    _load();
  }

  void _openDetails(Reservation reservation) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReservationDetailsScreen(reservationId: reservation.id, initial: reservation),
      ),
    );
  }
}

class _ReservationCard extends StatelessWidget {
  const _ReservationCard({required this.reservation, required this.onTap});

  final Reservation reservation;
  final VoidCallback onTap;

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
          padding: const EdgeInsets.all(12),
          child: Row(
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
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ReservationStatusBadge(reservation.status),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      formatDateRange(reservation.pickupAt, reservation.returnAt),
                      style: const TextStyle(fontSize: 15, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      formatMoney(reservation.totalPrice),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
