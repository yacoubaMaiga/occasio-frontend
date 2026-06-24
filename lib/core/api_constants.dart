class ApiConstants {
  // l'émulateur Android: 10.0.2.2.
  // static const String baseUrl = 'http://192.168.100.191:8080/api'; 

  static const String baseUrl = 'https://marketplace-backend-my4g.onrender.com/api';
  
  // Endpoints d'authentification
  static const String login = '/auth/connexion';
  static const String register = '/auth/inscription';
  static const String verifyEmail = '/auth/verify';
  static const String resendCode = '/auth/renvoyer-code';
  static const String googleLogin = '/auth/google';
}