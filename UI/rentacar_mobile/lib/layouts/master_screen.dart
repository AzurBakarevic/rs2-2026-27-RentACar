import 'package:material_ui/material_ui.dart';

import '../screens/home_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/reservation_list_screen.dart';
import '../screens/vehicle_list_screen.dart';
import '../utils/app_theme.dart';

class _TabEntry {
  const _TabEntry(this.label, this.icon, this.builder);

  final String label;
  final IconData icon;
  final Widget Function() builder;
}

final List<_TabEntry> _tabs = [
  _TabEntry(HomeScreen.title, Icons.home_outlined, () => const HomeScreen()),
  _TabEntry(VehicleListScreen.title, Icons.directions_car_outlined, () => const VehicleListScreen()),
  _TabEntry(ReservationListScreen.title, Icons.calendar_month_outlined, () => const ReservationListScreen()),
  _TabEntry(ProfileScreen.title, Icons.person_outline, () => const ProfileScreen()),
];

class MasterScreen extends StatefulWidget {
  const MasterScreen({super.key});

  @override
  State<MasterScreen> createState() => _MasterScreenState();
}

class _MasterScreenState extends State<MasterScreen> {
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [for (final _ in _tabs) GlobalKey<NavigatorState>()];

  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          for (var i = 0; i < _tabs.length; i++)
            NavigatorPopHandler<Object?>(
              enabled: i == _selectedIndex,
              onPopWithResult: (_) => _navigatorKeys[i].currentState?.maybePop(),
              child: Navigator(
                key: _navigatorKeys[i],
                onGenerateRoute: (settings) => MaterialPageRoute(
                  settings: settings,
                  builder: (_) => _tabs[i].builder(),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _selectTab,
          destinations: [
            for (final tab in _tabs) NavigationDestination(icon: Icon(tab.icon), label: tab.label),
          ],
        ),
      ),
    );
  }

  void _selectTab(int index) {
    if (index == _selectedIndex) {
      _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
      return;
    }
    setState(() => _selectedIndex = index);
  }
}
