import 'package:dio/dio.dart';
import 'package:occasio/core/api_client.dart';

class AdminService {
  final Dio _dio = ApiClient.instance;

  // --------------------------------------------------------
  // 1. STATISTIQUES GLOBALES (Pour le Dashboard)
  // --------------------------------------------------------
  Future<Map<String, int>> getGlobalStats() async {
    try {
      final response = await _dio.get('/admin/stats');
      final data = response.data as Map<String, dynamic>;

      return {
        'signalements': data['signalementsEnAttente'] as int,
        'users': data['utilisateurs'] as int,
        'annonces': data['annoncesActives'] as int,
        'categories': data['categories'] as int,
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
    // Le back ne renvoie que des IDs (annonceId, signaleurId) — on enrichit
    // en croisant avec /admin/users et /admin/annonces pour retrouver
    // les mêmes clés imbriquées ('annonce', 'signaleur') qu'avec Supabase.
    final results = await Future.wait([
      _dio.get('/signalements'),
      _dio.get('/admin/users'),
      _dio.get('/admin/annonces'),
    ]);

    final signalements = List<Map<String, dynamic>>.from(results[0].data);
    final users = List<Map<String, dynamic>>.from(results[1].data);
    final annonces = List<Map<String, dynamic>>.from(results[2].data);

    final usersById = {for (var u in users) u['id']: u};
    final annoncesById = {for (var a in annonces) a['id']: a};

    final enrichis = signalements.map((s) {
      final annonceId = s['annonceId'];
      final signaleur = usersById[s['signaleurId']];
      final annonce = annonceId != null ? annoncesById[annonceId] : null;

      return {
        'id': s['id'],
        'motif': s['motifSignalement'],
        'description': s['description'],
        'created_at': s['createdAt'],
        'annonce': annonce != null
            ? {
                'id': annonce['id'],
                'titre': annonce['titre'],
                'vendeur_id': annonce['vendeurId'],
              }
            : null,
        'signaleur': {
          'username': signaleur?['username'] ?? 'Inconnu',
          'email': signaleur?['email'] ?? '',
        },
      };
    }).toList();

    // Le back ne trie pas par date — on reproduit le tri croissant que
    // faisait Supabase (.order('created_at', ascending: true))
    enrichis.sort((a, b) =>
        (a['created_at'] as String).compareTo(b['created_at'] as String));

    return enrichis;
  }

  // Traiter un signalement (Rejeter, Supprimer l'annonce, ou Bannir le vendeur)
  Future<void> traiterSignalement({
    required String signalementId,
    required String action, // 'REJETER', 'SUPPRIMER_ANNONCE', 'BANNIR_USER'
    String? annonceId,
    String? vendeurId,
  }) async {
    if (action == 'BANNIR_USER' && vendeurId != null) {
      // Bannissement explicite (le back ne le fait pas automatiquement
      // pour un signalement de type ANNONCE — seulement pour un
      // signalement de type UTILISATEUR)
      await _dio.put(
        '/admin/users/$vendeurId/statut',
        queryParameters: {'enabled': false},
      );
    }

    final statut = action == 'REJETER' ? 'REJETE' : 'TRAITE';

    // Marquer le signalement comme traité. Si le signalement est de type
    // ANNONCE et que statut = TRAITE, le back supprime l'annonce lui-même.
    await _dio.patch(
      '/signalements/$signalementId',
      queryParameters: {'statut': statut},
    );
  }

  // --------------------------------------------------------
  // 3. GESTION DES UTILISATEURS
  // --------------------------------------------------------
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final response = await _dio.get('/admin/users');
    final users = List<Map<String, dynamic>>.from(response.data);

    // Remap vers les clés attendues par admin_users_screen.dart
    return users.map((u) => {
          'id': u['id'],
          'username': u['username'],
          'email': u['email'],
          'enabled': u['enabled'],
          'role': u['role'],
          'photo_profil': u['photoProfil'],
        }).toList();
  }

  Future<void> toggleUserStatus(String userId, bool isEnabled) async {
    await _dio.put(
      '/admin/users/$userId/statut',
      queryParameters: {'enabled': isEnabled},
    );
  }

  // --------------------------------------------------------
  // 4. GESTION DES CATÉGORIES
  // --------------------------------------------------------
  Future<void> creerCategorie(
    String nom,
    String description,
    String icone,
  ) async {
    await _dio.post('/categories', data: {
      'nom': nom,
      'description': description,
      'icone': icone,
    });
  }

  Future<void> supprimerCategorie(int categorieId) async {
    await _dio.delete('/categories/$categorieId');
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    final response = await _dio.get('/categories');
    final categories = List<Map<String, dynamic>>.from(response.data);
    categories.sort((a, b) => (a['nom'] as String).compareTo(b['nom'] as String));
    return categories;
  }

  Future<void> modifierCategorie(
    int id,
    String nom,
    String description,
    String icone,
  ) async {
    await _dio.put('/categories/$id', data: {
      'nom': nom,
      'description': description,
      'icone': icone,
    });
  }

  // Récupérer toutes les annonces avec les infos du vendeur
  Future<List<Map<String, dynamic>>> getAllAnnonces() async {
    final response = await _dio.get('/admin/annonces');
    final annonces = List<Map<String, dynamic>>.from(response.data);

    // Remap : admin_annonces_screen.dart attend a['vendeur']['username']
    return annonces.map((a) => {
          ...a,
          'vendeur': {'username': a['vendeurUsername']},
        }).toList();
  }

  // Forcer la suppression d'une annonce par l'admin
  Future<void> supprimerAnnonceAdmin(String annonceId) async {
    await _dio.delete('/admin/annonces/$annonceId');
  }
}