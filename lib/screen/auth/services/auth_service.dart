import 'package:dio/dio.dart';
import '../../../core/api_client.dart';
import '../../../core/api_constants.dart';
import '../../../core/token_storage.dart';
import '../../../data/models/user_model.dart';

class AuthService {
  // On récupère directement l'instance statique que tu as créée dans api_client.dart
  final Dio _dio = ApiClient.instance;

  // --- CONNEXION ---
  Future<UserModel> login(String email, String password) async {
    try {
      // 1. Appel de l'endpoint de connexion
      final authResponse = await _dio.post(
        ApiConstants.login,
        data: {'email': email, 'password': password},
      );

      final token = authResponse.data['token'];

      // 2. Sauvegarde du Token via ton fichier token_storage.dart
      await TokenStorage.saveToken(token);

      // 3. Récupération du profil complet
      final profilResponse = await _dio.get('/profil');

      return UserModel.fromJson(profilResponse.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // --- INSCRIPTION ---
  Future<String> register({
    required String username,
    required String email,
    required String password,
    required String confirmPassword,
    required String firstName,
    required String lastName,
    String? phoneNumber,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.register,
        data: {
          'username': username,
          'email': email,
          'password': password,
          'confirmPassword': confirmPassword,
          'firstName': firstName,
          'lastName': lastName,
          if (phoneNumber != null && phoneNumber.isNotEmpty)
            'phoneNumber': phoneNumber,
        },
      );
      return response.data['message'] ?? 'Inscription réussie';
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> loginWithGoogle(String idToken) async {
  try {
    final response = await _dio.post(
      '/auth/google',
      data: {'idToken': idToken},
    );
 
    // ✅ Sauvegarder le JWT exactement comme après un login classique
    final jwt = response.data['token'] ?? response.data['accessToken'];
    if (jwt != null) {
      await TokenStorage.saveToken(jwt);
    }
 
    return response.data;
  } catch (e) {
    throw Exception('Erreur de connexion via Google');
  }
}


  // --- DÉCONNEXION ---
  Future<void> logout() async {
    // Utilisation de ta méthode statique
    await TokenStorage.deleteToken();
  }

  // --- GESTION DES ERREURS ---
  String _handleError(DioException e) {
    if (e.response != null && e.response?.data != null) {
      final data = e.response?.data;

      // Messages d'erreurs classiques du backend (GlobalExceptionHandler)
      if (data is Map<String, dynamic> && data.containsKey('message')) {
        return data['message'];
      }
      // Erreurs de validation de formulaire du backend (ValidationExceptionHandler)
      if (data is Map<String, dynamic> &&
          data.containsKey('**** Erreurs ****: ')) {
        final errors = data['**** Erreurs ****: '] as List;
        return errors.join('\n');
      }
    }
    return "Impossible de joindre le serveur. Vérifiez votre connexion.";
  }

  // --- VÉRIFICATION DE L'EMAIL ---
  Future<String> verifyEmail(String code) async {
    try {
      final response = await _dio.post(
        ApiConstants
            .verifyEmail, // Assure-toi d'avoir cette constante dans api_constants.dart
        data: {'code': code},
      );
      return response.data['message'] ?? 'Email vérifié';
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // --- RENVOYER LE CODE ---
  Future<String> resendCode(String email) async {
    try {
      final response = await _dio.post(
        ApiConstants
            .resendCode, // Assure-toi d'avoir cette constante dans api_constants.dart
        data: {'email': email},
      );
      return response.data['message'] ?? 'Code renvoyé';
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
}
