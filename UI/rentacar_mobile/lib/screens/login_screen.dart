import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:material_ui/material_ui.dart';

import '../utils/api_client_exception.dart';
import '../utils/app_theme.dart';
import '../utils/form_errors.dart';
import '../utils/session.dart';
import '../utils/utils_widgets.dart';
import '../widgets/notice_box.dart';
import '../widgets/password_field.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.message});

  final String? message;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isLoading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: AutofillGroup(child: _buildForm()),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return FormBuilder(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.directions_car_outlined, color: Colors.white, size: 40),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'RentACar',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textDark),
          ),
          const SizedBox(height: 4),
          const Text(
            'Prijavite se na svoj nalog',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: AppColors.textMuted),
          ),
          const SizedBox(height: 32),
          NoticeBox(
            message: _error ?? widget.message,
            type: _error != null ? NoticeType.error : NoticeType.info,
          ),
          FormBuilderTextField(
            name: 'username',
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.username],
            decoration: const InputDecoration(labelText: 'Korisničko ime', prefixIcon: Icon(Icons.person_outline)),
            validator: (value) => (value?.trim() ?? '').isEmpty ? 'Unesite korisničko ime.' : null,
          ),
          const SizedBox(height: 20),
          PasswordField(
            name: 'password',
            label: 'Lozinka',
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            onSubmitted: _login,
            validator: (value) => (value ?? '').isEmpty ? 'Unesite lozinku.' : null,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _isLoading ? null : _openForgotPassword,
              child: const Text('Zaboravili ste lozinku?'),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _isLoading ? null : _login,
            child: _isLoading
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                : const Text('Prijava'),
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text('Nemate nalog?', style: TextStyle(color: AppColors.textMuted, fontSize: 15)),
              TextButton(
                onPressed: _isLoading ? null : _openRegister,
                child: const Text('Registrujte se'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openRegister() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterScreen()));
  }

  void _openForgotPassword() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()));
  }

  Future<void> _login() async {
    if (_isLoading) {
      return;
    }
    final form = _formKey.currentState!;
    clearServerErrors(form);
    if (!form.saveAndValidate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await signIn(context, (form.value['username'] as String).trim(), form.value['password'] as String);
      if (mounted) {
        openHome(context);
      }
    } on ApiClientException catch (e) {
      _showError(applyServerErrors(form, e));
      focusFirstError(form, 'password');
    } catch (e) {
      debugPrint('Prijava nije uspjela: $e');
      _showError(unexpectedResponseError);
    }
  }

  void _showError(String? message) {
    if (mounted) {
      setState(() {
        _isLoading = false;
        _error = message;
      });
    }
  }
}
