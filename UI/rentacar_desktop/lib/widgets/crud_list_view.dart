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
    this.searchKey = 'name',
    this.extraFilter = const {},
    this.filters = const [],
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

  /// Parametar API-ja za tekst iz pretrage (npr. `name` ili `text`).
  final String searchKey;

  /// Filteri koje drži ekran (npr. datum kod servisa); promjena ponovo učitava listu od prve stranice.
  final Map<String, dynamic> extraFilter;

  /// Polja za [extraFilter], prikazana lijevo od pretrage.
  final List<Widget> filters;

  final EdgeInsets padding;

  @override
  State<CrudListView<T>> createState() => _CrudListViewState<T>();
}

class _CrudListViewState<T> extends State<CrudListView<T>> {
  late final PagedListController<T> _controller = PagedListController<T>(widget.provider);
  final _searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _controller.search(_buildFilter());
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
    _controller.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildFilter() => {
        ...widget.extraFilter,
        widget.searchKey: _searchController.text.trim(),
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
              onNew: () => _edit(null),
              filters: widget.filters,
            ),
            const SizedBox(height: 32),
            Flexible(
              child: DataTableCard(
                columns: [...widget.columns, const TableColumnDef('Akcije')],
                rows: [
                  for (final item in _controller.items)
                    [
                      ...widget.cells(item),
                      TableActionButtons(onEdit: () => _edit(item), onDelete: () => _delete(item)),
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

  Future<void> _edit(T? item) async {
    bool saved;
    try {
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
      _controller.load();
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
        await alertBox(context, 'Brisanje nije moguće', e.message);
      }
    }
  }
}
