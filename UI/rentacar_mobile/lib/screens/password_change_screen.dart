import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../utils/api_client_exception.dart';
import '../utils/app_theme.dart';
import '../utils/form_errors.dart';
import '../utils/session.dart';
import '../utils/user_validators.dart';
import '../utils/utils_widgets.dart';
import '../widgets/form_page.dart';
import '../widgets/notice_box.dart';
import '../widgets/password_field.dart';

class PasswordChangeScreen extends StatefulWidget {
  const PasswordChangeScreen({super.key});

  @override
  State<PasswordChangeScreen> createState() => _PasswordChangeScreenState();
}

class _PasswordChangeScreenState extends State<PasswordChangeScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isSaving = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return FormPage(
      title: 'Promjena lozinke',
      child: FormBuilder(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Nakon promjene lozinke bit ćete odjavljeni i prijavljujete se novom lozinkom.',
              style: TextStyle(fontSize: 16, color: AppColors.textMuted),
            ),
            const SizedBox(height: 24),
            NoticeBox(message: _error),
            PasswordField(
              name: 'oldPassword',
              label: 'Trenutna lozinka',
              autofillHints: const [AutofillHints.password],
              validator: (value) => (value ?? '').isEmpty ? 'Unesite trenutnu lozinku.' : null,
            ),
            const SizedBox(height: 20),
            PasswordField(
              name: 'newPassword',
              label: 'Nova lozinka',
              autofillHints: const [AutofillHints.newPassword],
              validator: validatePassword,
            ),
            const SizedBox(height: 20),
            PasswordField(
              name: 'newPasswordConfirm',
              label: 'Potvrda nove lozinke',
              textInputAction: TextInputAction.done,
              onSubmitted: _save,
              validator: passwordConfirmValidator(() => _formKey.currentState?.fields['newPassword']?.value),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                  : const Text('Promijeni lozinku'),
            ),
          ],
        ),
      ),
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

    final auth = context.read<AuthProvider>();
    final navigator = Navigator.of(context, rootNavigator: true);
    try {
      await context.read<ProfileProvider>().changePassword(Map<String, dynamic>.from(form.value));
      auth.endSession();
      openLogin(navigator, message: 'Lozinka je promijenjena. Prijavite se novom lozinkom.');
    } on UnauthorizedException catch (_) {
    } on ApiClientException catch (e) {
      _showError(applyServerErrors(form, e));
      focusFirstError(form, 'oldPassword');
    } catch (e) {
      debugPrint('Promjena lozinke nije uspjela: $e');
      _showError(unexpectedResponseError);
    }
  }

  void _showError(String? message) {
    if (mounted) {
      setState(() {
        _isSaving = false;
        _error = message;
      });
    }
  }
}
