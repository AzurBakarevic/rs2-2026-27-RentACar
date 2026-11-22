import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import '../providers/base_provider.dart';
import '../utils/api_client_exception.dart';
import '../utils/paged_list_controller.dart';
import '../utils/utils_widgets.dart';
import 'data_table_card.dart';
import 'pagination_bar.dart';
import 'search_toolbar.dart';
import 'table_action_buttons.dart';

/// Tekstovi jedne liste (rod i padež se razlikuju: „Nova oprema”, „Novi servis”...).
class CrudListLabels<T> {
  const CrudListLabels({
    required this.searchHint,
    required this.newItem,
    required this.deleteQuestion,
    required this.saved,
    required this.deleted,
  });

  final String searchHint;
  final String newItem;
  final String Function(T item) deleteQuestion;
  final String saved;
  final String deleted;
}

/// Tabelarni pregled s pretragom, paginacijom, dodavanjem, izmjenom i brisanjem (šifarnici, vozila,
/// oprema, servisi, sezonske cijene). Kolona „Akcije” se dodaje sama.
class CrudListView<T> extends StatefulWidget {
  const CrudListView({
    super.key,
    required this.provider,
    required this.idOf,
    required this.labels,
    required this.columns,
    required this.cells,
    required this.openForm,
    this.newBlockedReason,
    this.deleteBlockedReason,
    this.searchKey = 'name',
    this.extraFilter = const {},
    this.filters = const [],
    this.onClearFilters,
    this.padding = const EdgeInsets.fromLTRB(32, 32, 32, 24),
  });

  final BaseProvider<T> provider;

  /// Id zapisa za brisanje.
  final int Function(T item) idOf;

  final CrudListLabels<T> labels;
  final List<TableColumnDef> columns;
  final List<Widget> Function(T item) cells;

  /// Otvara formu za novi zapis (`null`) ili izmjenu; vraća `true` ako je zapis sačuvan.
  final Future<bool> Function(BuildContext context, T? item) openForm;

  /// Preduslovi za novi zapis: vraća razlog zbog kojeg se forma ne može otvoriti ili `null` (upute 6).
  final Future<String?> Function()? newBlockedReason;

  /// Razlog zbog kojeg se zapis ne može obrisati ili `null` (upute 6).
  final String? Function(T item)? deleteBlockedReason;

  /// Parametar API-ja za tekst iz pretrage (npr. `name` ili `text`).
  final String searchKey;

  /// Filteri koje drži ekran (npr. datum kod servisa); promjena ponovo učitava listu od prve stranice.
  final Map<String, dynamic> extraFilter;

  /// Polja za [extraFilter], prikazana lijevo od pretrage.
  final List<Widget> filters;

  /// Prazni [extraFilter]; poziva se poslije dodavanja, da novi zapis ne ostane skriven iza filtera.
  final VoidCallback? onClearFilters;

  final EdgeInsets padding;

  @override
  State<CrudListView<T>> createState() => _CrudListViewState<T>();
}

class _CrudListViewState<T> extends State<CrudListView<T>> {
  late final PagedListController<T> _controller = PagedListController<T>(widget.provider);
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _searchDebounce;
  String? _newBlockedReason;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _controller.search(_buildFilter());
    _checkPrerequisites();
  }

  @override
  void didUpdateWidget(CrudListView<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!mapEquals(oldWidget.extraFilter, widget.extraFilter)) {
      _controller.search(_buildFilter());
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildFilter() => {
        ...widget.extraFilter,
        widget.searchKey: _searchController.text.trim(),
        'newestFirst': true,
      };

  bool get _isFiltered =>
      _searchController.text.trim().isNotEmpty || widget.extraFilter.values.any((value) => value != null);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding,
      child: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SearchToolbar(
              controller: _searchController,
              hintText: widget.labels.searchHint,
              onChanged: _onSearchChanged,
              newLabel: widget.labels.newItem,
              onNew: _create,
              newBlockedReason: _newBlockedReason,
              filters: widget.filters,
            ),
            const SizedBox(height: 32),
            Flexible(
              child: DataTableCard(
                scrollController: _scrollController,
                columns: [...widget.columns, const TableColumnDef('Akcije')],
                rows: [
                  for (final item in _controller.items)
                    [
                      ...widget.cells(item),
                      TableActionButtons(
                        onEdit: () => _edit(item),
                        onDelete: () => _delete(item),
                        deleteBlockedReason: widget.deleteBlockedReason?.call(item),
                      ),
                    ],
                ],
                isLoading: _controller.isLoading,
                error: _controller.error,
                onRetry: _controller.load,
                emptyText: _isFiltered ? 'Nema zapisa koji odgovaraju pretrazi.' : 'Nema zapisa.',
              ),
            ),
            const SizedBox(height: 32),
            PaginationBar(
              page: _controller.page,
              pageCount: _controller.pageCount,
              onPageChanged: _controller.goToPage,
            ),
          ],
        ),
      ),
    );
  }

  void _onSearchChanged(String text) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      _controller.search(_buildFilter());
    });
  }

  Future<void> _checkPrerequisites() async {
    try {
      final reason = await widget.newBlockedReason?.call();
      if (mounted) {
        setState(() => _newBlockedReason = reason);
      }
    } on ApiClientException catch (e) {
      // Dugme ostaje aktivno; preduslovi se ponovo provjeravaju na klik, pa se tada prikazuje i greška.
      debugPrint('Provjera preduslova za ${widget.provider.endpoint} nije uspjela: $e');
    }
  }

  // Dok traje provjera preduslova, drugi klik ne otvara još jednu formu.
  Future<void> _create() async {
    if (_isCreating) {
      return;
    }
    _isCreating = true;
    try {
      await _edit(null);
    } finally {
      _isCreating = false;
    }
  }

  Future<void> _edit(T? item) async {
    bool saved;
    try {
      if (item == null) {
        // Ponovo, jer je preduslov mogao biti obrisan otkad je lista otvorena.
        final reason = await widget.newBlockedReason?.call();
        if (!mounted) {
          return;
        }
        if (reason != null) {
          setState(() => _newBlockedReason = reason);
          await alertBox(context, 'Unos nije moguć', reason);
          return;
        }
      }
      saved = await widget.openForm(context, item);
    } on UnauthorizedException {
      return;
    } on ApiClientException catch (e) {
      // Npr. podaci za padajuće liste forme nisu učitani.
      if (mounted) {
        await alertBox(context, 'Greška', e.message);
      }
      return;
    }

    if (saved && mounted) {
      showSnack(context, widget.labels.saved);
      if (item == null) {
        _showNewest();
      } else {
        _controller.load();
      }
    }
  }

  // Novi zapis je prvi red prve stranice, pa se poništava sve što bi ga sakrilo (upute 6).
  void _showNewest() {
    _searchDebounce?.cancel();
    _searchController.clear();
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
    if (widget.extraFilter.isNotEmpty && widget.onClearFilters != null) {
      // Listu učitava didUpdateWidget, kad ekran vrati prazan filter.
      widget.onClearFilters!();
    } else {
      _controller.search(_buildFilter());
    }
  }

  Future<void> _delete(T item) async {
    final confirmed = await confirmDialog(
      context,
      title: 'Brisanje',
      content: widget.labels.deleteQuestion(item),
      confirmLabel: 'Obriši',
      destructive: true,
    );
    if (!confirmed || !mounted) {
      return;
    }

    try {
      await widget.provider.remove(widget.idOf(item));
      if (!mounted) {
        return;
      }
      showSnack(context, widget.labels.deleted);
      _controller.load();
    } on UnauthorizedException {
      return;
    } on ApiClientException catch (e) {
      if (mounted) {
        // Zapis je u međuvremenu iskorišten ili obrisan, pa red više nije tačan.
        _controller.load();
        await alertBox(context, 'Brisanje nije moguće', e.message);
      }
    }
  }
}
