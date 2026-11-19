import 'dart:math';

import 'package:material_ui/material_ui.dart';

import '../utils/app_theme.dart';

/// Brojevi stranica (« prva, » posljednja) i dugmad Prethodna/Sljedeća, kao na skicama.
class PaginationBar extends StatelessWidget {
  const PaginationBar({
    super.key,
    required this.page,
    required this.pageCount,
    required this.onPageChanged,
  });

  final int page;
  final int pageCount;
  final ValueChanged<int> onPageChanged;

  static const int _visiblePages = 9;

  @override
  Widget build(BuildContext context) {
    var first = max(1, page - _visiblePages ~/ 2);
    final last = min(pageCount, first + _visiblePages - 1);
    first = max(1, last - _visiblePages + 1);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            _PageButton(label: '«', tooltip: 'Prva stranica', onPressed: page > 1 ? () => onPageChanged(1) : null),
            for (var i = first; i <= last; i++)
              _PageButton(label: '$i', selected: i == page, onPressed: () => onPageChanged(i)),
            _PageButton(
              label: '»',
              tooltip: 'Posljednja stranica',
              onPressed: page < pageCount ? () => onPageChanged(pageCount) : null,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              width: 360,
              child: OutlinedButton.icon(
                onPressed: page > 1 ? () => onPageChanged(page - 1) : null,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Prethodna'),
              ),
            ),
            SizedBox(
              width: 360,
              child: OutlinedButton.icon(
                onPressed: page < pageCount ? () => onPageChanged(page + 1) : null,
                style: OutlinedButton.styleFrom(side: BorderSide(color: page < pageCount ? AppColors.primary : AppColors.border)),
                icon: const Icon(Icons.arrow_forward),
                iconAlignment: IconAlignment.end,
                label: const Text('Sljedeća'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PageButton extends StatelessWidget {
  const _PageButton({required this.label, this.selected = false, this.tooltip, this.onPressed});

  final String label;
  final bool selected;
  final String? tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final button = SizedBox(
      width: 56,
      height: 48,
      child: selected
          ? FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
              child: Text(label),
            )
          : OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                foregroundColor: AppColors.textDark,
                textStyle: const TextStyle(fontSize: 16),
              ),
              child: Text(label),
            ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip, child: button);
  }
}
