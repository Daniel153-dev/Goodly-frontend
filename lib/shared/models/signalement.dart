class Signalement {
  final String idSignalement;
  final String idPublication;
  final String idUtilisateurSignaleur;
  final String motif;
  final String? description;
  final String statut;
  final DateTime dateCreation;
  final String? publicationTitre;
  final String? nomUtilisateurSignaleur;

  Signalement({
    required this.idSignalement,
    required this.idPublication,
    required this.idUtilisateurSignaleur,
    required this.motif,
    this.description,
    required this.statut,
    required this.dateCreation,
    this.publicationTitre,
    this.nomUtilisateurSignaleur,
  });

  factory Signalement.fromJson(Map<String, dynamic> json) {
    return Signalement(
      idSignalement: json['id_signalement'],
      idPublication: json['id_publication'],
      idUtilisateurSignaleur: json['id_utilisateur_signaleur'],
      motif: json['motif'],
      description: json['description'],
      statut: json['statut'],
      dateCreation: DateTime.parse(json['date_creation']),
      publicationTitre: json['publication_titre'],
      nomUtilisateurSignaleur: json['nom_utilisateur_signaleur'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_signalement': idSignalement,
      'id_publication': idPublication,
      'id_utilisateur_signaleur': idUtilisateurSignaleur,
      'motif': motif,
      'description': description,
      'statut': statut,
      'date_creation': dateCreation.toIso8601String(),
      'publication_titre': publicationTitre,
      'nom_utilisateur_signaleur': nomUtilisateurSignaleur,
    };
  }

  String get motifLabel {
    switch (motif) {
      case 'contenu_inapproprie':
        return 'Contenu inapproprié';
      case 'fausse_information':
        return 'Fausse information';
      case 'spam':
        return 'Spam';
      default:
        return 'Autre';
    }
  }

  String get statutLabel {
    switch (statut) {
      case 'en_attente':
        return 'En attente';
      case 'traite':
        return 'Traité';
      case 'ignore':
        return 'Ignoré';
      default:
        return statut;
    }
  }
}
