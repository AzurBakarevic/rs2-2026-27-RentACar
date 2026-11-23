import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../layouts/master_screen.dart';
import '../models/role.dart';
import '../models/search_result.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../providers/role_provider.dart';
import '../providers/user_provider.dart';
import '../utils/api_client_exception.dart';
import '../utils/app_theme.dart';
import '../utils/form_errors.dart';
import '../utils/form_validators.dart';
import '../utils/formatters.dart';
import '../utils/image_file_picker.dart';
import '../utils/utils_widgets.dart';
import '../widgets/form_close_button.dart';
import '../widgets/user_avatar.dart';
import 'reservation_list_screen.dart';
import 'user_list_screen.dart';

class UserDetailsScreen extends StatefulWidget {
  const UserDetailsScreen({super.key, this.user});

  final User? user;

  @override
  State<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  static const int _passwordMinLength = 8;
  static const int _passwordMaxLength = 100;
  static const int _emailMaxLength = 100;

  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+$');
  static final RegExp _phonePattern = RegExp(r'^\+?[0-9][0-9 /-]{5,28}$');
  static final RegExp _usernamePattern = RegExp(r'^[a-zA-Z0-9._-]+$');

  final _formKey = GlobalKey<FormBuilderState>();

  User? _user;

  bool _wasSaved = false;

  List<DropdownMenuItem<int>> _roles = [];

  bool _isLoading = true;
  String? _loadError;
  bool _isSaving = false;
  String? _error;

  PickedImage? _image;
  String? _imageError;

  bool get _isNew => _user == null;

  bool get _isOwnAccount => _user != null && _user!.id == AuthProvider.userId;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    final userId = _user?.id;
    try {
      final results = await Future.wait<Object>([
        context.read<RoleProvider>().get(filter: {'pageSize': 100}),
        if (userId != null) context.read<UserProvider>().getById(userId),
      ]);
      if (!mounted) {
        return;
      }
      setState(() {
        if (userId != null) {
          _user = results[1] as User;
        }
        _roles = _toItems(results[0] as SearchResult<Role>, _user);
        _isLoading = false;
      });
    } on UnauthorizedException catch (_) {
    } on ApiClientException catch (e) {
      _showLoadError(e.message);
    } catch (e) {
      debugPrint('Učitavanje korisnika nije uspjelo: $e');
      _showLoadError('Odgovor servera nije moguće pročitati.');
    }
  }

  void _showLoadError(String message) {
    if (mounted) {
      setState(() {
        _loadError = message;
        _isLoading = false;
      });
    }
  }

  static List<DropdownMenuItem<int>> _toItems(SearchResult<Role> result, User? user) {
    final items = [
      for (final role in result.items ?? <Role>[]) DropdownMenuItem<int>(value: role.id, child: Text(role.name)),
    ];
    if (user != null && !items.any((item) => item.value == user.roleId)) {
      items.add(DropdownMenuItem<int>(value: user.roleId, child: Text(user.roleName)));
    }
    return items;
  }

  Future<void> _refreshUser() async {
    final user = _user;
    if (user == null) {
      return;
    }
    try {
      final fresh = await context.read<UserProvider>().getById(user.id);
      if (mounted) {
        setState(() => _user = fresh);
      }
    } on UnauthorizedException catch (_) {
    } on ApiClientException catch (e) {
      debugPrint('Osvježavanje korisnika nije uspjelo: $e');
    }
  }

  void _close() => Navigator.pop(context, _wasSaved);

  @override
  Widget build(BuildContext context) {
    return MasterScreen(
      title: _isNew ? 'Novi korisnik' : 'Izmjena korisnika',
      menuLabel: UserListScreen.title,
      onBack: _close,
      navigationBlockedReason: _isSaving ? savingInProgressReason : null,
      child: Stack(
        children: [
          Positioned.fill(child: _buildBody()),
          Positioned(top: 8, right: 16, child: FormCloseButton(isSaving: _isSaving, onClose: _close)),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_loadError!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.error)),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _load, child: const Text('Pokušaj ponovo')),
          ],
        ),
      );
    }

    final user = _user;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(64, 32, 64, 32),
      child: FormBuilder(
        key: _formKey,
        initialValue: {
          'firstName': user?.firstName ?? '',
          'lastName': user?.lastName ?? '',
          'email': user?.email ?? '',
          'phoneNumber': user?.phoneNumber ?? '',
          'username': user?.username ?? '',
          'roleId': user?.roleId,
          'driverLicenseNumber': user?.driverLicenseNumber ?? '',
          'driverLicenseValidUntil': user?.driverLicenseValidUntil,
          'password': '',
          'passwordConfirm': '',
          'isActive': user?.isActive ?? true,
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildError(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildFields()),
                const SizedBox(width: 48),
                SizedBox(width: 320, child: _buildSidePanel()),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: _isSaving ? null : _close,
                  child: const Text('Odustani'),
                ),
                const SizedBox(width: 16),
                FilledButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5))
                      : const Text('Sačuvaj'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _row(
          _textField(
            name: 'firstName',
            label: 'Ime',
            validator: requiredText('Ime je obavezno.', maxLength: 50, maxLengthMessage: 'Ime može imati najviše 50 znakova.'),
          ),
          _textField(
            name: 'lastName',
            label: 'Prezime',
            validator: requiredText(
              'Prezime je obavezno.',
              maxLength: 50,
              maxLengthMessage: 'Prezime može imati najviše 50 znakova.',
            ),
          ),
        ),
        _row(
          _textField(name: 'email', label: 'E-mail', validator: _validateEmail),
          _textField(name: 'phoneNumber', label: 'Broj telefona', hint: 'npr. 061 111 222', validator: _validatePhone),
        ),
        _row(
          _textField(name: 'username', label: 'Korisničko ime', validator: _validateUsername),
          FormBuilderDropdown<int>(
            name: 'roleId',
            enabled: !_isOwnAccount,
            decoration: const InputDecoration(labelText: 'Uloga'),
            dropdownColor: Colors.white,
            borderRadius: BorderRadius.circular(8),
            iconEnabledColor: AppColors.textMuted,
            items: _roles,
            validator: requiredValue('Uloga je obavezna.'),
          ),
        ),
        _row(
          _textField(
            name: 'driverLicenseNumber',
            label: 'Broj vozačke dozvole',
            validator: _validateDriverLicenseNumber,
            emptyAsNull: true,
          ),
          FormBuilderDateTimePicker(
            name: 'driverLicenseValidUntil',
            inputType: InputType.date,
            format: DateFormat('dd.MM.yyyy'),
            decoration: const InputDecoration(
              labelText: 'Vozačka dozvola važi do',
              suffixIcon: Icon(Icons.calendar_today_outlined),
            ),
            validator: _validateDriverLicenseValidUntil,
            valueTransformer: (value) => value == null ? null : toApiDate(value),
          ),
        ),
        _row(
          _textField(
            name: 'password',
            label: _isNew ? 'Lozinka' : 'Nova lozinka',
            helper: _isNew ? null : 'Ostavite prazno ako ne mijenjate lozinku.',
            obscureText: true,
            validator: _validatePassword,
            emptyAsNull: true,
          ),
          _textField(
            name: 'passwordConfirm',
            label: _isNew ? 'Potvrda lozinke' : 'Potvrda nove lozinke',
            obscureText: true,
            validator: _validatePasswordConfirm,
            emptyAsNull: true,
          ),
        ),
        FormBuilderSwitch(
          name: 'isActive',
          enabled: !_isOwnAccount,
          title: const Text('Aktivan (može se prijaviti u aplikaciju)'),
          decoration: plainFieldDecoration,
        ),
      ],
    );
  }

  Widget _row(Widget left, Widget right) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: left),
          const SizedBox(width: 24),
          Expanded(child: right),
        ],
      ),
    );
  }

  Widget _textField({
    required String name,
    required String label,
    required String? Function(String?) validator,
    String? hint,
    String? helper,
    bool obscureText = false,
    bool emptyAsNull = false,
  }) {
    return FormBuilderTextField(
      name: name,
      decoration: InputDecoration(labelText: label, hintText: hint, helperText: helper, helperMaxLines: 2),
      obscureText: obscureText,
      validator: validator,
      valueTransformer: (value) {
        final text = obscureText ? (value ?? '') : (value?.trim() ?? '');
        return emptyAsNull && text.isEmpty ? null : text;
      },
    );
  }

  String _fieldText(String name) => (_formKey.currentState?.fields[name]?.value as String?)?.trim() ?? '';

  String? _validateEmail(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'E-mail je obavezan.';
    }
    if (!_emailPattern.hasMatch(text)) {
      return 'E-mail nije ispravnog formata.';
    }
    return text.length > _emailMaxLength ? 'E-mail može imati najviše $_emailMaxLength znakova.' : null;
  }

  String? _validatePhone(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Broj telefona je obavezan.';
    }
    return _phonePattern.hasMatch(text) ? null : 'Broj telefona nije ispravnog formata.';
  }

  String? _validateUsername(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Korisničko ime je obavezno.';
    }
    if (text.length < 3 || text.length > 50) {
      return 'Korisničko ime mora imati između 3 i 50 znakova.';
    }
    return _usernamePattern.hasMatch(text)
        ? null
        : 'Korisničko ime smije sadržavati samo slova bez kvačica, brojeve, tačku, crticu i donju crtu.';
  }

  String? _validateDriverLicenseNumber(String? value) {
    final text = value?.trim() ?? '';
    if (text.length > 30) {
      return 'Broj vozačke dozvole može imati najviše 30 znakova.';
    }
    final validUntil = _formKey.currentState?.fields['driverLicenseValidUntil']?.value;
    return text.isEmpty && validUntil != null ? 'Unesite broj vozačke dozvole.' : null;
  }

  String? _validateDriverLicenseValidUntil(DateTime? value) {
    return value == null && _fieldText('driverLicenseNumber').isNotEmpty
        ? 'Unesite datum do kojeg važi vozačka dozvola.'
        : null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    final confirm = _formKey.currentState?.fields['passwordConfirm']?.value as String? ?? '';
    if (password.isEmpty) {
      return _isNew || confirm.isNotEmpty ? 'Lozinka je obavezna.' : null;
    }
    return password.length < _passwordMinLength || password.length > _passwordMaxLength
        ? 'Lozinka mora imati između $_passwordMinLength i $_passwordMaxLength znakova.'
        : null;
  }

  String? _validatePasswordConfirm(String? value) {
    final password = _formKey.currentState?.fields['password']?.value as String? ?? '';
    return (value ?? '') == password ? null : 'Lozinke se ne podudaraju.';
  }

  Widget _buildSidePanel() {
    final user = _user;
    final Widget preview;
    if (_image != null) {
      preview = ClipOval(
        child: SizedBox(
          width: 160,
          height: 160,
          child: Image.memory(
            _image!.bytes,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const UserAvatar(userId: 0, hasImage: false, size: 160),
          ),
        ),
      );
    } else {
      preview = UserAvatar(userId: user?.id ?? 0, hasImage: user?.hasProfileImage ?? false, size: 160);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Slika profila', style: _panelTitleStyle),
        const SizedBox(height: 12),
        Center(child: preview),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _isSaving ? null : _pickImage,
          icon: const Icon(Icons.upload_outlined),
          label: Text(_image != null || (user?.hasProfileImage ?? false) ? 'Promijeni sliku' : 'Odaberi sliku'),
        ),
        const SizedBox(height: 8),
        Text(
          _image == null ? imageRequirements : 'Odabrano: ${_image!.name} (sprema se uz korisnika)',
          style: const TextStyle(color: AppColors.textMuted),
        ),
        if (_imageError != null) ...[
          const SizedBox(height: 8),
          Text(_imageError!, style: const TextStyle(color: AppColors.error)),
        ],
        if (user != null) ...[
          const SizedBox(height: 32),
          const Text('Podaci o nalogu', style: _panelTitleStyle),
          const SizedBox(height: 12),
          _infoRow('Kreiran', formatDate(user.createdAt)),
          _infoRow('Aktivne rezervacije', '${user.activeReservationCount}'),
          if (user.activeReservationCount > 0) ...[
            const SizedBox(height: 4),
            OutlinedButton.icon(
              onPressed: _isSaving ? null : _openActiveReservations,
              icon: const Icon(Icons.event_note_outlined),
              label: const Text('Prikaži aktivne rezervacije'),
            ),
          ],
          if (_isOwnAccount || user.deleteBlockedReason != null) ...[
            const SizedBox(height: 12),
            Text(
              _isOwnAccount
                  ? 'Ovo je vaš nalog: ne možete mu promijeniti ulogu, deaktivirati ga niti obrisati.'
                  : user.deleteBlockedReason!,
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ],
        ],
      ],
    );
  }

  static const TextStyle _panelTitleStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
  );

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: AppColors.textMuted))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark)),
        ],
      ),
    );
  }

  Widget _buildError() {
    if (_error == null) {
      return const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.errorBackground, borderRadius: BorderRadius.circular(8)),
      child: Text(_error!, style: const TextStyle(color: AppColors.error)),
    );
  }

  Future<void> _pickImage() async {
    final result = await pickImageFile('Odaberite sliku profila');
    if (result == null || !mounted) {
      return;
    }
    setState(() {
      _image = result.image ?? _image;
      _imageError = result.error;
    });
  }

  Future<void> _openActiveReservations() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => ReservationListScreen(activeOfUser: _user)),
    );
    if (mounted) {
      await _refreshUser();
    }
  }

  Future<bool> _confirmDeactivation(Map<String, dynamic> values) async {
    final user = _user;
    if (user == null || !user.isActive || values['isActive'] != false || user.activeReservationCount == 0) {
      return true;
    }
    final count = user.activeReservationCount;
    final reservations = pluralBs(count, 'aktivnu rezervaciju', 'aktivne rezervacije', 'aktivnih rezervacija');
    return confirmDialog(
      context,
      title: 'Deaktivacija korisnika',
      content: 'Korisnik ima $count $reservations. Nakon deaktivacije se neće moći '
          'prijaviti, a rezervacije ostaju aktivne. Da li želite nastaviti?',
      confirmLabel: 'Deaktiviraj',
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

    final values = Map<String, dynamic>.from(form.value);
    if (!await _confirmDeactivation(values) || !mounted) {
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    final provider = context.read<UserProvider>();
    try {
      final current = _user;
      _user = current == null ? await provider.insert(values) : await provider.update(current.id, values);
      _wasSaved = true;
    } on UnauthorizedException {
      return;
    } on ApiClientException catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _error = applyServerErrors(form, e);
        });
        focusFirstError(form, 'firstName');
      }
      return;
    } catch (e) {
      debugPrint('Spremanje korisnika nije uspjelo: $e');
      if (mounted) {
        setState(() {
          _isSaving = false;
          _error = unexpectedSaveError;
        });
      }
      return;
    }

    final image = _image;
    if (image != null) {
      try {
        await provider.updateImage(_user!.id, image.bytes, fileName: image.name, contentType: image.contentType);
        PaintingBinding.instance.imageCache
          ..clear()
          ..clearLiveImages();
      } on UnauthorizedException {
        return;
      } on ApiClientException catch (e) {
        _showImageSaveError(e.message);
        return;
      } catch (e) {
        debugPrint('Spremanje slike nije uspjelo: $e');
        _showImageSaveError('neočekivana greška.');
        return;
      }
    }

    if (mounted) {
      closeForm(context, saved: true);
    }
  }

  void _showImageSaveError(String message) {
    if (mounted) {
      setState(() {
        _isSaving = false;
        _error = 'Podaci korisnika su sačuvani, ali slika nije: $message';
      });
    }
  }
}
