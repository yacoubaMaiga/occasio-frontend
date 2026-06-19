import 'package:flutter/material.dart';
import 'package:occasio/core/token_storage.dart';
import 'package:occasio/screen/annonce/publish_screen.dart';
import 'package:occasio/screen/app_colors.dart';
import 'package:occasio/screen/conversation/conversations_screen.dart';
import 'package:occasio/screen/home_screen.dart';
import 'package:occasio/screen/profil_screen.dart'; 

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // Liste complète des 5 écrans correspondant aux 5 onglets
  final List<Widget> _screens = [
    const HomeScreen(),                               // Index 0 : Accueil (Public)
    const Center(child: Text('Recherche (Bientôt)')), // Index 1 : Recherche (Public)
    const SizedBox(),                                 // Index 2 : Vendre (Intercepté / Protégé)
    const ConversationsScreen(),  // Index 3 : Messages (Protégé)
    const ProfilScreen(),         // Index 4 : Profil (Protégé)
  ];

  // Gestion asynchrone du changement d'onglet
  Future<void> _onItemTapped(int index) async {
    // 1. Interception pour les onglets nécessitant obligatoirement un compte
    if (index == 2 || index == 3 || index == 4) {
      final token = await TokenStorage.getToken();
      
      if (token == null || token.isEmpty) {
        // L'utilisateur est un visiteur anonyme : on affiche l'invite de connexion
        _showLoginRequiredBottomSheet();
        return;
      }
    }

    // 2. Si l'utilisateur est connecté ou si l'onglet est public
    if (index == 2) {
      // Ouverture de la page de création par-dessus le reste
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const PublishScreen()),
      );
    } else {
      // Navigation classique entre les onglets
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  // Composant visuel incitant le visiteur à s'authentifier
  void _showLoginRequiredBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.blanc,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 64,
                width: 64,
                decoration: BoxDecoration(
                  color: AppColors.terracotta.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child:  Icon(
                  Icons.lock_outlined, // Icône de cadenas épurée
                  color: AppColors.terracotta,
                  size: 28,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Connexion requise',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.nuit,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Rejoignez notre communauté pour publier des annonces, envoyer des messages et gérer votre profil personnel.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.nuit.withValues(alpha: 0.55),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              
              // Bouton principal : Connexion
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.of(context).pushNamed('/connexion');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.callToAction,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Se connecter',
                    style: TextStyle(
                      color: AppColors.blanc,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              // Bouton secondaire : Création de compte
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.of(context).pushNamed('/inscription');
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.terracotta, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Créer un compte',
                    style: TextStyle(
                      color: AppColors.terracotta,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
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
          type: BottomNavigationBarType.fixed, 
          selectedItemColor: AppColors.terracotta, 
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