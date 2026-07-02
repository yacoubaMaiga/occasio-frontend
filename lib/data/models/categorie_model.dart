class CategorieModel {
  final int id;
  final String nom;
  final String? description;
  final String? icone;

  CategorieModel({
    required this.id,
    required this.nom,
    this.description,
    this.icone,
  });

  factory CategorieModel.fromJson(Map<String, dynamic> json) {
    return CategorieModel(
      id: json['id'] ?? 0,
      nom: json['nom'] ?? 'Inconnu',
      description: json['description'],
      icone: json['icone'],
    );
  }
}