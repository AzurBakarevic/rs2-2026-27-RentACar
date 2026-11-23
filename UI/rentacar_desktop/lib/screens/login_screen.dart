import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../layouts/master_screen.dart';
import '../providers/auth_provider.dart';
import '../utils/api_client_exception.dart';
import '../utils/app_theme.dart';
import '../utils/form_errors.dart';
import '../utils/utils_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.message});

  final String? message;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Card(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: _buildForm(),
              ),
            ),
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
            'Prijava za administratore',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: AppColors.textMuted),
          ),
          const SizedBox(height: 32),
          _buildNotice(),
          FormBuilderTextField(
            name: 'username',
            autofocus: true,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Korisničko ime', prefixIcon: Icon(Icons.person_outline)),
            validator: requiredText('Unesite korisničko ime.'),
          ),
          const SizedBox(height: 20),
          FormBuilderTextField(
            name: 'password',
            obscureText: _obscurePassword,
            onSubmitted: (_) => _login(),
            decoration: InputDecoration(
              labelText: 'Lozinka',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                tooltip: _obscurePassword ? 'Prikaži lozinku' : 'Sakrij lozinku',
                icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (value) => (value ?? '').isEmpty ? 'Unesite lozinku.' : null,
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: _isLoading ? null : _login,
            child: _isLoading
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                : const Text('Prijava'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotice() {
    final text = _error ?? widget.message;
    if (text == null) {
      return const SizedBox.shrink();
    }
    final isError = _error != null;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isError ? AppColors.errorBackground : AppColors.infoBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: TextStyle(color: isError ? AppColors.error : AppColors.textDark, fontSize: 15)),
    );
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
      await context.read<AuthProvider>().login(
            (form.value['username'] as String).trim(),
            form.value['password'] as String,
          );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (_, _, _) => buildHomeScreen(),
          transitionDuration: Duration.zero,
        ),
        (route) => false,
      );
    } on ApiClientException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _error = applyServerErrors(form, e);
      });
      focusFirstError(form, 'password');
    }
  }
}
