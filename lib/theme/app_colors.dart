import 'package:flutter/material.dart';

class AppColors {
  // --- PALETTE PRINCIPALE ---
  static const Color nuit = Color(0xFF1A1A2E);
  static const Color terracotta = Color(0xFFE07B39);
  static const Color sable = Color(0xFFF5ECD7);
  static const Color menthe = Color(0xFF4CAF7D);
  static const Color blanc = Color(0xFFFFFFFF);

  // Textes & Fonds
  static const Color textPrimary = nuit;
  static const Color backgroundLight = blanc;
  static const Color backgroundDark = nuit;
  static const Color cardLight = blanc;
  static const Color cardDark = Color(0xFF23233D); // Léger décalage du Nuit

  // Actions & États
  static const Color primaryAction = sable;
  static const Color callToAction = terracotta; // Boutons principaux, Prix
  static const Color successState = menthe; // Badges Vendu, Succès
}
