import 'package:flutter/material.dart';

class IconHelper {
  // Liste des icônes disponibles pour l'admin
  static final Map<String, IconData> icons = {
    'defaut': Icons.category_outlined,
    'smartphone': Icons.smartphone_outlined,
    'ordinateur': Icons.computer_outlined,
    'voiture': Icons.directions_car_outlined,
    'maison': Icons.home_outlined,
    'vetements': Icons.checkroom_outlined,
    'canapes': Icons.chair_outlined,
    'livre': Icons.menu_book_outlined,
    'sport': Icons.sports_soccer_outlined,
    'musique': Icons.music_note_outlined,
    'sante': Icons.health_and_safety_outlined,
    'jouet': Icons.toys_outlined,
    'outil': Icons.handyman_outlined,
  };

  static IconData getIcon(String? nomIcone) {
    return icons[nomIcone] ?? Icons.category_outlined;
  }
}