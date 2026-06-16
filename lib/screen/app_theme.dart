import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  /// THÈME CLAIR (Light Mode)
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: AppColors.sable,
      scaffoldBackgroundColor: AppColors.backgroundLight,

      // Palette sémantique Material 3
      colorScheme: const ColorScheme.light(
        primary: AppColors.sable,
        secondary: AppColors.callToAction,
        surface: AppColors.backgroundLight,
        error: Colors.redAccent,
        onPrimary: AppColors.nuit,
        onSecondary: AppColors.blanc,
        onSurface: AppColors.nuit,
      ),

      // Application Bar (Header)
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.backgroundLight,
        foregroundColor: AppColors.nuit,
        elevation: 0,
        centerTitle: true,
      ),

      // Typographie
      textTheme: const TextTheme(
        displayLarge: AppTextStyles.headerLarge,
        displayMedium: AppTextStyles.headerMedium,
        bodyLarge: AppTextStyles.body,
      ),

      // Boutons Call To Action (Terracotta)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.callToAction,
          foregroundColor: AppColors.blanc,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // Boutons secondaires (Bordure Sable)
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.nuit,
          side: const BorderSide(color: AppColors.primaryAction, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  /// THÈME SOMBRE (Dark Mode)
  static ThemeData get darkTheme {
    return lightTheme.copyWith(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.backgroundDark,

      colorScheme: const ColorScheme.dark(
        primary: AppColors.sable,
        secondary: AppColors.callToAction,
        surface: AppColors.backgroundDark,
        onPrimary: AppColors.nuit,
        onSecondary: AppColors.blanc,
        onSurface: AppColors.blanc,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.backgroundDark,
        foregroundColor: AppColors.blanc,
        elevation: 0,
      ),
    );
  }
}
