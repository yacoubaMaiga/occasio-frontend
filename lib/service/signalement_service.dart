import 'package:dio/dio.dart';
import 'package:occasio/core/api_client.dart';

class SignalementService {
  final Dio _dio = ApiClient.instance;

  Future<void> signalerAnnonce({
    required String annonceId,
    required String motifSignalement, // 'CONTENU_INAPPROPRIE' | 'ARNAQUE' | 'SPAM' | 'AUTRE'
    String? description,
  }) async {
    try {
      await _dio.post(
        '/signalements/annonces/$annonceId',
        data: {
          'motifSignalement': motifSignalement,
          'typeSignalement': 'ANNONCE',
          if (description != null && description.isNotEmpty) 'description': description,
        },
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map<String, dynamic> && data.containsKey('message')) {
        throw Exception(data['message']);
      }
      throw Exception("Impossible d'envoyer le signalement");
    }
  }
}