import 'package:material_ui/material_ui.dart';

import 'app_theme.dart';

Future<void> alertBox(BuildContext context, String title, String content) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('U redu'),
        ),
      ],
    ),
  );
}

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String content,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Odustani'),
        ),
        FilledButton(
          style: destructive ? FilledButton.styleFrom(backgroundColor: AppColors.error) : null,
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

const String savingInProgressReason = 'Sačekajte da se spremanje završi.';

const String unexpectedSaveError =
    'Spremanje nije potvrđeno zbog neočekivane greške. Provjerite listu prije ponovnog pokušaja.';

void closeForm(BuildContext context, {required bool saved}) {
  final navigator = Navigator.of(context);
  final route = ModalRoute.of(context);
  if (route == null || !route.isActive) {
    return;
  }
  navigator.popUntil((current) => current == route);
  navigator.pop(saved);
}

void showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

String? Function(String?) requiredText(String message, {int? maxLength, String? maxLengthMessage}) {
  return (value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return message;
    }
    if (maxLength != null && text.length > maxLength) {
      return maxLengthMessage;
    }
    return null;
  };
}

const InputDecoration plainFieldDecoration = InputDecoration(
  border: InputBorder.none,
  enabledBorder: InputBorder.none,
  focusedBorder: InputBorder.none,
  contentPadding: EdgeInsets.zero,
);
