import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../layouts/master_screen.dart';
import '../models/reservation.dart';
import '../models/user.dart';
import '../providers/reservation_provider.dart';
import '../providers/vehicle_provider.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/paged_list_controller.dart';
import '../utils/utils_widgets.dart';
import '../widgets/data_table_card.dart';
import '../widgets/date_filter_field.dart';
import '../widgets/paged_table_layout.dart';
import '../widgets/pagination_bar.dart';
import '../widgets/reservation_action_button.dart';
import '../widgets/reservation_status_badge.dart';
import '../widgets/search_toolbar.dart';
import '../widgets/user_avatar.dart';
import 'reservation_action_dialog.dart';
import 'reservation_details_screen.dart';
import 'user_list_screen.dart';
import 'vehicle_list_screen.dart';

class ReservationListScreen extends StatefulWidget {
  const ReservationListScreen({super.key, this.activeOfUser});

  static const String title = 'Rezervacije';

  final User? activeOfUser;

  @override
  State<ReservationListScreen> createState() => _ReservationListScreenState();
}

class _ReservationListScreenState extends State<ReservationListScreen> {
  static const List<TableColumnDef> _columns = [
    TableColumnDef('Korisnik', flex: 140),
    TableColumnDef('Vozilo', flex: 160),
    TableColumnDef('Preuzimanje', flex: 114),
    TableColumnDef('Vraćanje', flex: 92),
    TableColumnDef('Iznos', flex: 100),
    TableColumnDef('Status', flex: 118),
    TableColumnDef('Akcije', flex: 196),
  ];

  late final PagedListController<Reservation> _controller =
      PagedListController<Reservation>(context.read<ReservationProvider>());
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _searchDebounce;
  DateTime? _date;
  ReservationStatus? _status;

  @override
  void initState() {
    super.initState();
    _controller.search(_buildFilter());
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildFilter() {
    final date = _date;
    final user = widget.activeOfUser;
    return {
      if (user != null) ...{'userId': user.id, 'isActive': true},
      'text': _searchController.text.trim(),
      'status': _status?.apiValue,
      if (date != null) ...{'from': date, 'to': DateTime(date.year, date.month, date.day + 1)},
    };
  }

  bool get _isFiltered => _searchController.text.trim().isNotEmpty || _date != null || _status != null;

  @override
  Widget build(BuildContext context) {
    final vehicleProvider = context.read<VehicleProvider>();
    final user = widget.activeOfUser;
    return MasterScreen(
      title: user == null ? ReservationListScreen.title : 'Aktivne rezervacije: ${user.fullName}',
      menuLabel: user == null ? ReservationListScreen.title : UserListScreen.title,
      child: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) => PagedTableLayout(
          toolbar: SearchToolbar(
            controller: _searchController,
            hintText: 'po korisniku ili vozilu',
            onChanged: _onSearchChanged,
            filters: [
              DateFilterField(value: _date, onChanged: _onDateChanged),
              _StatusFilter(
                value: _status,
                statuses: user == null
                    ? ReservationStatus.values
                    : ReservationStatus.values.where((status) => !status.isFinal).toList(),
                onChanged: _onStatusChanged,
              ),
            ],
          ),
          table: DataTableCard(
            scrollController: _scrollController,
            columns: _columns,
            rows: [for (final item in _controller.items) _buildCells(item, vehicleProvider)],
            isLoading: _controller.isLoading,
            error: _controller.error,
            onRetry: _controller.load,
            emptyText: _isFiltered
                ? 'Nema rezervacija koje odgovaraju pretrazi.'
                : user == null
                    ? 'Nema rezervacija.'
                    : 'Korisnik nema aktivnih rezervacija.',
          ),
          pagination: PaginationBar(
            page: _controller.page,
            pageCount: _controller.pageCount,
            onPageChanged: _goToPage,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCells(Reservation item, VehicleProvider vehicleProvider) {
    return [
      _ImageTextCell(
        image: UserAvatar(userId: item.userId, hasImage: item.userHasImage),
        text: item.userFullName,
      ),
      _ImageTextCell(
        image: VehicleImage(
          vehicleId: item.vehicleId,
          hasImage: item.vehicleHasImage,
          provider: vehicleProvider,
          width: 48,
          height: 32,
        ),
        text: item.vehicleName,
        details: item.vehicleRegistrationNumber,
      ),
      _DateTimeCell(item.pickupAt),
      _DateTimeCell(item.returnAt),
      _AmountCell(item),
      ReservationStatusBadge(item.status),
      Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final action in item.actions)
            ReservationActionButton(reservation: item, action: action, onPressed: () => _perform(item, action)),
          IconButton(
            tooltip: 'Detalji',
            icon: const Icon(Icons.visibility_outlined),
            color: AppColors.textDark,
            style: IconButton.styleFrom(
              fixedSize: const Size(40, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: AppColors.border),
              ),
            ),
            onPressed: () => _openDetails(item),
          ),
        ],
      ),
    ];
  }

  void _onSearchChanged(String text) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), _search);
  }

  void _onDateChanged(DateTime? value) {
    setState(() => _date = value);
    _search();
  }

  void _onStatusChanged(ReservationStatus? value) {
    setState(() => _status = value);
    _search();
  }

  void _search() {
    _searchDebounce?.cancel();
    _scrollToTop();
    _controller.search(_buildFilter());
  }

  void _goToPage(int page) {
    _scrollToTop();
    _controller.goToPage(page);
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  Future<void> _perform(Reservation item, ReservationAction action) async {
    final done = await showReservationActionDialog(context, item, action);
    if (!mounted) {
      return;
    }
    if (done) {
      showSnack(context, reservationActionDone(action));
    }
    _controller.load();
  }

  Future<void> _openDetails(Reservation item) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => ReservationDetailsScreen(reservationId: item.id)),
    );
    if (mounted) {
      _controller.load();
    }
  }
}

class _StatusFilter extends StatelessWidget {
  const _StatusFilter({required this.value, required this.statuses, required this.onChanged});

  final ReservationStatus? value;
  final List<ReservationStatus> statuses;
  final ValueChanged<ReservationStatus?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: DropdownButtonFormField<ReservationStatus?>(
        initialValue: value,
        isExpanded: true,
        style: Theme.of(context).textTheme.bodyLarge,
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
        items: [
          const DropdownMenuItem<ReservationStatus?>(value: null, child: Text('Svi statusi')),
          for (final status in statuses)
            DropdownMenuItem<ReservationStatus?>(value: status, child: Text(status.label)),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

class _ImageTextCell extends StatelessWidget {
  const _ImageTextCell({required this.image, required this.text, this.details});

  final Widget image;
  final String text;
  final String? details;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Row(
        children: [
          image,
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Tooltip(
                  message: text,
                  child: Text(
                    text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.start,
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
                if (details != null)
                  Text(
                    details!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DateTimeCell extends StatelessWidget {
  const _DateTimeCell(this.value);

  final DateTime value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(formatDate(value), style: const TextStyle(fontSize: 15)),
        Text(formatTime(value), style: const TextStyle(fontSize: 14, color: AppColors.textMuted)),
      ],
    );
  }
}

class _AmountCell extends StatelessWidget {
  const _AmountCell(this.reservation);

  final Reservation reservation;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(formatMoney(reservation.totalPrice), style: const TextStyle(fontSize: 15)),
        if (reservation.isPaid)
          const Text(
            'Plaćeno',
            style: TextStyle(fontSize: 13, color: AppColors.success, fontWeight: FontWeight.w600),
          )
        else if (reservation.status == ReservationStatus.pending)
          const Text('Nije plaćeno', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
      ],
    );
  }
}
