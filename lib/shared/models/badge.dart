class BadgeModel {
  final String idBadge;
  final String nom;
  final String? description;
  final String? icone;
  final String? couleur;

  BadgeModel({
    required this.idBadge,
    required this.nom,
    this.description,
    this.icone,
    this.couleur,
  });

  factory BadgeModel.fromJson(Map<String, dynamic> json) {
    return BadgeModel(
      idBadge: json['id_badge'],
      nom: json['nom'],
      description: json['description'],
      icone: json['icone'],
      couleur: json['couleur'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_badge': idBadge,
      'nom': nom,
      'description': description,
      'icone': icone,
      'couleur': couleur,
    };
  }
}
