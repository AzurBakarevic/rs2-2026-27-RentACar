import 'package:material_ui/material_ui.dart';

// Boje iz skica u prijavi.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF4F46A5);
  static const Color background = Color(0xFFF4F6FA);
  static const Color border = Color(0xFFD7DDE7);
  static const Color textDark = Color(0xFF1F2937);
  static const Color textMuted = Color(0xFF475569);
  static const Color avatarBackground = Color(0xFFECEBFA);
  static const Color error = Color(0xFFB42318);
  static const Color errorBackground = Color(0xFFFDECEC);
  static const Color infoBackground = Color(0xFFECEBFA);
  static const Color success = Color(0xFF15803D);
  static const Color successBackground = Color(0xFFE6F6EC);
  static const Color warning = Color(0xFF8A5B00);
  static const Color warningBackground = Color(0xFFFDF1D0);
  static const Color confirmed = Color(0xFF1C5FA8);
  static const Color confirmedBackground = Color(0xFFE2EEFC);
}

ThemeData buildAppTheme() {
  final colorScheme = ColorScheme.fromSeed(seedColor: AppColors.primary).copyWith(
    primary: AppColors.primary,
    error: AppColors.error,
    surface: Colors.white,
  );

  final inputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: const BorderSide(color: AppColors.border),
  );

  final buttonShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(8));

  return ThemeData(
    colorScheme: colorScheme,
    scaffoldBackgroundColor: Colors.white,
    inputDecorationTheme: InputDecorationTheme(
      border: inputBorder,
      enabledBorder: inputBorder,
      focusedBorder: inputBorder.copyWith(borderSide: const BorderSide(color: AppColors.primary, width: 2)),
      hintStyle: const TextStyle(color: AppColors.textMuted),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        shape: buttonShape,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 48),
        shape: buttonShape,
        side: const BorderSide(color: AppColors.border),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(minimumSize: const Size(0, 44), shape: buttonShape),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: AppColors.primary,
      unselectedLabelColor: AppColors.textMuted,
      indicatorColor: AppColors.primary,
      labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 16),
      dividerColor: AppColors.border,
    ),
    // Bijele površine kao na skicama (Material 3 ih inače boji nijansom primarne boje).
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    popupMenuTheme: const PopupMenuThemeData(color: Colors.white, surfaceTintColor: Colors.transparent),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating, width: 420),
  );
}
