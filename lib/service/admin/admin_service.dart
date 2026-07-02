import 'package:supabase_flutter/supabase_flutter.dart';

class AdminService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // --------------------------------------------------------
  // 1. STATISTIQUES GLOBAL (Pour le Dashboard)
  // --------------------------------------------------------
  Future<Map<String, int>> getGlobalStats() async {
    try {
      final sig = await _supabase
          .from('signalements')
          .select('id')
          .eq('statut', 'EN_ATTENTE');
      final users = await _supabase.from('users').select('id');
      final ann = await _supabase
          .from('annonces')
          .select('id')
          .eq('statut', 'ACTIVE');
      final cat = await _supabase.from('categories').select('id');

      return {
        'signalements': sig.length,
        'users': users.length,
        'annonces': ann.length,
        'categories': cat.length,
      };
    } catch (e) {
      print("Erreur stats admin: $e");
      return {'signalements': 0, 'users': 0, 'annonces': 0, 'categories': 0};
    }
  }

  // --------------------------------------------------------
  // 2. GESTION DES SIGNALEMENTS
  // --------------------------------------------------------
  Future<List<Map<String, dynamic>>> getSignalementsEnAttente() async {
    final response = await _supabase
        .from('signalements')
        .select(
          '*, annonce:annonces(id, titre, vendeur_id), signaleur:users!signale_par_id(username, email)',
        )
        .eq('statut', 'EN_ATTENTE')
        .order('created_at', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  // Traiter un signalement (Rejeter, Supprimer l'annonce, ou Bannir le vendeur)
  Future<void> traiterSignalement({
    required String signalementId,
    required String action, // 'REJETER', 'SUPPRIMER_ANNONCE', 'BANNIR_USER'
    String? annonceId,
    String? vendeurId,
  }) async {
    if (action == 'SUPPRIMER_ANNONCE' && annonceId != null) {
      await _supabase
          .from('annonces')
          .update({'statut': 'SUPPRIMEE'})
          .eq('id', annonceId);
    } else if (action == 'BANNIR_USER' && vendeurId != null) {
      await _supabase
          .from('users')
          .update({'enabled': false})
          .eq('id', vendeurId);
      // Optionnel : on supprime aussi son annonce
      if (annonceId != null) {
        await _supabase
            .from('annonces')
            .update({'statut': 'SUPPRIMEE'})
            .eq('id', annonceId);
      }
    }

    // Dans tous les cas, on marque le signalement comme traité
    await _supabase
        .from('signalements')
        .update({'statut': 'TRAITE'})
        .eq('id', signalementId);
  }

  // --------------------------------------------------------
  // 3. GESTION DES UTILISATEURS
  // --------------------------------------------------------
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final response = await _supabase
        .from('users')
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> toggleUserStatus(String userId, bool isEnabled) async {
    await _supabase
        .from('users')
        .update({'enabled': isEnabled})
        .eq('id', userId);
  }

  // --------------------------------------------------------
  // 4. GESTION DES CATÉGORIES
  // --------------------------------------------------------
  Future<void> creerCategorie(
    String nom,
    String description,
    String icone,
  ) async {
    await _supabase.from('categories').insert({
      'nom': nom,
      'description': description,
      'icone': icone,
    });
  }

  Future<void> supprimerCategorie(int categorieId) async {
    await _supabase.from('categories').delete().eq('id', categorieId);
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    final response = await _supabase.from('categories').select().order('nom');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> modifierCategorie(
    int id,
    String nom,
    String description,
    String icone,
  ) async {
    await _supabase
        .from('categories')
        .update({'nom': nom, 'description': description, 'icone': icone})
        .eq('id', id);
  }

  // Récupérer toutes les annonces avec les infos du vendeur
  Future<List<Map<String, dynamic>>> getAllAnnonces() async {
    final response = await _supabase
        .from('annonces')
        .select('*, vendeur:users(username, email)')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  // Forcer la suppression d'une annonce par l'admin
  Future<void> supprimerAnnonceAdmin(String annonceId) async {
    await _supabase.from('annonces').update({'statut': 'SUPPRIMEE'}).eq('id', annonceId);
  }
}
