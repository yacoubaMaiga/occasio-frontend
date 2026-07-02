import 'package:supabase_flutter/supabase_flutter.dart';

class MessagerieService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<dynamic>> getMesConversations() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    // On récupère les conversations + infos annonce + infos acheteur/vendeur + messages
    final response = await _supabase
        .from('conversations')
        .select('''
          *,
          annonce:annonces(id, titre, prix, statut, images),
          acheteur:users!acheteur_id(id, username, photo_profil),
          vendeur:users!vendeur_id(id, username, photo_profil),
          messages(id, contenu, lu, expediteur_id, created_at)
        ''')
        .or('acheteur_id.eq.$userId,vendeur_id.eq.$userId')
        .order('dernier_message_date', ascending: false);

    // Formatage pour correspondre exactement à l'attente de ton UI
    return (response as List).map((conv) {
      final isAcheteur = conv['acheteur_id'] == userId;
      final interlocuteur = isAcheteur ? conv['vendeur'] : conv['acheteur'];
      
      final msgs = conv['messages'] as List;
      msgs.sort((a, b) => a['created_at'].compareTo(b['created_at']));
      final lastMsg = msgs.isNotEmpty ? msgs.last : null;
      final nonLus = msgs.where((m) => m['lu'] == false && m['expediteur_id'] != userId).length;

      return {
        'id': conv['id'],
        'userId': interlocuteur['id'],
        'username': interlocuteur['username'],
        'annonceTitre': conv['annonce']['titre'],
        'annoncePrix': conv['annonce']['prix'],
        'annonceStatut': conv['annonce']['statut'],
        'annonceImagePrincipale': (conv['annonce']['images'] != null && conv['annonce']['images'].isNotEmpty) ? conv['annonce']['images'][0] : null,
        'dernierMessage': lastMsg != null ? lastMsg['contenu'] : 'Nouvelle conversation',
        'dernierMessageDate': conv['dernier_message_date'],
        'nonLus': nonLus,
        'createdAt': conv['created_at'],
      };
    }).toList();
  }

  Future<Map<String, dynamic>> ouvrirConversation(String annonceId) async {
    final userId = _supabase.auth.currentUser?.id;
    
    // 1. Cherche si la conversation existe déjà
    final existing = await _supabase.from('conversations').select().eq('annonce_id', annonceId).eq('acheteur_id', userId!).maybeSingle();
    if (existing != null) return existing;

    // 2. Sinon, on récupère le vendeur et on crée la conversation
    final annonce = await _supabase.from('annonces').select('vendeur_id').eq('id', annonceId).single();
    final newConv = await _supabase.from('conversations').insert({
      'annonce_id': annonceId,
      'acheteur_id': userId,
      'vendeur_id': annonce['vendeur_id'],
    }).select().single();

    return newConv;
  }

  Future<List<dynamic>> getMessages(String conversationId) async {
    final response = await _supabase
        .from('messages')
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true);
        
    return (response as List).map((m) => {
      'id': m['id'],
      'contenu': m['contenu'],
      'dateEnvoie': m['created_at'],
      'lu': m['lu'],
      'expediteurId': m['expediteur_id']
    }).toList();
  }

  Future<Map<String, dynamic>> envoyerMessage(String conversationId, String contenu) async {
    final userId = _supabase.auth.currentUser?.id;
    
    // 1. Insère le message
    final newMsg = await _supabase.from('messages').insert({
      'conversation_id': conversationId,
      'expediteur_id': userId,
      'contenu': contenu
    }).select().single();

    // 2. Met à jour la date de la conversation
    await _supabase.from('conversations').update({
      'dernier_message_date': DateTime.now().toIso8601String()
    }).eq('id', conversationId);

    return {
      'id': newMsg['id'],
      'contenu': newMsg['contenu'],
      'dateEnvoie': newMsg['created_at'],
      'lu': newMsg['lu'],
      'expediteurId': newMsg['expediteur_id']
    };
  }

  Future<void> marquerCommeLu(String conversationId) async {
    final userId = _supabase.auth.currentUser?.id;
    await _supabase.from('messages')
        .update({'lu': true})
        .eq('conversation_id', conversationId)
        .neq('expediteur_id', userId!);
  }
}