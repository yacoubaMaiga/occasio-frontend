import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../main.dart';
import 'api_constants.dart';
import 'token_storage.dart';

// Routes publiques : un 401 ici ne doit PAS déconnecter l'utilisateur.
// Spring les autorise sans token, mais si un token invalide est envoyé,
// certains backends renvoient quand même 401.
const _publicPaths = [
  '/annonces',
  '/annonces/recherche',
  '/annonces/categorie',
  '/categories',
  '/uploads',
  '/profil',
];

bool _isPublicPath(String path) {
  return _publicPaths.any((p) => path.contains(p));
}

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
          // Ajout du token uniquement si disponible (routes publiques
          // fonctionnent sans token, routes protégées en ont besoin)
          if (!options.path.contains('/auth/')) {
            final token = await TokenStorage.getToken();
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          return handler.next(options);
        },

        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401) {
            // ── CORRECTIF : ne déconnecter que sur les routes protégées ──
            // Sur une route publique, le 401 signifie juste que le token
            // optionnel était invalide — pas que la session est expirée.
            final path = e.requestOptions.path;

            if (_isPublicPath(path)) {
              // Route publique : on supprime juste le token invalide
              // mais on ne redirige PAS vers la connexion.
              await TokenStorage.deleteToken();

              // On relance la requête SANS token cette fois
              final retryOptions = e.requestOptions;
              retryOptions.headers.remove('Authorization');
              try {
                final response = await _dio.fetch(retryOptions);
                return handler.resolve(response);
              } catch (_) {
                // Si ça échoue encore, on laisse passer l'erreur normalement
                return handler.next(e);
              }
            } else {
              // Route protégée : là on déconnecte vraiment
              await TokenStorage.deleteToken();

              final ctx = navigatorKey.currentContext;
              if (ctx != null && ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content:
                        Text('Votre session a expiré. Veuillez vous reconnecter.'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
                navigatorKey.currentState
                    ?.pushNamedAndRemoveUntil('/connexion', (route) => false);
              }
            }
          }

          return handler.next(e);
        },
      ),
    );

  static Dio get instance => _dio;
}