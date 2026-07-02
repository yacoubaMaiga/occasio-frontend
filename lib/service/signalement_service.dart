import 'package:supabase_flutter/supabase_flutter.dart';

class SignalementService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> signalerAnnonce({
    required String annonceId,
    required String motif,
    String? description,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception("Vous devez être connecté pour signaler une annonce.");
      }

      await _supabase.from('signalements').insert({
        'annonce_id': annonceId,
        'signale_par_id': userId,
        'motif': motif,
        'description': description ?? '',
        'statut': 'EN_ATTENTE',
      });
    } catch (e) {
      throw Exception("Erreur lors de l'envoi du signalement : $e");
    }
  }
}