import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../layouts/master_screen.dart';
import '../models/review.dart';
import '../providers/review_provider.dart';
import '../providers/vehicle_provider.dart';
import '../utils/api_client_exception.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/paged_list_controller.dart';
import '../utils/utils_widgets.dart';
import '../widgets/data_table_card.dart';
import '../widgets/image_text_cell.dart';
import '../widgets/paged_table_layout.dart';
import '../widgets/pagination_bar.dart';
import '../widgets/search_toolbar.dart';
import '../widgets/table_action_buttons.dart';
import '../widgets/user_avatar.dart';
import 'vehicle_list_screen.dart';

class ReviewListScreen extends StatefulWidget {
  const ReviewListScreen({super.key});

  static const String title = 'Recenzije';

  @override
  State<ReviewListScreen> createState() => _ReviewListScreenState();
}

class _ReviewListScreenState extends State<ReviewListScreen> {
  static const List<TableColumnDef> _columns = [
    TableColumnDef('Korisnik', flex: 150),
    TableColumnDef('Vozilo', flex: 170),
    TableColumnDef('Ocjena', flex: 120),
    TableColumnDef('Komentar', flex: 300),
    TableColumnDef('Datum', flex: 100),
    TableColumnDef('Akcije', flex: 80),
  ];

  late final ReviewProvider _provider = context.read<ReviewProvider>();
  late final PagedListController<Review> _controller = PagedListController<Review>(_provider);
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _searchDebounce;

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

  Map<String, dynamic> _buildFilter() => {'text': _searchController.text.trim()};

  bool get _isFiltered => _searchController.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final vehicleProvider = context.read<VehicleProvider>();
    return MasterScreen(
      title: ReviewListScreen.title,
      child: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) => PagedTableLayout(
          toolbar: SearchToolbar(
            controller: _searchController,
            hintText: 'po korisniku ili vozilu',
            onChanged: _onSearchChanged,
          ),
          table: DataTableCard(
            scrollController: _scrollController,
            columns: _columns,
            rows: [for (final item in _controller.items) _buildCells(item, vehicleProvider)],
            isLoading: _controller.isLoading,
            error: _controller.error,
            onRetry: _controller.load,
            emptyText: _isFiltered ? 'Nema recenzija koje odgovaraju pretrazi.' : 'Nema recenzija.',
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

  List<Widget> _buildCells(Review item, VehicleProvider vehicleProvider) {
    return [
      ImageTextCell(
        image: UserAvatar(userId: item.userId, hasImage: item.userHasImage),
        text: item.userFullName,
      ),
      ImageTextCell(
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
      _RatingStars(item.rating),
      _CommentCell(item.comment),
      Text(formatDate(item.createdAt), style: const TextStyle(fontSize: 15)),
      TableActionButtons(onDelete: () => _delete(item)),
    ];
  }

  void _onSearchChanged(String text) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      _scrollToTop();
      _controller.search(_buildFilter());
    });
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

  Future<void> _delete(Review item) async {
    final confirmed = await confirmDialog(
      context,
      title: 'Brisanje',
      content: 'Da li želite obrisati recenziju korisnika „${item.userFullName}” za vozilo „${item.vehicleName}”?',
      confirmLabel: 'Obriši',
      destructive: true,
    );
    if (!confirmed || !mounted) {
      return;
    }

    try {
      await _provider.remove(item.id);
      if (!mounted) {
        return;
      }
      showSnack(context, 'Recenzija je obrisana.');
      _controller.load();
    } on UnauthorizedException {
      return;
    } on ApiClientException catch (e) {
      if (mounted) {
        _controller.load();
        await alertBox(context, 'Brisanje nije moguće', e.message);
      }
    }
  }
}

class _RatingStars extends StatelessWidget {
  const _RatingStars(this.rating);

  final int rating;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Ocjena $rating od 5',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 1; i <= 5; i++)
            Icon(
              i <= rating ? Icons.star_rounded : Icons.star_outline_rounded,
              color: i <= rating ? AppColors.rating : AppColors.border,
              size: 24,
            ),
        ],
      ),
    );
  }
}

class _CommentCell extends StatelessWidget {
  const _CommentCell(this.comment);

  final String? comment;

  @override
  Widget build(BuildContext context) {
    final text = comment?.trim() ?? '';
    if (text.isEmpty) {
      return const Text('Bez komentara', style: TextStyle(fontSize: 15, color: AppColors.textMuted));
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Tooltip(
        message: text,
        child: Text(text, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
      ),
    );
  }
}
