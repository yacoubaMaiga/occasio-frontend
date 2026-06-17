import 'package:dio/dio.dart';
import 'package:occasio/core/api_client.dart';

class AnnonceService {
  final Dio _dio = ApiClient.instance;

  // Récupérer les catégories
  Future<List<dynamic>> getCategories() async {
    try {
      final response = await _dio.get('/categories');
      return response.data; // Retourne la liste des catégories
    } catch (e) {
      throw Exception("Erreur lors de la récupération des catégories");
    }
  }

  // Récupérer les annonces actives (page 0)
  Future<List<dynamic>> getAnnonces() async {
    try {
      final response = await _dio.get('/annonces?page=0&size=20&sortBy=createdAt&sortDirection=desc');
      // Le backend renvoie une "Page", les données sont dans "content"
      return response.data['content']; 
    } catch (e) {
      throw Exception("Erreur lors de la récupération des annonces");
    }
  }
}