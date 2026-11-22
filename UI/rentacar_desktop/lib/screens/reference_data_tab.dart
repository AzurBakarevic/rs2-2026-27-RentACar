import 'package:material_ui/material_ui.dart';

import '../models/named_entity.dart';
import '../providers/base_provider.dart';
import '../widgets/crud_list_view.dart';
import '../widgets/data_table_card.dart';
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
class ReferenceDataTab<T extends NamedEntity> extends StatelessWidget {
  const ReferenceDataTab({
    super.key,
    required this.provider,
    required this.labels,
    this.extraColumns = const [],
    this.extraCells,
    this.openForm,
    this.newBlockedReason,
  });

  final BaseProvider<T> provider;
  final ReferenceDataLabels labels;

  /// Kolone između „Naziv” i „Akcije” (npr. „Marka” kod modela).
  final List<String> extraColumns;
  final List<Widget> Function(T item)? extraCells;

  /// Vlastita forma; bez nje se otvara forma sa samo nazivom.
  final Future<bool> Function(BuildContext context, T? item)? openForm;

  /// Preduslovi za novi zapis (npr. marka za model).
  final Future<String?> Function()? newBlockedReason;

  @override
  Widget build(BuildContext context) {
    return CrudListView<T>(
      provider: provider,
      idOf: (item) => item.id,
      labels: CrudListLabels(
        searchHint: 'po nazivu',
        newItem: labels.newItem,
        deleteQuestion: (item) => labels.deleteQuestion(item.name),
        saved: labels.saved,
        deleted: labels.deleted,
      ),
      columns: [
        const TableColumnDef('Naziv', flex: 2),
        for (final column in extraColumns) TableColumnDef(column, flex: 2),
      ],
      cells: (item) => [Text(item.name), ...?extraCells?.call(item)],
      openForm: openForm ?? _openNameForm,
      newBlockedReason: newBlockedReason,
      deleteBlockedReason: (item) => item.deleteBlockedReason,
      padding: const EdgeInsets.fromLTRB(0, 32, 0, 24),
    );
  }

  Future<bool> _openNameForm(BuildContext context, T? item) {
    return showReferenceDataDialog(
      context,
      title: item == null ? labels.newItem : labels.editItem,
      initialValue: {'name': item?.name ?? ''},
      onSave: (values) async {
        if (item == null) {
          await provider.insert(values);
        } else {
          await provider.update(item.id, values);
        }
      },
    );
  }
}
