import 'package:material_ui/material_ui.dart';

class SearchToolbar extends StatelessWidget {
  const SearchToolbar({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
    this.newLabel,
    this.onNew,
    this.newBlockedReason,
    this.filters = const [],
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final String? newLabel;
  final VoidCallback? onNew;

  final String? newBlockedReason;

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
        if (newLabel case final label?) ...[
          const SizedBox(width: 16),
          if (newBlockedReason == null)
            FilledButton(onPressed: onNew, child: Text(label))
          else
            Tooltip(message: newBlockedReason, child: FilledButton(onPressed: null, child: Text(label))),
        ],
      ],
    );
  }
}
