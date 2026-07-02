import 'package:supabase_flutter/supabase_flutter.dart';

class FavoriService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Vérifier si une annonce spécifique est dans les favoris de l'utilisateur
  Future<bool> estFavori(String annonceId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final response = await _supabase
          .from('favoris')
          .select('id')
          .eq('user_id', userId)
          .eq('annonce_id', annonceId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print("Erreur dans estFavori: $e");
      return false;
    }
  }

  // Ajouter une annonce aux favoris
  Future<void> ajouterAuxFavoris(String annonceId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception("Vous devez être connecté pour ajouter un favori.");

      await _supabase.from('favoris').insert({
        'user_id': userId,
        'annonce_id': annonceId,
      });
    } catch (e) {
      throw Exception("Erreur lors de l'ajout aux favoris : $e");
    }
  }

  // Supprimer une annonce des favoris
  Future<void> supprimerDesFavoris(String annonceId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception("Vous devez être connecté.");

      await _supabase
          .from('favoris')
          .delete()
          .eq('user_id', userId)
          .eq('annonce_id', annonceId);
    } catch (e) {
      throw Exception("Erreur lors de la suppression du favori : $e");
    }
  }

  // Récupérer la liste de toutes les annonces favorites de l'utilisateur connecté
  Future<List<Map<String, dynamic>>> getMesFavoris() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception("Non connecté");

      // On récupère les favoris en joignant les détails de l'annonce associée
      final response = await _supabase
          .from('favoris')
          .select('*, annonce:annonces(*, vendeur:users(username), categorie:categories(nom))')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return response as List<Map<String, dynamic>>;
    } catch (e) {
      throw Exception("Erreur lors de la récupération des favoris : $e");
    }
  }
}