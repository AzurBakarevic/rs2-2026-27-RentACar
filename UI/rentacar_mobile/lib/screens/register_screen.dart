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

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isSaving = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return FormPage(
      title: 'Registracija',
      child: FormBuilder(
        key: _formKey,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              NoticeBox(message: _error),
              _textField(
                name: 'firstName',
                label: 'Ime',
                icon: Icons.badge_outlined,
                validator: validateFirstName,
                autofillHints: const [AutofillHints.givenName],
              ),
              _textField(
                name: 'lastName',
                label: 'Prezime',
                icon: Icons.badge_outlined,
                validator: validateLastName,
                autofillHints: const [AutofillHints.familyName],
              ),
              _textField(
                name: 'email',
                label: 'E-mail',
                icon: Icons.mail_outline,
                validator: validateEmail,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
              ),
              _textField(
                name: 'phoneNumber',
                label: 'Broj telefona',
                hint: 'npr. 061 111 222',
                icon: Icons.phone_outlined,
                validator: validatePhone,
                keyboardType: TextInputType.phone,
                autofillHints: const [AutofillHints.telephoneNumber],
              ),
              _textField(
                name: 'username',
                label: 'Korisničko ime',
                icon: Icons.person_outline,
                validator: validateUsername,
                autofillHints: const [AutofillHints.newUsername],
              ),
              PasswordField(
                name: 'password',
                label: 'Lozinka',
                autofillHints: const [AutofillHints.newPassword],
                validator: validatePassword,
              ),
              const SizedBox(height: 20),
              PasswordField(
                name: 'passwordConfirm',
                label: 'Potvrda lozinke',
                textInputAction: TextInputAction.done,
                onSubmitted: _register,
                validator: passwordConfirmValidator(() => _formKey.currentState?.fields['password']?.value),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _isSaving ? null : _register,
                child: _isSaving
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                    : const Text('Registruj se'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _textField({
    required String name,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
    String? hint,
    TextInputType? keyboardType,
    Iterable<String>? autofillHints,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: FormBuilderTextField(
        name: name,
        keyboardType: keyboardType,
        textInputAction: TextInputAction.next,
        autofillHints: autofillHints,
        decoration: InputDecoration(labelText: label, hintText: hint, prefixIcon: Icon(icon)),
        validator: validator,
        valueTransformer: (value) => value?.trim() ?? '',
      ),
    );
  }

  Future<void> _register() async {
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

    final values = Map<String, dynamic>.from(form.value);
    try {
      await context.read<AuthProvider>().register(values);
    } on ApiClientException catch (e) {
      _showError(applyServerErrors(form, e));
      focusFirstError(form, 'firstName');
      return;
    } catch (e) {
      debugPrint('Registracija nije uspjela: $e');
      _showError(unexpectedResponseError);
      return;
    }

    if (!mounted) {
      return;
    }
    try {
      await signIn(context, values['username'] as String, values['password'] as String);
      if (mounted) {
        openHome(context);
      }
    } catch (e) {
      debugPrint('Prijava nakon registracije nije uspjela: $e');
      if (mounted) {
        openLogin(Navigator.of(context), message: 'Nalog je kreiran. Prijavite se korisničkim imenom i lozinkom.');
      }
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
