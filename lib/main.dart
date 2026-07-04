import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:occasio/screen/admin/admin_dashboard_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:occasio/screen/main_screen.dart';
import 'package:occasio/screen/onboarding_screen.dart';
import 'package:occasio/screen/auth/registration_screen.dart';
import 'package:occasio/screen/auth/login_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Initialisation de Supabase
  await Supabase.initialize(
    url: 'https://xwvlldozxpzfkbpinnvb.supabase.co',
    anonKey: 'sb_secret_fKy4R7AP1eAxg_jR5m1o6g_mfRhqfMQ',
  );

  runApp(const MyApp());
  
  FlutterNativeSplash.remove();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
      
      // On n'utilise plus "initialRoute" calculé en dur. 
      // On donne directement le "AuthGate" comme page d'accueil (home).
      home: const AuthGate(),
      
      routes: {
        '/onboarding': (context) => const OnboardingScreen(),
        '/home': (context) => const MainScreen(),
        '/inscription': (context) => const RegistrationScreen(),
        '/connexion': (context) => const LoginScreen(),
        '/admin': (context) => const AdminDashboardScreen(),
      },
    );
  }
}

// --- LE GARDIEN D'AUTHENTIFICATION ---
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFE07B39),
            body: Center(child: CircularProgressIndicator(color: Colors.white)),
          );
        }

        final session = snapshot.data?.session;

        if (session != null) {
          return FutureBuilder<Map<String, dynamic>?>(
            // Utilisation de maybeSingle() au lieu de single() pour éviter l'erreur si user inexistant
            future: Supabase.instance.client
                .from('users')
                .select('role')
                .eq('id', session.user.id)
                .maybeSingle(), 
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  backgroundColor: Color(0xFFE07B39),
                  body: Center(child: CircularProgressIndicator(color: Colors.white)),
                );
              }

              // Gestion sécurisée de la valeur : si null ou erreur, on redirige vers le Home (MEMBRE)
              final data = userSnapshot.data;
              final role = data != null ? data['role'] : 'ROLE_MEMBRE';

              if (role == 'ROLE_ADMIN') {
                return const AdminDashboardScreen();
              } else {
                return const MainScreen();
              }
            },
          );
        } else {
          return const OnboardingScreen();
        }
      },
    );
  }
}