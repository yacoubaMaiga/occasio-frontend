import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  static const TextStyle headerLarge = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 28,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
  );

  static const TextStyle headerMedium = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 20,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle body = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );

  // Style spécifique pour les éléments de conversion (Terracotta)
  static const TextStyle priceBadge = TextStyle(
    color: AppColors.callToAction,
    fontSize: 18,
    fontWeight: FontWeight.w700,
  );

  // Permet d'adapter la couleur du texte facilement pour le Dark Mode
  static TextStyle withColor(TextStyle style, Color color) =>
      style.copyWith(color: color);
}
