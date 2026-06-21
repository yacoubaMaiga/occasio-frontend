import 'package:dio/dio.dart';
import 'package:occasio/core/api_client.dart';

class MessagerieService {
  final Dio _dio = ApiClient.instance;

  Future<List<dynamic>> getMesConversations() async {
    try {
      final response = await _dio.get('/conversations');
      return response.data;
    } catch (e) {
      throw Exception('Erreur lors du chargement des conversations');
    }
  }

  // 🎯 Ouvre ou récupère une conversation existante pour une annonce
  Future<Map<String, dynamic>> ouvrirConversation(String annonceId) async {
    final response = await _dio.post('/conversations/$annonceId');
    return response.data;
  }

  // 🎯 Récupère tous les messages d'une conversation
  Future<List<dynamic>> getMessages(String conversationId) async {
    final response = await _dio.get('/conversations/$conversationId/messages');
    return response.data;
  }

  // 🎯 Envoie un nouveau message
  Future<Map<String, dynamic>> envoyerMessage(String conversationId, String contenu) async {
    final response = await _dio.post(
      '/conversations/$conversationId/messages',
      data: {'contenu': contenu},
    );
    return response.data;
  }

  // 🎯 Marque les messages de la conversation comme lus
  Future<void> marquerCommeLu(String conversationId) async {
    await _dio.patch('/conversations/$conversationId/lu');
  }
}