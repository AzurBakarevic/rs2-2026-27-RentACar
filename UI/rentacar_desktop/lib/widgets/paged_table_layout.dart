import 'dart:math';

import 'package:material_ui/material_ui.dart';

class PagedTableLayout extends StatelessWidget {
  const PagedTableLayout({
    super.key,
    required this.toolbar,
    required this.table,
    required this.pagination,
    this.padding = const EdgeInsets.fromLTRB(32, 32, 32, 24),
  });

  final Widget toolbar;
  final Widget table;
  final Widget pagination;
  final EdgeInsets padding;

  static const double _minHeight = 440;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: SizedBox(
          height: max(constraints.maxHeight, _minHeight),
          child: Padding(
            padding: padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                toolbar,
                const SizedBox(height: 32),
                Flexible(child: table),
                const SizedBox(height: 32),
                pagination,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
