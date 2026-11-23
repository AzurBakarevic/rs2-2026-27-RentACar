import 'package:material_ui/material_ui.dart';

import '../utils/utils_widgets.dart';

class FormCloseButton extends StatelessWidget {
  const FormCloseButton({super.key, required this.isSaving, required this.onClose});

  final bool isSaving;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: isSaving ? savingInProgressReason : 'Zatvori',
      icon: const Icon(Icons.close),
      onPressed: isSaving ? null : onClose,
    );
  }
}
