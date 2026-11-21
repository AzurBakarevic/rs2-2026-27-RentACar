import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../screens/dashboard_screen.dart';
import '../screens/equipment_screen.dart';
import '../screens/login_screen.dart';
import '../screens/reference_data_screen.dart';
import '../screens/seasonal_price_screen.dart';
import '../screens/vehicle_list_screen.dart';
import '../screens/vehicle_maintenance_screen.dart';
import '../utils/app_theme.dart';
import '../utils/utils_widgets.dart';

class _MenuEntry {
  const _MenuEntry(this.label, this.builder);

  final String label;
  final Widget Function() builder;
}

// Stavke se dodaju redom kako ekrani budu gotovi (redoslijed kao na skicama).
final List<_MenuEntry> _menuEntries = [
  _MenuEntry(DashboardScreen.title, () => const DashboardScreen()),
  _MenuEntry(VehicleListScreen.title, () => const VehicleListScreen()),
  _MenuEntry(EquipmentScreen.title, () => const EquipmentScreen()),
  _MenuEntry(VehicleMaintenanceScreen.title, () => const VehicleMaintenanceScreen()),
  _MenuEntry(SeasonalPriceScreen.title, () => const SeasonalPriceScreen()),
  _MenuEntry(ReferenceDataScreen.title, () => const ReferenceDataScreen()),
];

/// Početni ekran nakon prijave (prijava: Dashboard).
Widget buildHomeScreen() => _menuEntries.first.builder();

/// Okvir svih ekrana: meni lijevo, naslov i prijavljeni korisnik gore.
class MasterScreen extends StatelessWidget {
  const MasterScreen({super.key, required this.title, required this.child, String? menuLabel})
      : menuLabel = menuLabel ?? title;

  final String title;
  final Widget child;

  /// Stavka menija koja je označena (detalji vozila npr. pripadaju stavci „Vozila”).
  final String menuLabel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSidebar(context),
          const VerticalDivider(width: 1, color: AppColors.border),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTopBar(context),
                const Divider(height: 1, color: AppColors.border),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 280,
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(40, 32, 32, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.directions_car_outlined, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 16),
              const Text(
                'RentACar',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.textDark),
              ),
            ],
          ),
          const SizedBox(height: 40),
          Expanded(
            child: ListView(
              children: [
                for (final entry in _menuEntries) _buildMenuItem(context, entry),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, _MenuEntry entry) {
    final selected = entry.label == menuLabel;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: selected
              ? null
              : () => Navigator.of(context).pushAndRemoveUntil(
                    PageRouteBuilder(
                      pageBuilder: (_, _, _) => entry.builder(),
                      transitionDuration: Duration.zero,
                      reverseTransitionDuration: Duration.zero,
                    ),
                    (route) => false,
                  ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: Text(
              entry.label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? Colors.white : AppColors.textDark,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      height: 96,
      padding: const EdgeInsets.symmetric(horizontal: 64),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.textDark),
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Korisnički meni',
            position: PopupMenuPosition.under,
            onSelected: (value) {
              if (value == 'logout') {
                _logout(context);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'logout',
                child: ListTile(leading: Icon(Icons.logout), title: Text('Odjava'), contentPadding: EdgeInsets.zero),
              ),
            ],
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.avatarBackground,
                  child: Icon(Icons.person_outline, color: AppColors.primary),
                ),
                const SizedBox(width: 16),
                Text(
                  AuthProvider.username ?? '',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textDark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await confirmDialog(
      context,
      title: 'Odjava',
      content: 'Da li se želite odjaviti?',
      confirmLabel: 'Odjavi se',
    );
    if (!confirmed || !context.mounted) {
      return;
    }

    final navigator = Navigator.of(context);
    await context.read<AuthProvider>().logout();
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }
}
