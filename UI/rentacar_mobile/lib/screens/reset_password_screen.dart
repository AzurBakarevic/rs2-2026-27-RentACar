import 'dart:async';

import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../utils/api_client_exception.dart';
import '../utils/form_errors.dart';
import '../utils/session.dart';
import '../utils/user_validators.dart';
import '../utils/utils_widgets.dart';
import '../widgets/form_page.dart';
import '../widgets/notice_box.dart';
import '../widgets/password_field.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, required this.email});

  final String email;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  static const int _resendCooldownSeconds = 60;
  static const int _codeValidMinutes = 15;

  final _formKey = GlobalKey<FormBuilderState>();
  bool _isSaving = false;
  bool _isResending = false;
  String? _error;
  String? _info;
  int _resendSecondsLeft = _resendCooldownSeconds;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _info = _sentMessage();
    _startResendCooldown();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    super.dispose();
  }

  String _sentMessage() =>
      'Ako je adresa ${widget.email} povezana s nalogom, na nju je poslan kod od $resetCodeLength cifara. '
      'Kod važi $_codeValidMinutes minuta.';

  void _startResendCooldown() {
    _resendTimer?.cancel();
    _resendSecondsLeft = _resendCooldownSeconds;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _resendSecondsLeft--);
      if (_resendSecondsLeft <= 0) {
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final canResend = _resendSecondsLeft <= 0 && !_isResending && !_isSaving;
    return FormPage(
      title: 'Nova lozinka',
      child: FormBuilder(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            NoticeBox(message: _info, type: NoticeType.info),
            NoticeBox(message: _error),
            FormBuilderTextField(
              name: 'code',
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.oneTimeCode],
              maxLength: resetCodeLength,
              decoration: const InputDecoration(
                labelText: 'Kod iz e-maila',
                prefixIcon: Icon(Icons.pin_outlined),
                counterText: '',
              ),
              validator: validateResetCode,
              valueTransformer: (value) => value?.trim() ?? '',
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
              onSubmitted: _reset,
              validator: passwordConfirmValidator(() => _formKey.currentState?.fields['newPassword']?.value),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _isSaving ? null : _reset,
              child: _isSaving
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                  : const Text('Postavi novu lozinku'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: canResend ? _resend : null,
              child: Text(
                _resendSecondsLeft > 0 ? 'Novi kod možete zatražiti za $_resendSecondsLeft s' : 'Pošalji novi kod',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _resend() async {
    setState(() {
      _isResending = true;
      _error = null;
    });
    try {
      await context.read<AuthProvider>().requestPasswordReset(widget.email);
      if (mounted) {
        setState(() {
          _isResending = false;
          _info = _sentMessage();
          _startResendCooldown();
        });
      }
    } on ApiClientException catch (e) {
      _showError(e.message);
    } catch (e) {
      debugPrint('Ponovno slanje koda nije uspjelo: $e');
      _showError(unexpectedResponseError);
    }
  }

  Future<void> _reset() async {
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
      await context.read<AuthProvider>().resetPassword({'email': widget.email, ...form.value});
      if (mounted) {
        openLogin(Navigator.of(context), message: 'Lozinka je promijenjena. Prijavite se novom lozinkom.');
      }
    } on ApiClientException catch (e) {
      _showError(applyServerErrors(form, e));
      focusFirstError(form, 'code');
    } catch (e) {
      debugPrint('Postavljanje lozinke nije uspjelo: $e');
      _showError(unexpectedResponseError);
    }
  }

  void _showError(String? message) {
    if (mounted) {
      setState(() {
        _isSaving = false;
        _isResending = false;
        _error = message;
      });
    }
  }
}
