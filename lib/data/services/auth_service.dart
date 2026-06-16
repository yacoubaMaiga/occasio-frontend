import 'package:dio/dio.dart';
import '../../core/api_client.dart';
import '../../core/api_constants.dart';
import '../../core/token_storage.dart';
import '../models/auth_response.dart';

class AuthService {
  final Dio _dio = ApiClient.instance;

  // 1. Connexion (LoginRequest)
  Future<AuthResponse> login(String email, String password) async {
    try {
      final response = await _dio.post(
        ApiConstants.login,
        data: {
          'email': email,
          'password': password,
        },
      );
      
      final authData = AuthResponse.fromJson(response.data);
      // Sauvegarde du JWT pour les prochaines requêtes
      await TokenStorage.saveToken(authData.token);
      
      return authData;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 2. Inscription (RegisterRequest)
  // Renvoie juste le message de succès (cf: MessageResponse côté backend)
  Future<String> register({
    required String username,
    required String email,
    required String password,
    required String confirmPassword,
    required String firstName,
    required String lastName,
    String? phoneNumber, // Optionnel
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
          if (phoneNumber != null && phoneNumber.isNotEmpty) 'phoneNumber': phoneNumber,
        },
      );
      return response.data['message'] ?? 'Inscription réussie';
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 3. Vérification de l'email (VerifyEmailRequest)
  Future<String> verifyEmail(String code) async {
    try {
      final response = await _dio.post(
        ApiConstants.verifyEmail,
        data: {'code': code},
      );
      return response.data['message'] ?? 'Email vérifié';
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 4. Renvoyer le code (ResendCodeRequest)
  Future<String> resendCode(String email) async {
    try {
      final response = await _dio.post(
        ApiConstants.resendCode,
        data: {'email': email},
      );
      return response.data['message'] ?? 'Code renvoyé';
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 5. Déconnexion (Purement côté Flutter puisque le backend est Stateless)
  Future<void> logout() async {
    await TokenStorage.deleteToken();
  }

  // -- Gestion des erreurs renvoyées par ton GlobalExceptionHandler.java
  String _handleError(DioException e) {
    if (e.response != null && e.response?.data != null) {
      // Ton backend renvoie souvent des "MessageResponse" avec une clé "message"
      final data = e.response?.data;
      if (data is Map<String, dynamic> && data.containsKey('message')) {
        return data['message'];
      }
      // Pour les erreurs de validation (@Valid -> ValidationExceptionHandler)
      if (data is Map<String, dynamic> && data.containsKey('**** Erreurs ****: ')) {
        final errors = data['**** Erreurs ****: '] as List;
        return errors.join('\n');
      }
    }
    return "Une erreur de connexion au serveur est survenue";
  }
}