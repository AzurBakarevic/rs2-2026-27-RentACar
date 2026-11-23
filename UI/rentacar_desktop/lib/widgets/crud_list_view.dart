import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import '../providers/base_provider.dart';
import '../utils/api_client_exception.dart';
import '../utils/paged_list_controller.dart';
import '../utils/utils_widgets.dart';
import 'data_table_card.dart';
import 'paged_table_layout.dart';
import 'pagination_bar.dart';
import 'search_toolbar.dart';
import 'table_action_buttons.dart';

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

  final int Function(T item) idOf;

  final CrudListLabels<T> labels;
  final List<TableColumnDef> columns;
  final List<Widget> Function(T item) cells;

  final Future<bool> Function(BuildContext context, T? item) openForm;

  final Future<String?> Function()? newBlockedReason;

  final String? Function(T item)? deleteBlockedReason;

  final String searchKey;

  final Map<String, dynamic> extraFilter;

  final List<Widget> filters;

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
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) => PagedTableLayout(
        padding: widget.padding,
        toolbar: SearchToolbar(
          controller: _searchController,
          hintText: widget.labels.searchHint,
          onChanged: _onSearchChanged,
          newLabel: widget.labels.newItem,
          onNew: _create,
          newBlockedReason: _newBlockedReason,
          filters: widget.filters,
        ),
        table: DataTableCard(
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
        pagination: PaginationBar(
          page: _controller.page,
          pageCount: _controller.pageCount,
          onPageChanged: _controller.goToPage,
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
      debugPrint('Provjera preduslova za ${widget.provider.endpoint} nije uspjela: $e');
    }
  }

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

  void _showNewest() {
    _searchDebounce?.cancel();
    _searchController.clear();
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
    if (widget.extraFilter.isNotEmpty && widget.onClearFilters != null) {
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
        _controller.load();
        await alertBox(context, 'Brisanje nije moguće', e.message);
      }
    }
  }
}
