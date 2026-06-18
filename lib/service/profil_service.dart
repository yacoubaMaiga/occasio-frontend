import 'package:dio/dio.dart';
import 'package:occasio/core/api_client.dart';

class ProfilService {
  final Dio _dio = ApiClient.instance;

  // Récupérer les informations du profil connecté
  Future<Map<String, dynamic>> getMonProfil() async {
    try {
      final response = await _dio.get('/profil');
      return response.data; // Renvoie les données du profil (MonProfilResponse)
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Mettre à jour les informations du profil
  Future<Map<String, dynamic>> modifierProfil({
    required String firstName,
    required String lastName,
    required String username,
    String? phoneNumber,
  }) async {
    try {
      final response = await _dio.put(
        '/profil',
        data: {
          'firstName': firstName,
          'lastName': lastName,
          'username': username,
          if (phoneNumber != null) 'phoneNumber': phoneNumber,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException e) {
    if (e.response != null && e.response?.data != null) {
      final data = e.response?.data;
      if (data is Map<String, dynamic> && data.containsKey('message')) {
        return data['message'];
      }
    }
    return "Une erreur est survenue avec le serveur de profil.";
  }
}