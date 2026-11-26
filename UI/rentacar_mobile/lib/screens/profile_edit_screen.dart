import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../providers/profile_provider.dart';
import '../utils/api_client_exception.dart';
import '../utils/app_theme.dart';
import '../utils/form_errors.dart';
import '../utils/formatters.dart';
import '../utils/user_validators.dart';
import '../utils/utils_widgets.dart';
import '../widgets/form_page.dart';
import '../widgets/notice_box.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key, required this.profile});

  final User profile;

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isSaving = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    return FormPage(
      title: 'Uredi profil',
      child: FormBuilder(
        key: _formKey,
        initialValue: {
          'firstName': profile.firstName,
          'lastName': profile.lastName,
          'email': profile.email,
          'phoneNumber': profile.phoneNumber,
          'username': profile.username,
          'driverLicenseNumber': profile.driverLicenseNumber ?? '',
          'driverLicenseValidUntil': profile.driverLicenseValidUntil,
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            NoticeBox(message: _error),
            _textField(name: 'firstName', label: 'Ime', icon: Icons.badge_outlined, validator: validateFirstName),
            _textField(name: 'lastName', label: 'Prezime', icon: Icons.badge_outlined, validator: validateLastName),
            _textField(
              name: 'email',
              label: 'E-mail',
              icon: Icons.mail_outline,
              validator: validateEmail,
              keyboardType: TextInputType.emailAddress,
            ),
            _textField(
              name: 'phoneNumber',
              label: 'Broj telefona',
              hint: 'npr. 061 111 222',
              icon: Icons.phone_outlined,
              validator: validatePhone,
              keyboardType: TextInputType.phone,
            ),
            _textField(
              name: 'username',
              label: 'Korisničko ime',
              icon: Icons.person_outline,
              validator: validateUsername,
            ),
            const SizedBox(height: 8),
            const Text(
              'Vozačka dozvola',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark),
            ),
            const SizedBox(height: 4),
            const Text(
              'Potrebna je za rezervaciju vozila i mora važiti do kraja najma.',
              style: TextStyle(fontSize: 15, color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            _textField(
              name: 'driverLicenseNumber',
              label: 'Broj vozačke dozvole',
              icon: Icons.credit_card_outlined,
              validator: (value) => validateDriverLicenseNumber(
                value,
                hasValidUntil: _formKey.currentState?.fields['driverLicenseValidUntil']?.value != null,
              ),
              emptyAsNull: true,
            ),
            FormBuilderDateTimePicker(
              name: 'driverLicenseValidUntil',
              inputType: InputType.date,
              format: DateFormat('dd.MM.yyyy'),
              decoration: const InputDecoration(
                labelText: 'Važi do',
                prefixIcon: Icon(Icons.event_outlined),
              ),
              validator: (value) => validateDriverLicenseValidUntil(
                value,
                hasNumber: (_formKey.currentState?.fields['driverLicenseNumber']?.value as String? ?? '').trim().isNotEmpty,
              ),
              valueTransformer: (value) => value == null ? null : toApiDate(value),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                  : const Text('Sačuvaj'),
            ),
          ],
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
    bool emptyAsNull = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: FormBuilderTextField(
        name: name,
        keyboardType: keyboardType,
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(labelText: label, hintText: hint, prefixIcon: Icon(icon)),
        validator: validator,
        valueTransformer: (value) {
          final text = value?.trim() ?? '';
          return emptyAsNull && text.isEmpty ? null : text;
        },
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

    try {
      await context.read<ProfileProvider>().update(Map<String, dynamic>.from(form.value));
      if (mounted) {
        showSnack(context, 'Profil je sačuvan.');
        Navigator.pop(context);
      }
    } on UnauthorizedException catch (_) {
    } on ApiClientException catch (e) {
      _showError(applyServerErrors(form, e));
      focusFirstError(form, 'firstName');
    } catch (e) {
      debugPrint('Spremanje profila nije uspjelo: $e');
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
