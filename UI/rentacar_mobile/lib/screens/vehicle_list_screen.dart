import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models/named_entity.dart';
import '../models/search_result.dart';
import '../models/vehicle.dart';
import '../providers/category_provider.dart';
import '../providers/fuel_type_provider.dart';
import '../providers/reservation_provider.dart';
import '../providers/transmission_type_provider.dart';
import '../providers/vehicle_provider.dart';
import '../utils/api_client_exception.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/rental_period.dart';
import '../utils/utils_widgets.dart';
import '../widgets/date_time_field.dart';
import '../widgets/notice_box.dart';
import '../widgets/vehicle_filter_sheet.dart';
import '../widgets/vehicle_widgets.dart';
import 'vehicle_details_screen.dart';

class VehicleListScreen extends StatefulWidget {
  const VehicleListScreen({super.key});

  static const String title = 'Vozila';

  @override
  State<VehicleListScreen> createState() => _VehicleListScreenState();
}

class _VehicleListScreenState extends State<VehicleListScreen> {
  static const int _pageSize = 20;
  static const int _lookupPageSize = 100;
  static const int _bookingDaysAhead = 365;
  static const Duration _searchDelay = Duration(milliseconds: 400);
  static const double _loadMoreOffset = 300;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchTimer;

  RentalPeriod _period = RentalPeriod.initial(DateTime.now());
  int? _categoryId;
  VehicleFilter _filter = const VehicleFilter();

  List<NamedEntity> _categories = [];
  List<NamedEntity> _fuelTypes = [];
  List<NamedEntity> _transmissionTypes = [];
  bool _lookupsLoaded = false;
  String? _lookupsError;

  List<Vehicle> _vehicles = [];
  int _totalCount = 0;
  int _page = 0;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _loadMoreFailed = false;
  String? _error;
  String? _periodError;
  int _requestId = 0;
  late final ReservationProvider _reservationProvider;

  bool get _hasMore => _vehicles.length < _totalCount;

  bool get _hasSearchOrFilters =>
      _searchController.text.trim().isNotEmpty || _categoryId != null || _filter.activeCount > 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _reservationProvider = context.read<ReservationProvider>()..addListener(_loadVehicles);
    _refresh();
  }

  @override
  void dispose() {
    _reservationProvider.removeListener(_loadVehicles);
    _searchTimer?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final today = DateUtils.dateOnly(DateTime.now());
    final pickupDate = DateUtils.dateOnly(_period.pickupAt);
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: DateTimeField(
                          label: 'Preuzimanje',
                          value: _period.pickupAt,
                          firstDate: today,
                          lastDate: DateTime(today.year, today.month, today.day + _bookingDaysAhead),
                          onChanged: (value) => _changePeriod(_period.withPickup(value)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DateTimeField(
                          label: 'Vraćanje',
                          value: _period.returnAt,
                          firstDate: pickupDate,
                          lastDate: DateTime(pickupDate.year, pickupDate.month, pickupDate.day + RentalPeriod.maxRentalDays),
                          onChanged: (value) => _changePeriod(_period.withReturn(value)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildSearchField()),
                      const SizedBox(width: 12),
                      _buildFilterButton(),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (_lookupsError != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: NoticeBox(message: _lookupsError, bottomSpacing: 12),
              ),
            if (_categories.isNotEmpty) _buildCategoryChips(),
            SizedBox(
              height: 3,
              child: _isLoading && _vehicles.isNotEmpty ? const LinearProgressIndicator() : null,
            ),
            Expanded(
              child: RefreshIndicator(onRefresh: _refresh, child: _buildResults()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      textInputAction: TextInputAction.search,
      onChanged: _onSearchChanged,
      onSubmitted: (_) => _searchNow(),
      decoration: InputDecoration(
        hintText: 'Pretraži vozila...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchController.text.isEmpty
            ? null
            : IconButton(tooltip: 'Obriši pretragu', icon: const Icon(Icons.close), onPressed: _clearSearch),
      ),
    );
  }

  Widget _buildFilterButton() {
    final count = _filter.activeCount;
    return Badge(
      isLabelVisible: count > 0,
      label: Text('$count'),
      backgroundColor: AppColors.primary,
      child: SizedBox.square(
        dimension: 56,
        child: IconButton.outlined(
          tooltip: 'Filteri',
          onPressed: _lookupsLoaded ? _openFilters : null,
          style: IconButton.styleFrom(
            side: BorderSide(color: count > 0 ? AppColors.primary : AppColors.border),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: Icon(Icons.filter_alt_outlined, color: count > 0 ? AppColors.primary : AppColors.textDark),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: _categories.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = index == 0 ? null : _categories[index - 1];
          return Center(
            child: ChoiceChip(
              label: Text(category?.name ?? 'Sve'),
              selected: _categoryId == category?.id,
              onSelected: (_) => _selectCategory(category?.id),
            ),
          );
        },
      ),
    );
  }

  Widget _buildResults() {
    final periodError = _periodError;
    if (periodError != null) {
      return _buildMessageList([NoticeBox(message: periodError, bottomSpacing: 0)]);
    }

    final error = _error;
    if (error != null && _vehicles.isEmpty) {
      return _buildMessageList([
        Text(error, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted, fontSize: 16)),
        const SizedBox(height: 12),
        Center(child: OutlinedButton(onPressed: _loadVehicles, child: const Text('Pokušaj ponovo'))),
      ]);
    }

    if (_vehicles.isEmpty) {
      if (_isLoading) {
        return _buildMessageList([const Center(child: CircularProgressIndicator())]);
      }
      return _buildMessageList([
        Text(
          _hasSearchOrFilters
              ? 'Nema slobodnih vozila koja odgovaraju pretrazi i filterima u odabranom periodu.'
              : 'Nema slobodnih vozila u odabranom periodu.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 16),
        ),
      ]);
    }

    final showFooter = _hasMore;
    return ListView.separated(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      itemCount: _vehicles.length + (showFooter ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        if (index == _vehicles.length) {
          return _buildFooter();
        }
        final vehicle = _vehicles[index];
        return _VehicleCard(vehicle: vehicle, onTap: () => _openDetails(vehicle));
      },
    );
  }

  Widget _buildFooter() {
    if (_loadMoreFailed) {
      return Center(child: TextButton(onPressed: _loadMore, child: const Text('Učitaj još vozila')));
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

  Future<void> _refresh() async {
    await Future.wait([
      if (!_lookupsLoaded) _loadLookups(),
      _loadVehicles(),
    ]);
  }

  Future<void> _loadLookups() async {
    const filter = {'pageSize': _lookupPageSize};
    try {
      final results = await Future.wait<SearchResult<NamedEntity>>([
        context.read<CategoryProvider>().get(filter: filter),
        context.read<FuelTypeProvider>().get(filter: filter),
        context.read<TransmissionTypeProvider>().get(filter: filter),
      ]);
      if (!mounted) {
        return;
      }
      setState(() {
        _categories = results[0].items ?? [];
        _fuelTypes = results[1].items ?? [];
        _transmissionTypes = results[2].items ?? [];
        _lookupsLoaded = true;
        _lookupsError = null;
      });
    } on ApiClientException catch (e) {
      if (mounted) {
        setState(() => _lookupsError = 'Filteri nisu učitani. ${e.message}');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _lookupsError = 'Filteri nisu učitani. $unexpectedResponseError');
      }
    }
  }

  Future<void> _loadVehicles() async {
    final requestId = ++_requestId;
    final periodError = _period.validate(DateTime.now());
    if (periodError != null) {
      setState(() {
        _periodError = periodError;
        _vehicles = [];
        _totalCount = 0;
        _page = 0;
        _error = null;
        _isLoading = false;
        _isLoadingMore = false;
      });
      return;
    }

    setState(() {
      _periodError = null;
      _error = null;
      _isLoading = true;
      _isLoadingMore = false;
      _loadMoreFailed = false;
    });

    try {
      final result = await context.read<VehicleProvider>().get(filter: _buildFilter(1));
      if (!mounted || requestId != _requestId) {
        return;
      }
      setState(() {
        _vehicles = result.items ?? [];
        _totalCount = result.totalCount ?? _vehicles.length;
        _page = 1;
      });
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
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
      _vehicles = [];
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
      final result = await context.read<VehicleProvider>().get(filter: _buildFilter(_page + 1));
      if (!mounted || requestId != _requestId) {
        return;
      }
      setState(() {
        _vehicles = [..._vehicles, ...?result.items];
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

  Map<String, dynamic> _buildFilter(int page) {
    return {
      'availableFrom': _period.pickupAt,
      'availableTo': _period.returnAt,
      'text': _searchController.text,
      'categoryId': _categoryId,
      'fuelTypeId': _filter.fuelTypeId,
      'transmissionTypeId': _filter.transmissionTypeId,
      'minPricePerDay': _filter.minPrice,
      'maxPricePerDay': _filter.maxPrice,
      'page': page,
      'pageSize': _pageSize,
      'includeTotalCount': true,
    };
  }

  void _changePeriod(RentalPeriod period) {
    setState(() => _period = period);
    _loadVehicles();
  }

  void _selectCategory(int? categoryId) {
    if (categoryId == _categoryId) {
      return;
    }
    setState(() => _categoryId = categoryId);
    _loadVehicles();
  }

  void _onSearchChanged(String _) {
    _searchTimer?.cancel();
    _searchTimer = Timer(_searchDelay, _loadVehicles);
    setState(() {});
  }

  void _searchNow() {
    _searchTimer?.cancel();
    _loadVehicles();
  }

  void _clearSearch() {
    _searchController.clear();
    _searchNow();
  }

  Future<void> _openFilters() async {
    final result = await showModalBottomSheet<VehicleFilter>(
      context: context,
      isScrollControlled: true,
      builder: (_) => VehicleFilterSheet(
        initial: _filter,
        fuelTypes: _fuelTypes,
        transmissionTypes: _transmissionTypes,
      ),
    );
    if (result == null || !mounted) {
      return;
    }
    setState(() => _filter = result);
    _loadVehicles();
  }

  void _openDetails(Vehicle vehicle) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => VehicleDetailsScreen(vehicle: vehicle, period: _period)));
  }
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({required this.vehicle, required this.onTap});

  final Vehicle vehicle;
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
              VehicleImage(vehicle: vehicle, width: 104, height: 84),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textDark),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        CategoryBadge(vehicle.categoryName),
                        Text(
                          formatPricePerDay(vehicle.pricePerDay),
                          style: const TextStyle(fontSize: 16, color: AppColors.textDark),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${vehicle.fuelTypeName} · ${vehicle.transmissionTypeName}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
                          ),
                        ),
                        const SizedBox(width: 8),
                        AverageRating(rating: vehicle.averageRating),
                      ],
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
