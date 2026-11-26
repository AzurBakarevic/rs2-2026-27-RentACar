import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../layouts/master_screen.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../screens/login_screen.dart';

Future<void> signIn(BuildContext context, String username, String password) async {
  final auth = context.read<AuthProvider>();
  final profile = context.read<ProfileProvider>();

  await auth.login(username, password);
  try {
    await profile.load();
  } catch (_) {
    await auth.logout();
    rethrow;
  }
}

void openHome(BuildContext context) {
  Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
    PageRouteBuilder(pageBuilder: (_, _, _) => const MasterScreen(), transitionDuration: Duration.zero),
    (route) => false,
  );
}

void openLogin(NavigatorState navigator, {String? message}) {
  navigator.pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => LoginScreen(message: message)),
    (route) => false,
  );
}
