import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF080C14);
  static const Color surface = Color(0xFF101726);
  static const Color surfaceLight = Color(0xFF1B2438);
  static const Color surfaceElevated = Color(0xFF243048);

  static const Color primary = Color(0xFF00E676); // Stadium Emerald Green
  static const Color primaryGlow = Color(0x6600E676);
  static const Color cyanAccent = Color(0xFF00E5FF);
  static const Color liveRed = Color(0xFFFF2D55);
  static const Color liveRedGlow = Color(0x66FF2D55);
  static const Color goldAccent = Color(0xFFFFB300);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9EAFC5);
  static const Color textMuted = Color(0xFF64748B);
  static const Color border = Color(0xFF1F2A40);
  static const Color borderFocused = Color(0xFF00E676);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.cyanAccent,
        surface: AppColors.surface,
        error: AppColors.liveRed,
        onPrimary: Colors.black,
        onSurface: AppColors.textPrimary,
      ),
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
        ),
        bodyMedium: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
    );
  }
}
