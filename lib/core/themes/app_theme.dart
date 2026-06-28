import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'app_colors.dart';

/// Extension to get theme-aware colors on any BuildContext.
/// Makes it easy to use the right color in both light and dark modes.
extension ThemeColors on BuildContext {
  Color get surfaceColor =>
      brightness == Brightness.light ? Colors.white : AppColors.darkCardBg;

  Color get scaffoldBgColor =>
      Theme.of(this).scaffoldBackgroundColor;

  Color get surfaceContainerColor =>
      brightness == Brightness.light
          ? const Color(0xFFF7FAFC)
          : AppColors.darkSurface;

  Color get textOnSurfaceColor =>
      brightness == Brightness.light
          ? AppColors.textDark
          : AppColors.textMain;

  Color get textMutedColor =>
      brightness == Brightness.light
          ? AppColors.textGrey
          : AppColors.textMuted;

  Color get borderColor =>
      brightness == Brightness.light
          ? const Color(0xFFE2E8F0)
          : AppColors.darkBorder;

  Color get inputBgColor =>
      brightness == Brightness.light
          ? AppColors.inputBackground
          : AppColors.darkCardBg;

  Brightness get brightness => Theme.of(this).brightness;

  bool get isDark => brightness == Brightness.dark;
}

class AppTheme {
  static ThemeData light = ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.indigo,
    scaffoldBackgroundColor: AppColors.lightBackground,
    fontFamilyFallback: const [
      'Noto Color Emoji',
      'Apple Color Emoji',
      'Segoe UI Emoji',
      'Roboto',
    ],
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: AppColors.textDark,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: AppColors.primaryPurple,
      unselectedItemColor: AppColors.textGrey,
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFFE2E8F0),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.inputBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide.none,
      ),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: Colors.white,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.primaryPurple;
        return AppColors.textGrey;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.primaryPurple.withValues(alpha: 0.3);
        return AppColors.textGrey.withValues(alpha: 0.2);
      }),
    ),
    colorScheme: ColorScheme.light(
      primary: AppColors.primaryPurple,
      secondary: AppColors.accentBlue,
      surface: Colors.white,
      onSurface: AppColors.textDark,
    ),
  );

  static ThemeData dark = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.indigo,
    scaffoldBackgroundColor: AppColors.darkBackground,
    fontFamilyFallback: const [
      'Noto Color Emoji',
      'Apple Color Emoji',
      'Segoe UI Emoji',
      'Roboto',
    ],
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.darkSurface,
      foregroundColor: AppColors.textMain,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: AppColors.darkCardBg,
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        side: const BorderSide(color: AppColors.darkBorder),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.darkSurface,
      selectedItemColor: AppColors.primaryPurple,
      unselectedItemColor: AppColors.textMuted,
      type: BottomNavigationBarType.fixed,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.darkBorder,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkCardBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide.none,
      ),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: AppColors.darkCardBg,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.primaryPurple;
        return AppColors.textMuted;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.primaryPurple.withValues(alpha: 0.3);
        return AppColors.textMuted.withValues(alpha: 0.2);
      }),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.darkSurface,
      labelStyle: TextStyle(color: AppColors.textMuted, fontSize: 12.sp),
      side: const BorderSide(color: AppColors.darkBorder),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
      ),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: AppColors.textMain),
      bodyMedium: TextStyle(color: AppColors.textMain),
      bodySmall: TextStyle(color: AppColors.textMuted),
      titleLarge: TextStyle(color: AppColors.textMain),
      titleMedium: TextStyle(color: AppColors.textMain),
      titleSmall: TextStyle(color: AppColors.textMuted),
    ),
    colorScheme: ColorScheme.dark(
      primary: AppColors.primaryPurple,
      secondary: AppColors.accentBlue,
      surface: AppColors.darkCardBg,
      onSurface: AppColors.textMain,
      onPrimary: AppColors.textMain,
      onSecondary: AppColors.textMain,
      outline: AppColors.darkBorder,
    ),
  );
}
