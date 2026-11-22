import 'package:material_ui/material_ui.dart';

import '../utils/app_theme.dart';

class TableColumnDef {
  const TableColumnDef(this.label, {this.flex = 1});

  final String label;
  final int flex;
}

/// Tabela kao na skicama: zaglavlje velikim slovima, centrirane ćelije, okvir sa zaobljenim uglovima.
class DataTableCard extends StatelessWidget {
  const DataTableCard({
    super.key,
    required this.columns,
    required this.rows,
    this.isLoading = false,
    this.error,
    this.onRetry,
    this.emptyText = 'Nema zapisa.',
    this.scrollController,
  });

  final List<TableColumnDef> columns;
  final List<List<Widget>> rows;
  final bool isLoading;
  final String? error;
  final VoidCallback? onRetry;
  final String emptyText;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          Flexible(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: AppColors.background,
      height: 56,
      child: Row(
        children: [
          for (final column in columns)
            Expanded(
              flex: column.flex,
              child: Text(
                column.label.toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                  color: AppColors.textMuted,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (error != null) {
      return _buildMessage(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.error)),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(onPressed: onRetry, child: const Text('Pokušaj ponovo')),
            ],
          ],
        ),
      );
    }

    if (isLoading && rows.isEmpty) {
      return _buildMessage(const CircularProgressIndicator());
    }

    if (rows.isEmpty) {
      return _buildMessage(Text(emptyText, style: const TextStyle(color: AppColors.textMuted)));
    }

    return Stack(
      children: [
        ListView.separated(
          controller: scrollController,
          shrinkWrap: true,
          itemCount: rows.length,
          separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.border),
          itemBuilder: (context, index) => _buildRow(rows[index]),
        ),
        // Pri promjeni stranice stari redovi ostaju vidljivi dok ne stignu novi.
        if (isLoading) const Positioned(left: 0, right: 0, top: 0, child: LinearProgressIndicator(minHeight: 2)),
      ],
    );
  }

  Widget _buildRow(List<Widget> cells) {
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          for (var i = 0; i < columns.length; i++)
            Expanded(
              flex: columns[i].flex,
              child: DefaultTextStyle.merge(
                style: const TextStyle(fontSize: 16, color: AppColors.textDark),
                textAlign: TextAlign.center,
                child: Center(child: i < cells.length ? cells[i] : const SizedBox.shrink()),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessage(Widget child) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(child: child),
    );
  }
}
