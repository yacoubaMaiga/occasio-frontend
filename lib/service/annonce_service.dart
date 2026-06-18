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
      final response = await _dio.get('/annonces?page=0&size=20&sortBy=createdAt&sortDirection=desc');
      // Le backend renvoie une "Page", les données sont dans "content"
      return response.data['content']; 
    } catch (e) {
      throw Exception("Erreur lors de la récupération des annonces");
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

    formData.files.add(MapEntry(
      'annonce',
      MultipartFile.fromString(
        jsonEncode(annonceData),
        contentType: MediaType.parse('application/json'),
      ),
    ));

    // 2. Les fichiers images (pour le @RequestPart("image") de Spring)
    for (var file in images) {
      formData.files.add(MapEntry(
        'image',
        await MultipartFile.fromFile(file.path),
      ));
    }

    try {
      await _dio.post('/annonces', data: formData);
    } catch (e) {
      throw Exception("Erreur lors de la publication de l'annonce");
    }
  }
}