import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/annonce_model.dart';
import '../data/models/categorie_model.dart';

class AnnonceService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // --- CATÉGORIES ---
  Future<List<CategorieModel>> getCategories() async {
    try {
      // Utilise .select() et récupère directement le résultat typé
      final List<dynamic> response = await _supabase
          .from('categories')
          .select()
          .order('nom');

      print("Données brutes reçues de Supabase : $response"); // DEBUG ICI

      return response.map((json) => CategorieModel.fromJson(json)).toList();
    } catch (e) {
      print("Erreur dans getCategories: $e");
      throw Exception("Erreur lors de la récupération des catégories: $e");
    }
  }

  // --- CRÉER UNE ANNONCE ---
  Future<void> createAnnonce({
    required String titre,
    required String description,
    required int prix,
    required String etat,
    required int categorieId,
    required List<String> imagesUrls,
  }) async {
    try {
      // 1. On récupère l'ID du vendeur connecté
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception("Vous devez être connecté pour publier.");
      }

      // 2. On insère la nouvelle ligne dans la table annonces
      await _supabase.from('annonces').insert({
        'titre': titre,
        'description': description,
        'prix': prix,
        'etat': etat,
        'categorie_id': categorieId,
        'vendeur_id': userId,
        'images': imagesUrls,
        'statut': 'ACTIVE',
      });
    } catch (e) {
      throw Exception("Erreur lors de la publication : $e");
    }
  }

  // --- SUPPRIMER UNE ANNONCE ---
  Future<void> deleteAnnonce(String annonceId) async {
    try {
      // Grâce aux règles de sécurité (RLS) PostgreSQL,
      // la suppression sera rejetée si l'annonce n'appartient pas au user connecté !
      await _supabase.from('annonces').delete().eq('id', annonceId);
    } catch (e) {
      throw Exception("Impossible de supprimer l'annonce : $e");
    }
  }

  // --- TOUTES LES ANNONCES ACTIVES (AVEC PAGINATION) ---
  Future<List<AnnonceModel>> getAnnonces({int offset = 0, int limit = 10}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;

      var query = _supabase
          .from('annonces')
          .select('*, vendeur:users(username), categorie:categories(nom)')
          .eq('statut', 'ACTIVE');

      // On exclut les annonces de l'utilisateur connecté
      if (userId != null) {
        query = query.neq('vendeur_id', userId);
      }

      // 💡 MAGIE ICI : On applique le tri et la pagination (range)
      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1); 
          // Si offset = 0 et limit = 10 -> range(0, 9)
      
      return (response as List).map((json) => AnnonceModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception("Erreur lors de la récupération des annonces paginées: $e");
    }
  }
  // --- MES ANNONCES ---
  Future<List<AnnonceModel>> getMesAnnonces() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception("Non connecté");

      final response = await _supabase
          .from('annonces')
          .select('*, vendeur:users(username), categorie:categories(nom)')
          .eq('vendeur_id', userId)
          .order('created_at', ascending: false);
      return (response as List)
          .map((json) => AnnonceModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception("Erreur lors de la récupération de vos annonces: $e");
    }
  }

  // --- RECHERCHE ---
  Future<List<AnnonceModel>> rechercher({
    String? q,
    int? categorieId,
    String? etat,
    int? prixMin,
    int? prixMax,
  }) async {
    try {
      var query = _supabase
          .from('annonces')
          .select('*, vendeur:users(username), categorie:categories(nom)')
          .eq('statut', 'ACTIVE');

      if (q != null && q.isNotEmpty) query = query.ilike('titre', '%$q%');
      if (categorieId != null) query = query.eq('categorie_id', categorieId);
      if (etat != null && etat.isNotEmpty) query = query.eq('etat', etat);
      if (prixMin != null) query = query.gte('prix', prixMin);
      if (prixMax != null) query = query.lte('prix', prixMax);

      final response = await query.order('created_at', ascending: false);
      return (response as List)
          .map((json) => AnnonceModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception("Erreur lors de la recherche: $e");
    }
  }
}
