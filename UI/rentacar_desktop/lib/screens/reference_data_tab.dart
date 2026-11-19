import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../models/named_entity.dart';
import '../providers/base_provider.dart';
import '../utils/api_client_exception.dart';
import '../utils/paged_list_controller.dart';
import '../utils/utils_widgets.dart';
import '../widgets/data_table_card.dart';
import '../widgets/pagination_bar.dart';
import '../widgets/search_toolbar.dart';
import '../widgets/table_action_buttons.dart';
import 'reference_data_dialog.dart';

/// Tekstovi jednog šifarnika (rod i padež se razlikuju: „Nova marka”, „Novi model”...).
class ReferenceDataLabels {
  const ReferenceDataLabels({
    required this.newItem,
    required this.editItem,
    required this.deleteQuestion,
    required this.saved,
    required this.deleted,
  });

  final String newItem;
  final String editItem;
  final String Function(String name) deleteQuestion;
  final String saved;
  final String deleted;
}

/// Jedan tab ekrana Šifarnici: pretraga po nazivu, tabela, paginacija, dodavanje, izmjena i brisanje.
class ReferenceDataTab<T extends NamedEntity> extends StatefulWidget {
  const ReferenceDataTab({
    super.key,
    required this.provider,
    required this.labels,
    this.extraColumns = const [],
    this.extraCells,
    this.openForm,
  });

  final BaseProvider<T> provider;
  final ReferenceDataLabels labels;

  /// Kolone između „Naziv” i „Akcije” (npr. „Marka” kod modela).
  final List<String> extraColumns;
  final List<Widget> Function(T item)? extraCells;

  /// Vlastita forma; bez nje se otvara forma sa samo nazivom.
  final Future<bool> Function(BuildContext context, T? item)? openForm;

  @override
  State<ReferenceDataTab<T>> createState() => _ReferenceDataTabState<T>();
}

class _ReferenceDataTabState<T extends NamedEntity> extends State<ReferenceDataTab<T>> {
  late final PagedListController<T> _controller = PagedListController<T>(widget.provider);
  final _searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _controller.load();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 32, 0, 24),
      child: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SearchToolbar(
              controller: _searchController,
              hintText: 'po nazivu',
              onChanged: _onSearchChanged,
              newLabel: widget.labels.newItem,
              onNew: () => _edit(null),
            ),
            const SizedBox(height: 32),
            Flexible(
              child: DataTableCard(
                columns: [
                  const TableColumnDef('Naziv', flex: 2),
                  for (final column in widget.extraColumns) TableColumnDef(column, flex: 2),
                  const TableColumnDef('Akcije'),
                ],
                rows: [
                  for (final item in _controller.items)
                    [
                      Text(item.name),
                      ...?widget.extraCells?.call(item),
                      TableActionButtons(onEdit: () => _edit(item), onDelete: () => _delete(item)),
                    ],
                ],
                isLoading: _controller.isLoading,
                error: _controller.error,
                onRetry: _controller.load,
                emptyText: _searchController.text.trim().isEmpty
                    ? 'Nema zapisa.'
                    : 'Nema zapisa koji odgovaraju pretrazi.',
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
      _controller.search({'name': text.trim()});
    });
  }

  Future<void> _edit(T? item) async {
    final labels = widget.labels;
    bool saved;
    try {
      saved = widget.openForm != null
          ? await widget.openForm!(context, item)
          : await showReferenceDataDialog(
              context,
              title: item == null ? labels.newItem : labels.editItem,
              initialValue: {'name': item?.name ?? ''},
              onSave: (values) async {
                if (item == null) {
                  await widget.provider.insert(values);
                } else {
                  await widget.provider.update(item.id, values);
                }
              },
            );
    } on UnauthorizedException {
      return;
    } on ApiClientException catch (e) {
      // Npr. lista marki za formu modela nije učitana.
      if (mounted) {
        await alertBox(context, 'Greška', e.message);
      }
      return;
    }

    if (saved && mounted) {
      showSnack(context, labels.saved);
      _controller.load();
    }
  }

  Future<void> _delete(T item) async {
    final confirmed = await confirmDialog(
      context,
      title: 'Brisanje',
      content: widget.labels.deleteQuestion(item.name),
      confirmLabel: 'Obriši',
      destructive: true,
    );
    if (!confirmed || !mounted) {
      return;
    }

    try {
      await widget.provider.remove(item.id);
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
