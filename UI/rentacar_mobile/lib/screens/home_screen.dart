import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../providers/profile_provider.dart';
import '../utils/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const String title = 'Početna';

  @override
  Widget build(BuildContext context) {
    final firstName = context.watch<ProfileProvider>().profile?.firstName;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          children: [
            Text(
              firstName == null ? 'Zdravo!' : 'Zdravo, $firstName!',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textDark),
            ),
            const SizedBox(height: 8),
            const Text(
              'Spremni za sljedeće putovanje?',
              style: TextStyle(fontSize: 17, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
