import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF070B14);
  static const Color surface = Color(0xFF0E1626);
  static const Color surfaceLight = Color(0xFF162238);
  static const Color surfaceElevated = Color(0xFF1E2E4A);

  static const Color primary = Color(0xFF243F7C); // Meiwa Brand Blue #243F7C
  static const Color primaryLight = Color(0xFF3B5FA8);
  static const Color primaryGlow = Color(0x99243F7C);
  static const Color cyanAccent = Color(0xFF38BDF8); // Sky blue accent
  static const Color liveRed = Color(0xFFFF2D55);
  static const Color liveRedGlow = Color(0x66FF2D55);
  static const Color goldAccent = Color(0xFFFFB300);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
  static const Color border = Color(0xFF1D2E4D);
  static const Color borderFocused = Color(0xFF3B5FA8);
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
