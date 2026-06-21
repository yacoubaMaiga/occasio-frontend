import 'package:dio/dio.dart';
import 'package:occasio/core/api_client.dart';

class ProfilService {
  final Dio _dio = ApiClient.instance;

  // 🎯 Récupérer mon profil privé (MonProfilResponse)
  Future<Map<String, dynamic>> getMonProfil() async {
    try {
      final response = await _dio.get('/profil');
      return response.data;
    } catch (e) {
      throw Exception('Erreur lors du chargement du profil');
    }
  }

  // 🎯 Modifier les champs texte du profil (ProfilRequest)
  Future<Map<String, dynamic>> modifierProfil({
    required String nom,
    required String prenom,
    required String telephone,
  }) async {
    try {
      final response = await _dio.put(
        '/profil',
        data: {'firstName': prenom, 'lastName': nom, 'phoneNumber': telephone},
        options: Options(contentType: 'application/json'),
      );
      return response.data;
    } catch (e) {
      throw Exception('Erreur lors de la modification du profil');
    }
  }

  // 🎯 Mettre à jour la photo de profil (MultipartFile)
  Future<Map<String, dynamic>> modifierPhotoProfil(
    String cheminLocalPhoto,
  ) async {
    try {
      final formData = FormData.fromMap({
        'photo': await MultipartFile.fromFile(cheminLocalPhoto),
      });

      final response = await _dio.patch(
        '/profil/photo',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return response.data;
    } catch (e) {
      throw Exception('Erreur lors du changement de la photo de profil');
    }
  }

  // 🎯 Récupérer le profil public d'un autre utilisateur (PubliProfilResponse)
  Future<Map<String, dynamic>> getProfilPublic(String userId) async {
    try {
      final response = await _dio.get('/profil/$userId');
      return response.data;
    } catch (e) {
      throw Exception('Erreur lors du chargement du profil public');
    }
  }
}
