import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:material_ui/material_ui.dart';

import '../utils/api_client_exception.dart';
import '../utils/app_theme.dart';
import '../utils/form_errors.dart';
import '../utils/utils_widgets.dart';

/// Forma za zapis šifarnika: naziv i, po potrebi, dodatna polja (npr. marka modela).
/// Vraća `true` ako je zapis sačuvan.
Future<bool> showReferenceDataDialog(
  BuildContext context, {
  required String title,
  required Map<String, dynamic> initialValue,
  List<Widget> extraFields = const [],
  required Future<void> Function(Map<String, dynamic> values) onSave,
}) async {
  final saved = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _ReferenceDataDialog(
      title: title,
      initialValue: initialValue,
      extraFields: extraFields,
      onSave: onSave,
    ),
  );
  return saved ?? false;
}

class _ReferenceDataDialog extends StatefulWidget {
  const _ReferenceDataDialog({
    required this.title,
    required this.initialValue,
    required this.extraFields,
    required this.onSave,
  });

  final String title;
  final Map<String, dynamic> initialValue;
  final List<Widget> extraFields;
  final Future<void> Function(Map<String, dynamic> values) onSave;

  @override
  State<_ReferenceDataDialog> createState() => _ReferenceDataDialogState();
}

class _ReferenceDataDialogState extends State<_ReferenceDataDialog> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isSaving = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 440,
        child: FormBuilder(
          key: _formKey,
          initialValue: widget.initialValue,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Poruka je uvijek na istom mjestu u listi, inače bi se polja ispod nje
              // napravila iznova i izgubila fokus.
              _buildError(),
              FormBuilderTextField(
                name: 'name',
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Naziv'),
                validator: requiredText(
                  'Naziv je obavezan.',
                  maxLength: 50,
                  maxLengthMessage: 'Naziv može imati najviše 50 znakova.',
                ),
                onSubmitted: (_) => _save(),
              ),
              for (final field in widget.extraFields) ...[
                const SizedBox(height: 16),
                field,
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context, false),
          child: const Text('Odustani'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5))
              : const Text('Sačuvaj'),
        ),
      ],
    );
  }

  Widget _buildError() {
    if (_error == null) {
      return const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.errorBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(_error!, style: const TextStyle(color: AppColors.error)),
    );
  }

  Future<void> _save() async {
    if (_isSaving) {
      return;
    }
    final form = _formKey.currentState!;
    clearServerErrors(form);
    if (!form.saveAndValidate()) {
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final values = Map<String, dynamic>.from(form.value);
      values['name'] = (values['name'] as String).trim();
      await widget.onSave(values);
      if (mounted) {
        Navigator.pop(context, true);
      }
    } on UnauthorizedException {
      // Aplikacija se već vraća na prijavu.
    } on ApiClientException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSaving = false;
        _error = applyServerErrors(form, e);
      });
      focusFirstError(form, 'name');
    }
  }
}
