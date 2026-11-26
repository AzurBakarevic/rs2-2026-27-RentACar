import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/category_provider.dart';
import 'providers/fuel_type_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/review_provider.dart';
import 'providers/transmission_type_provider.dart';
import 'providers/vehicle_provider.dart';
import 'screens/login_screen.dart';
import 'utils/app_theme.dart';
import 'utils/session.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  AuthProvider.onSessionExpired = (message) {
    final navigator = navigatorKey.currentState;
    if (navigator != null) {
      openLogin(navigator, message: message);
    }
  };

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => VehicleProvider()),
        ChangeNotifierProvider(create: (_) => ReviewProvider()),
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
      locale: const Locale('bs'),
      supportedLocales: const [Locale('bs')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const LoginScreen(),
    );
  }
}
