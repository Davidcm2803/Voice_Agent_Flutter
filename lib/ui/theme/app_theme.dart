import 'package:flutter/material.dart';
import 'package:voice_agent_flutter/ui/theme/app_colors.dart';

abstract final class AppTheme {
  static ThemeData get dark {
    const scheme = ColorScheme.dark(
      primary: AppColors.red,
      secondary: AppColors.blue,
      tertiary: AppColors.cyan,
      surface: AppColors.night,
      onPrimary: AppColors.paper,
      onSurface: AppColors.paper,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.ink,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        foregroundColor: AppColors.paper,
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
          fontStyle: FontStyle.italic,
          color: AppColors.paper,
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
          fontStyle: FontStyle.italic,
          color: AppColors.paper,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          height: 1.35,
          fontWeight: FontWeight.w600,
          color: AppColors.paper,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.8,
          color: AppColors.muted,
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.panel,
        contentTextStyle: TextStyle(color: AppColors.paper),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}