import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:occasio/core/api_client.dart';
import 'package:http_parser/http_parser.dart';

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
      final response = await _dio.get(
        '/annonces?page=0&size=20&sortBy=createdAt&sortDirection=desc',
      );
      // Le backend renvoie une "Page", les données sont dans "content"
      return response.data['content'];
    } catch (e) {
      throw Exception("Erreur lors de la récupération des annonces");
    }
  }

  // 🎯 NOUVEAU : Récupérer mes propres annonces
  Future<List<dynamic>> getMesAnnonces() async {
    try {
      final response = await _dio.get('/annonces/mes-annonces');
      
      // Le backend renvoie une "Page", les données sont dans "content"
      if (response.data != null && response.data['content'] != null) {
        return response.data['content'];
      }
      return [];
    } catch (e) {
      print("Erreur API getMesAnnonces: $e");
      throw Exception("Erreur lors de la récupération de mes annonces");
    }
  }

  Future<void> creerAnnonce({
    required String titre,
    required String description,
    required int prix,
    required String etat,
    required int categorieId,
    required List<File> images,
  }) async {
    final formData = FormData();
    // 1. Les données de l'annonce (JSON pour le @RequestPart("annonce") de Spring)
    final annonceData = {
      'titre': titre,
      'description': description,
      'prix': prix,
      'etat': etat,
      'categorieId': categorieId,
    };

    formData.files.add(
      MapEntry(
        'annonce',
        MultipartFile.fromString(
          jsonEncode(annonceData),
          contentType: MediaType.parse('application/json'),
        ),
      ),
    );

    // 2. Les fichiers images (pour le @RequestPart("image") de Spring)
    for (var file in images) {
      formData.files.add(
        MapEntry('image', await MultipartFile.fromFile(file.path)),
      );
    }

    try {
      await _dio.post('/annonces', data: formData);
    } catch (e) {
      throw Exception("Erreur lors de la publication de l'annonce");
    }
  }

  Future<List<dynamic>> getAnnoncesParCategorie(int categorieId) async {
    try {
      final response = await _dio.get('/annonces/categorie/$categorieId');
      return response.data; // Renvoie la liste des annonces de cette catégorie
    } catch (e) {
      throw Exception("Erreur lors de la récupération des recommandations");
    }
  }

  // Recherche avec filtres
  Future<List<dynamic>> rechercher({
    String? q,
    int? categorieId,
    String? etat,
    int? prixMin,
    int? prixMax,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (q != null && q.trim().isNotEmpty) queryParams['q'] = q;
      if (categorieId != null && categorieId > 0) queryParams['categorieId'] = categorieId;
      if (etat != null && etat.isNotEmpty) queryParams['etat'] = etat;
      if (prixMin != null) queryParams['prixMin'] = prixMin;
      if (prixMax != null) queryParams['prixMax'] = prixMax;

      final response = await _dio.get(
        '/annonces/recherche',
        queryParameters: queryParams,
      );

      // Spring Boot renvoie un objet Page, la liste est dans "content"
      if (response.data != null && response.data['content'] != null) {
        return response.data['content'];
      }
      return [];
    } catch (e) {
      print("Erreur lors de la recherche: $e");
      return [];
    }
  }
}