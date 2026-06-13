import 'package:flutter/material.dart';
import 'package:occasio/screen/home_screen.dart';
import 'package:occasio/screen/onboarding_screen.dart';
import 'package:occasio/screen/auth/registration_screen.dart';
import 'package:occasio/screen/auth/login_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Occasio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE07B39)),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const OnboardingScreen(),
        '/home': (context) => const HomeScreen(),
        '/inscription': (context) => const RegistrationScreen(),
        '/connexion': (context) => const LoginScreen(),
      },
    );
  }
}
