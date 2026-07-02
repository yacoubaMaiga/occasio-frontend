class AnnonceModel {
  final String id;
  final String titre;
  final String description;
  final int prix;
  final String etat;
  final String statut;
  final List<String> images;
  final String vendeurId;
  final String vendeurPseudo;
  final String categorieNom;
  final String createdAt;

  AnnonceModel({
    required this.id,
    required this.titre,
    required this.description,
    required this.prix,
    required this.etat,
    required this.statut,
    required this.images,
    required this.vendeurId,
    required this.vendeurPseudo,
    required this.categorieNom,
    required this.createdAt,
  });

  // Getters pratiques pour l'UI
  String? get imagePrincipale => images.isNotEmpty ? images.first : null;
  bool get estVendue => statut == 'VENDUE';

  factory AnnonceModel.fromJson(Map<String, dynamic> json) {
    return AnnonceModel(
      id: json['id'].toString(),
      titre: json['titre'] ?? 'Sans titre',
      description: json['description'] ?? '',
      prix: (json['prix'] as num?)?.toInt() ?? 0,
      etat: json['etat'] ?? 'INCONNU',
      statut: json['statut'] ?? 'ACTIVE',
      // Supabase renvoie un tableau PostgreSQL directement lisible
      images: List<String>.from(json['images'] ?? []),
      vendeurId: json['vendeur_id']?.toString() ?? '',
      createdAt: json['created_at'] ?? '',
      // Jointures automatiques de Supabase (les relations)
      vendeurPseudo: json['vendeur'] != null ? json['vendeur']['username'] : 'Utilisateur',
      categorieNom: json['categorie'] != null ? json['categorie']['nom'] : 'Catégorie',
    );
  }
}