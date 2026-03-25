import 'package:flutter/material.dart';

// Color palette: "Leseecke" — warm, soft, inviting
class AppColors {
  static const background = Color(0xFFFFF8F0);     // Warm cream
  static const surface = Color(0xFFFFF1E6);         // Soft linen
  static const primary = Color(0xFFD4845A);         // Terracotta
  static const secondary = Color(0xFF8BA888);        // Sage green
  static const textDark = Color(0xFF3D2C22);         // Warm brown
  static const textLight = Color(0xFF8B7355);        // Cocoa
  static const error = Color(0xFFC4574B);            // Muted red
  static const activeWord = Color(0xFFF2C94C);       // Sunny yellow
  static const cardShadow = Color(0x1A3D2C22);       // Subtle warm shadow
  static const divider = Color(0xFFE8D5C4);          // Warm divider
}

final focusReadTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  scaffoldBackgroundColor: AppColors.background,
  colorScheme: ColorScheme.light(
    primary: AppColors.primary,
    onPrimary: Colors.white,
    secondary: AppColors.secondary,
    onSecondary: Colors.white,
    surface: AppColors.surface,
    onSurface: AppColors.textDark,
    error: AppColors.error,
    onError: Colors.white,
    primaryContainer: AppColors.surface,
    onPrimaryContainer: AppColors.primary,
  ),
  textTheme: ThemeData.light().textTheme.apply(fontFamily: 'Nunito').copyWith(
    displayLarge: const TextStyle(fontFamily: 'Quicksand', fontSize: 40, fontWeight: FontWeight.w700, color: AppColors.textDark),
    displayMedium: const TextStyle(fontFamily: 'Quicksand', fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.textDark),
    headlineLarge: const TextStyle(fontFamily: 'Quicksand', fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textDark),
    headlineMedium: const TextStyle(fontFamily: 'Quicksand', fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.textDark),
    headlineSmall: const TextStyle(fontFamily: 'Quicksand', fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textDark),
    titleLarge: const TextStyle(fontFamily: 'Quicksand', fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textDark),
    titleMedium: const TextStyle(fontFamily: 'Nunito', fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark),
    titleSmall: const TextStyle(fontFamily: 'Nunito', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark),
    bodyLarge: const TextStyle(fontFamily: 'Nunito', fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.textDark),
    bodyMedium: const TextStyle(fontFamily: 'Nunito', fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textDark),
    bodySmall: const TextStyle(fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textLight),
    labelLarge: const TextStyle(fontFamily: 'Nunito', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark),
  ),
  appBarTheme: const AppBarTheme(
    centerTitle: true,
    elevation: 0,
    backgroundColor: AppColors.background,
    foregroundColor: AppColors.textDark,
    titleTextStyle: TextStyle(
      fontFamily: 'Quicksand',
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: AppColors.textDark,
    ),
    iconTheme: IconThemeData(color: AppColors.textDark),
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    color: AppColors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
    shadowColor: AppColors.cardShadow,
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      minimumSize: const Size(48, 56),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      textStyle: const TextStyle(
        fontFamily: 'Nunito',
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primary,
      textStyle: const TextStyle(
        fontFamily: 'Nunito',
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
  iconButtonTheme: IconButtonThemeData(
    style: IconButton.styleFrom(
      foregroundColor: AppColors.textDark,
    ),
  ),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return AppColors.secondary;
      return AppColors.textLight;
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return AppColors.secondary.withValues(alpha: 0.3);
      return AppColors.divider;
    }),
  ),
  sliderTheme: const SliderThemeData(
    activeTrackColor: AppColors.primary,
    inactiveTrackColor: AppColors.divider,
    thumbColor: AppColors.primary,
    overlayColor: Color(0x1AD4845A),
    valueIndicatorColor: AppColors.primary,
    valueIndicatorTextStyle: TextStyle(
      fontFamily: 'Nunito',
      color: Colors.white,
      fontWeight: FontWeight.w600,
    ),
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: AppColors.background,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
    ),
    titleTextStyle: const TextStyle(
      fontFamily: 'Quicksand',
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: AppColors.textDark,
    ),
  ),
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: AppColors.background,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.divider),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.divider),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.primary, width: 2),
    ),
    labelStyle: const TextStyle(fontFamily: 'Nunito', color: AppColors.textLight),
  ),
  dividerColor: AppColors.divider,
);
