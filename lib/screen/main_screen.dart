import 'package:flutter/material.dart';
import 'package:occasio/screen/app_colors.dart';
import 'package:occasio/screen/home_screen.dart'; // Ton écran d'accueil actuel

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // L'index de l'onglet actuellement sélectionné (0 = Accueil par défaut)
  int _selectedIndex = 0;

  // La liste des écrans qui vont s'afficher quand on clique sur les onglets
  final List<Widget> _screens = [
    const HomeScreen(),
    const Center(child: Text('Recherche (Bientôt)')), // Index 1 : Placeholder
    const Center(child: Text('Publier une annonce')), // Index 2 : Placeholder
    const Center(child: Text('Messages (Bientôt)')), // Index 3 : Placeholder
    const Center(child: Text('Mon Profil')), // Index 4 : Placeholder
  ];

  // Fonction déclenchée quand on touche un icône en bas
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // On affiche l'écran correspondant à l'index sélectionné
      body: _screens[_selectedIndex],
      
      // La fameuse barre de navigation
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          backgroundColor: AppColors.blanc,
          type: BottomNavigationBarType.fixed, // Empèche les icônes de bouger bizarrement
          selectedItemColor: AppColors.terracotta, // La couleur de ton Call to Action
          unselectedItemColor: Colors.grey.shade400,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Accueil',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search_outlined),
              activeIcon: Icon(Icons.search),
              label: 'Recherche',
            ),
            BottomNavigationBarItem(
              // Un icône un peu différent pour le bouton "Ajouter"
              icon: Icon(Icons.add_circle_outline, size: 28),
              activeIcon: Icon(Icons.add_circle, size: 28),
              label: 'Vendre',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              activeIcon: Icon(Icons.chat_bubble),
              label: 'Messages',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}