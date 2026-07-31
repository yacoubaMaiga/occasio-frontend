import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:occasio/core/token_storage.dart';
import 'package:occasio/screen/admin/admin_dashboard_screen.dart';
import 'package:occasio/screen/auth/verify_email_screen.dart';
import 'package:occasio/screen/main_screen.dart';
import 'package:occasio/screen/onboarding_screen.dart';
import 'package:occasio/screen/auth/registration_screen.dart';
import 'package:occasio/screen/auth/login_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  final String? token = await TokenStorage.getToken();
  final bool isAdmin = await TokenStorage.isAdmin();

  final String startRoute = (token == null || token.isEmpty)
      ? '/onboarding'
      : (isAdmin ? '/admin' : '/home');

  runApp(MyApp(initialRoute: startRoute));

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
        '/admin': (context) => const AdminDashboardScreen(),
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