import 'package:material_ui/material_ui.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF4F46A5);
  static const Color background = Color(0xFFF4F6FA);
  static const Color card = Color(0xFFF8FAFC);
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
  static const Color rating = Color(0xFFE0A100);
  static const Color imagePlaceholder = Color(0xFFE9ECF4);
  static const Color imagePlaceholderIcon = Color(0xFF94A3B8);
}

ThemeData buildAppTheme() {
  final colorScheme = ColorScheme.fromSeed(seedColor: AppColors.primary).copyWith(
    primary: AppColors.primary,
    error: AppColors.error,
    surface: Colors.white,
  );

  final inputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: AppColors.border),
  );

  final buttonShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));

  return ThemeData(
    colorScheme: colorScheme,
    scaffoldBackgroundColor: Colors.white,
    inputDecorationTheme: InputDecorationTheme(
      border: inputBorder,
      enabledBorder: inputBorder,
      focusedBorder: inputBorder.copyWith(borderSide: const BorderSide(color: AppColors.primary, width: 2)),
      hintStyle: const TextStyle(color: AppColors.textMuted),
      helperMaxLines: 3,
      errorMaxLines: 3,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        shape: buttonShape,
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 52),
        shape: buttonShape,
        side: const BorderSide(color: AppColors.border),
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(minimumSize: const Size(0, 44), shape: buttonShape),
    ),
    chipTheme: ChipThemeData(
      showCheckmark: false,
      color: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? AppColors.primary : Colors.white,
      ),
      side: WidgetStateBorderSide.resolveWith(
        (states) => BorderSide(color: states.contains(WidgetState.selected) ? AppColors.primary : AppColors.border),
      ),
      labelStyle: TextStyle(
        fontSize: 15,
        color: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.selected) ? Colors.white : AppColors.textDark,
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      indicatorColor: Colors.transparent,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected) ? AppColors.primary : AppColors.textMuted,
          size: 26,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w700)
            : const TextStyle(color: AppColors.textMuted, fontSize: 13),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
    ),
    datePickerTheme: const DatePickerThemeData(backgroundColor: Colors.white, surfaceTintColor: Colors.transparent),
    timePickerTheme: const TimePickerThemeData(backgroundColor: Colors.white),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
