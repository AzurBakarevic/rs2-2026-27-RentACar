import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../utils/api_client_exception.dart';
import '../utils/app_theme.dart';
import '../utils/form_errors.dart';
import '../utils/user_validators.dart';
import '../utils/utils_widgets.dart';
import '../widgets/form_page.dart';
import '../widgets/notice_box.dart';
import 'reset_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isSending = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return FormPage(
      title: 'Zaboravljena lozinka',
      child: FormBuilder(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Unesite e-mail adresu svog naloga. Na nju ćemo poslati kod pomoću kojeg postavljate novu lozinku.',
              style: TextStyle(fontSize: 16, color: AppColors.textMuted),
            ),
            const SizedBox(height: 24),
            NoticeBox(message: _error),
            FormBuilderTextField(
              name: 'email',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.email],
              onSubmitted: (_) => _send(),
              decoration: const InputDecoration(labelText: 'E-mail', prefixIcon: Icon(Icons.mail_outline)),
              validator: validateEmail,
              valueTransformer: (value) => value?.trim() ?? '',
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _isSending ? null : _send,
              child: _isSending
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                  : const Text('Pošalji kod'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _send() async {
    if (_isSending) {
      return;
    }
    final form = _formKey.currentState!;
    clearServerErrors(form);
    if (!form.saveAndValidate()) {
      return;
    }

    setState(() {
      _isSending = true;
      _error = null;
    });

    final email = form.value['email'] as String;
    try {
      await context.read<AuthProvider>().requestPasswordReset(email);
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => ResetPasswordScreen(email: email)),
        );
      }
    } on ApiClientException catch (e) {
      _showError(applyServerErrors(form, e));
    } catch (e) {
      debugPrint('Slanje koda nije uspjelo: $e');
      _showError(unexpectedResponseError);
    }
  }

  void _showError(String? message) {
    if (mounted) {
      setState(() {
        _isSending = false;
        _error = message;
      });
    }
  }
}
