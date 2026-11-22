import 'package:material_ui/material_ui.dart';

/// Polje za pretragu i dugme za novi zapis, desno iznad tabele.
class SearchToolbar extends StatelessWidget {
  const SearchToolbar({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
    required this.newLabel,
    required this.onNew,
    this.newBlockedReason,
    this.filters = const [],
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final String newLabel;
  final VoidCallback onNew;

  /// Kad je zadan, dugme za novi zapis je onemogućeno, a razlog se prikazuje kad se pređe mišem preko njega.
  final String? newBlockedReason;

  /// Dodatni filteri lijevo od pretrage (npr. datum kod servisa vozila).
  final List<Widget> filters;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        for (final filter in filters) ...[filter, const SizedBox(width: 16)],
        Flexible(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: hintText,
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        if (newBlockedReason == null)
          FilledButton(onPressed: onNew, child: Text(newLabel))
        else
          Tooltip(message: newBlockedReason, child: FilledButton(onPressed: null, child: Text(newLabel))),
      ],
    );
  }
}
