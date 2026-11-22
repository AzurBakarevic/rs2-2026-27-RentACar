import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:material_ui/material_ui.dart';

import '../utils/api_client_exception.dart';
import '../utils/app_theme.dart';
import '../utils/form_errors.dart';
import '../utils/utils_widgets.dart';
import 'form_close_button.dart';

/// Forma u dijalogu (šifarnici, oprema, servisi, sezonske cijene). [buildFields] dobija funkciju
/// za slanje forme (npr. na Enter u tekstualnom polju). Vraća `true` ako je zapis sačuvan.
///
/// [formKey] treba kad jedno polje provjerava drugo (npr. kraj servisa poslije početka).
/// [focusField] dobija fokus poslije greške servera koja nije uz neko polje.
Future<bool> showFormDialog(
  BuildContext context, {
  required String title,
  required Map<String, dynamic> initialValue,
  required List<Widget> Function(VoidCallback submit) buildFields,
  required Future<void> Function(Map<String, dynamic> values) onSave,
  required String focusField,
  GlobalKey<FormBuilderState>? formKey,
  double width = 440,
}) async {
  final saved = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _FormDialog(
      title: title,
      initialValue: initialValue,
      buildFields: buildFields,
      onSave: onSave,
      focusField: focusField,
      formKey: formKey ?? GlobalKey<FormBuilderState>(),
      width: width,
    ),
  );
  return saved ?? false;
}

class _FormDialog extends StatefulWidget {
  const _FormDialog({
    required this.title,
    required this.initialValue,
    required this.buildFields,
    required this.onSave,
    required this.focusField,
    required this.formKey,
    required this.width,
  });

  final String title;
  final Map<String, dynamic> initialValue;
  final List<Widget> Function(VoidCallback submit) buildFields;
  final Future<void> Function(Map<String, dynamic> values) onSave;
  final String focusField;
  final GlobalKey<FormBuilderState> formKey;
  final double width;

  @override
  State<_FormDialog> createState() => _FormDialogState();
}

class _FormDialogState extends State<_FormDialog> {
  bool _isSaving = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final fields = widget.buildFields(_save);
    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 12, 0),
      title: SizedBox(
        width: widget.width + 12,
        child: Row(
          children: [
            Expanded(child: Text(widget.title)),
            FormCloseButton(isSaving: _isSaving, onClose: () => Navigator.pop(context, false)),
          ],
        ),
      ),
      // Pomjeraju se samo polja: naslov i „X” ostaju vidljivi, a traka za pomjeranje je pored polja.
      contentPadding: EdgeInsets.zero,
      content: SizedBox(
        width: widget.width + 48,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: FormBuilder(
            key: widget.formKey,
            initialValue: widget.initialValue,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Poruka je uvijek na istom mjestu u listi, inače bi se polja ispod nje
                // napravila iznova i izgubila fokus.
                _buildError(),
                for (var i = 0; i < fields.length; i++) ...[
                  if (i > 0) const SizedBox(height: 16),
                  fields[i],
                ],
              ],
            ),
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
    final form = widget.formKey.currentState!;
    clearServerErrors(form);
    if (!form.saveAndValidate()) {
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      await widget.onSave(Map<String, dynamic>.from(form.value));
      if (mounted) {
        closeForm(context, saved: true);
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
      focusFirstError(form, widget.focusField);
    } catch (e) {
      debugPrint('Spremanje forme „${widget.title}” nije uspjelo: $e');
      if (mounted) {
        setState(() {
          _isSaving = false;
          _error = unexpectedSaveError;
        });
      }
    }
  }
}
