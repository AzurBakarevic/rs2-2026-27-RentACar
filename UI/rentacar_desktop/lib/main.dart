import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/brand_provider.dart';
import 'providers/category_provider.dart';
import 'providers/fuel_type_provider.dart';
import 'providers/transmission_type_provider.dart';
import 'providers/vehicle_model_provider.dart';
import 'screens/login_screen.dart';
import 'utils/app_theme.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  // 401 s bilo kojeg ekrana (istekao ili poništen token) vraća na prijavu (upute A.2).
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
      home: const LoginScreen(),
    );
  }
}
