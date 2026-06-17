import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart'; // Ajout de l'import
import 'package:occasio/core/token_storage.dart'; // Pour lire le JWT
import 'package:occasio/screen/auth/verify_email_screen.dart';
import 'package:occasio/screen/home_screen.dart';
import 'package:occasio/screen/onboarding_screen.dart';
import 'package:occasio/screen/auth/registration_screen.dart';
import 'package:occasio/screen/auth/login_screen.dart';

void main() async {
  // 1. Initialiser le moteur Flutter de base
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // 2. Demander au système de GARDER le Splash Screen natif affiché
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // 3. Lire le token en arrière-plan
  final String? token = await TokenStorage.getToken();

  // 4. Décider de la route de départ selon la présence du token
  final String startRoute = (token != null && token.isNotEmpty)
      ? '/home'
      : '/onboarding';

  // 5. Lancer l'application avec la route dynamique
  runApp(MyApp(initialRoute: startRoute));

  // 6. Une fois l'application chargée, on DÉTRUIT le Splash Screen natif
  FlutterNativeSplash.remove();
}

class MyApp extends StatelessWidget {
  // Variable pour recevoir la route calculée dans le main()
  final String initialRoute;

  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Occasio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE07B39)),
        useMaterial3: true,
      ),

      // On utilise la variable injectée
      initialRoute: initialRoute,

      routes: {
        // Plus besoin de la route '/' puisque startRoute sera direct /home ou /onboarding
        '/onboarding': (context) => const OnboardingScreen(),
        '/home': (context) => const HomeScreen(),
        '/inscription': (context) => const RegistrationScreen(),
        '/connexion': (context) => const LoginScreen(),
      },

      onGenerateRoute: (settings) {
        if (settings.name == '/verification') {
          final String email = settings.arguments as String;
          return MaterialPageRoute(
            builder: (context) => VerifyEmailScreen(email: email),
          );
        }
        return null;
      },
    );
  }
}
