import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../utils/api_client_exception.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/image_file_picker.dart';
import '../utils/session.dart';
import '../utils/utils_widgets.dart';
import '../widgets/form_page.dart';
import '../widgets/notice_box.dart';
import '../widgets/profile_avatar.dart';
import 'password_change_screen.dart';
import 'profile_edit_screen.dart';

enum _ImageAction { pick, remove }

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  static const String title = 'Profil';

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isImageSaving = false;

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>().profile;
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            children: [
              const TabTitle(ProfileScreen.title),
              const SizedBox(height: 20),
              if (profile == null) _buildMissingProfile() else ..._buildProfile(profile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMissingProfile() {
    return Column(
      children: [
        const Text('Podaci profila nisu učitani.', style: TextStyle(color: AppColors.textMuted, fontSize: 16)),
        const SizedBox(height: 12),
        OutlinedButton(onPressed: _refresh, child: const Text('Pokušaj ponovo')),
      ],
    );
  }

  List<Widget> _buildProfile(User profile) {
    return [
      _buildHeader(profile),
      const SizedBox(height: 28),
      const _SectionTitle('Lični podaci'),
      _InfoRow(icon: Icons.mail_outline, label: 'E-mail', value: profile.email),
      _InfoRow(icon: Icons.phone_outlined, label: 'Broj telefona', value: profile.phoneNumber),
      const SizedBox(height: 28),
      const _SectionTitle('Vozačka dozvola'),
      ..._buildDriverLicense(profile),
      const SizedBox(height: 28),
      _ActionTile(
        icon: Icons.edit_outlined,
        label: 'Uredi profil',
        onTap: () => _open(ProfileEditScreen(profile: profile)),
      ),
      const SizedBox(height: 12),
      _ActionTile(
        icon: Icons.lock_outline,
        label: 'Promijeni lozinku',
        onTap: () => _open(const PasswordChangeScreen()),
      ),
      const SizedBox(height: 28),
      OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: const BorderSide(color: AppColors.error),
        ),
        onPressed: _logout,
        icon: const Icon(Icons.logout),
        label: const Text('Odjavi se'),
      ),
    ];
  }

  Widget _buildHeader(User profile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: 'Slika profila',
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _isImageSaving ? null : () => _showImageOptions(profile),
              child: Stack(
                children: [
                  const ProfileAvatar(size: 80),
                  if (_isImageSaving)
                    const Positioned.fill(
                      child: ClipOval(
                        child: ColoredBox(
                          color: Colors.black38,
                          child: Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)),
                        ),
                      ),
                    ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.photo_camera_outlined, size: 15, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.fullName,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textDark),
                ),
                const SizedBox(height: 4),
                Text(profile.username, style: const TextStyle(fontSize: 15, color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDriverLicense(User profile) {
    final validUntil = profile.driverLicenseValidUntil;
    if (!profile.hasDriverLicense || validUntil == null) {
      return const [
        NoticeBox(
          message: 'Niste unijeli podatke o vozačkoj dozvoli. Bez njih nije moguće rezervisati vozilo.',
          type: NoticeType.warning,
          bottomSpacing: 0,
        ),
      ];
    }

    final isExpired = validUntil.isBefore(DateUtils.dateOnly(DateTime.now()));
    return [
      _InfoRow(icon: Icons.badge_outlined, label: 'Broj', value: profile.driverLicenseNumber!),
      _InfoRow(
        icon: Icons.event_outlined,
        label: 'Važi do',
        value: isExpired ? '${formatDate(validUntil)} (istekla)' : formatDate(validUntil),
        valueColor: isExpired ? AppColors.error : null,
      ),
      if (isExpired) ...[
        const SizedBox(height: 12),
        const NoticeBox(
          message: 'Vozačka dozvola je istekla. Unesite nove podatke da biste mogli rezervisati vozilo.',
          type: NoticeType.warning,
          bottomSpacing: 0,
        ),
      ],
    ];
  }

  void _open(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _refresh() async {
    try {
      await context.read<ProfileProvider>().load();
    } on UnauthorizedException catch (_) {
    } on ApiClientException catch (e) {
      if (mounted) {
        showSnack(context, e.message);
      }
    } catch (e) {
      debugPrint('Osvježavanje profila nije uspjelo: $e');
      if (mounted) {
        showSnack(context, unexpectedResponseError);
      }
    }
  }

  Future<void> _showImageOptions(User profile) async {
    final action = await showModalBottomSheet<_ImageAction>(
      context: context,
      useRootNavigator: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(profile.hasProfileImage ? 'Promijeni sliku' : 'Dodaj sliku'),
              subtitle: const Text(imageRequirements),
              onTap: () => Navigator.pop(sheetContext, _ImageAction.pick),
            ),
            if (profile.hasProfileImage)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.error),
                title: const Text('Ukloni sliku', style: TextStyle(color: AppColors.error)),
                onTap: () => Navigator.pop(sheetContext, _ImageAction.remove),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    switch (action) {
      case _ImageAction.pick:
        await _pickImage();
      case _ImageAction.remove:
        await _removeImage();
      case null:
        return;
    }
  }

  Future<void> _pickImage() async {
    final provider = context.read<ProfileProvider>();
    final result = await pickImageFile('Odaberite sliku profila');
    if (result == null || !mounted) {
      return;
    }
    final image = result.image;
    if (image == null) {
      showSnack(context, result.error!);
      return;
    }
    await _saveImage(() => provider.updateImage(image), 'Slika profila je sačuvana.');
  }

  Future<void> _removeImage() async {
    final provider = context.read<ProfileProvider>();
    final confirmed = await confirmDialog(
      context,
      title: 'Uklanjanje slike',
      content: 'Da li želite ukloniti sliku profila?',
      confirmLabel: 'Ukloni',
      destructive: true,
    );
    if (confirmed && mounted) {
      await _saveImage(provider.deleteImage, 'Slika profila je uklonjena.');
    }
  }

  Future<void> _saveImage(Future<void> Function() save, String successMessage) async {
    setState(() => _isImageSaving = true);
    try {
      await save();
      if (mounted) {
        showSnack(context, successMessage);
      }
    } on UnauthorizedException catch (_) {
    } on ApiClientException catch (e) {
      if (mounted) {
        showSnack(context, e.message);
      }
    } catch (e) {
      debugPrint('Spremanje slike profila nije uspjelo: $e');
      if (mounted) {
        showSnack(context, unexpectedResponseError);
      }
    } finally {
      if (mounted) {
        setState(() => _isImageSaving = false);
      }
    }
  }

  Future<void> _logout() async {
    final confirmed = await confirmDialog(
      context,
      title: 'Odjava',
      content: 'Da li se želite odjaviti?',
      confirmLabel: 'Odjavi se',
    );
    if (!confirmed || !mounted) {
      return;
    }

    final navigator = Navigator.of(context, rootNavigator: true);
    await context.read<AuthProvider>().logout();
    openLogin(navigator);
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark)),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value, this.valueColor});

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textMuted)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontSize: 16, color: valueColor ?? AppColors.textDark)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      tileColor: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
    );
  }
}
