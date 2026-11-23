import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/brand_provider.dart';
import 'providers/category_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/equipment_provider.dart';
import 'providers/fuel_type_provider.dart';
import 'providers/reservation_provider.dart';
import 'providers/seasonal_price_provider.dart';
import 'providers/transmission_type_provider.dart';
import 'providers/vehicle_maintenance_provider.dart';
import 'providers/vehicle_model_provider.dart';
import 'providers/vehicle_provider.dart';
import 'screens/login_screen.dart';
import 'utils/app_theme.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  AuthProvider.onSessionExpired = (message) {
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LoginScreen(message: message)),
      (route) => false,
    );
  };

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BrandProvider()),
        ChangeNotifierProvider(create: (_) => VehicleModelProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => FuelTypeProvider()),
        ChangeNotifierProvider(create: (_) => TransmissionTypeProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => VehicleProvider()),
        ChangeNotifierProvider(create: (_) => EquipmentProvider()),
        ChangeNotifierProvider(create: (_) => VehicleMaintenanceProvider()),
        ChangeNotifierProvider(create: (_) => SeasonalPriceProvider()),
        ChangeNotifierProvider(create: (_) => ReservationProvider()),
      ],
      child: const RentACarApp(),
    ),
  );
}

class RentACarApp extends StatelessWidget {
  const RentACarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RentACar',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: buildAppTheme(),
      locale: const Locale('bs'),
      supportedLocales: const [Locale('bs')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const LoginScreen(),
    );
  }
}
