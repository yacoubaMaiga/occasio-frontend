import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Ajout de l'import Supabase

import 'package:occasio/screen/main_screen.dart';
import 'package:occasio/screen/onboarding_screen.dart';
import 'package:occasio/screen/auth/registration_screen.dart';
import 'package:occasio/screen/auth/login_screen.dart';
// Note: J'ai retiré l'import de verify_email_screen.dart car Supabase n'utilise pas de code OTP par défaut.

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  // 1. Initialiser le moteur Flutter de base
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // 2. Demander au système de GARDER le Splash Screen natif affiché
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // 3. Initialisation de Supabase (Remplace par tes VRAIES clés)
  await Supabase.initialize(
    url: 'https://ogauagzufinzpihsoxpf.supabase.co', // <-- À CHANGER
    anonKey: 'sb_secret_U5wGvyJQabsrIHx18xZEnw_8ebD8PF0',       // <-- À CHANGER
  );

  // 4. Vérifier si une session Supabase est déjà active
  final session = Supabase.instance.client.auth.currentSession;

  // 5. Décider de la route de départ selon la présence d'une session
  final String startRoute = session != null ? '/home' : '/onboarding';

  // 6. Lancer l'application avec la route dynamique
  runApp(MyApp(initialRoute: startRoute));

  // 7. Une fois l'application chargée, on DÉTRUIT le Splash Screen natif
  FlutterNativeSplash.remove();
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Occasio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE07B39)),
        useMaterial3: true,
      ),
      initialRoute: initialRoute,
      routes: {
        '/onboarding': (context) => const OnboardingScreen(),
        '/home': (context) => const MainScreen(),
        '/inscription': (context) => const RegistrationScreen(),
        '/connexion': (context) => const LoginScreen(),
      },
      // J'ai supprimé onGenerateRoute pour /verification car nous avons désactivé 
      // la confirmation d'email dans Supabase pour faciliter le développement.
    );
  }
}