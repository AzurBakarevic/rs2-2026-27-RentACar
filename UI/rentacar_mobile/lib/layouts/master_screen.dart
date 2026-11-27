import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../providers/notification_provider.dart';
import '../providers/reservation_provider.dart';
import '../screens/home_screen.dart';
import '../screens/notification_list_screen.dart';
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
  _TabEntry(NotificationListScreen.title, Icons.notifications_outlined, () => const NotificationListScreen()),
  _TabEntry(ProfileScreen.title, Icons.person_outline, () => const ProfileScreen()),
];

class MasterScreen extends StatefulWidget {
  const MasterScreen({super.key});

  static void openTab(BuildContext context, String title) {
    final index = _tabs.indexWhere((tab) => tab.label == title);
    if (index >= 0) {
      context.findAncestorStateOfType<_MasterScreenState>()?._selectTab(index);
    }
  }

  @override
  State<MasterScreen> createState() => _MasterScreenState();
}

class _MasterScreenState extends State<MasterScreen> {
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [for (final _ in _tabs) GlobalKey<NavigatorState>()];

  late final NotificationProvider _notifications;
  late final ReservationProvider _reservations;
  late final AppLifecycleListener _lifecycleListener;

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _notifications = context.read<NotificationProvider>()
      ..clear()
      ..startPolling();
    _reservations = context.read<ReservationProvider>()..addListener(_notifications.refresh);
    _lifecycleListener = AppLifecycleListener(
      onShow: _notifications.startPolling,
      onHide: _notifications.stopPolling,
    );
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    _reservations.removeListener(_notifications.refresh);
    _notifications.clear();
    super.dispose();
  }

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
