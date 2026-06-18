import 'package:dio/dio.dart';
import 'package:flutter/material.dart'; // Requis pour utiliser navigatorKey
import '../main.dart'; // Importer ton main.dart pour accéder à la navigatorKey
import 'api_constants.dart';
import 'token_storage.dart';

class ApiClient {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  )..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // On n'ajoute pas le token pour les routes publiques d'authentification
          if (!options.path.contains('/auth/')) {
            final token = await TokenStorage.getToken();
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          return handler.next(options);
        },
        // --- NOUVEAU : Interception des erreurs de Token ---
        onError: (DioException e, handler) async {
          // Si le backend nous dit que le token est expiré ou invalide (401)
          if (e.response?.statusCode == 401) {
            
            // 1. On vide le coffre-fort
            await TokenStorage.deleteToken();
            
            // 2. On affiche un petit message à l'utilisateur
            ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
              const SnackBar(
                content: Text('Votre session a expiré. Veuillez vous reconnecter.'),
                backgroundColor: Colors.redAccent,
              ),
            );

            // 3. On le jette violemment (mais poliment) sur la page de connexion
            navigatorKey.currentState?.pushNamedAndRemoveUntil('/connexion', (route) => false);
          }
          
          return handler.next(e);
        },
      ),
    );

  static Dio get instance => _dio;
}