import '../../core/api/api_constants.dart';

/// Modèle Don pour GOODLY
class Don {
  final String idDon;
  final String idUtilisateur;
  final int montantUsd;
  final int pointsAttribues;
  final String statutPaiement;
  final DateTime dateCreation;
  final DateTime? dateConfirmation;

  Don({
    required this.idDon,
    required this.idUtilisateur,
    required this.montantUsd,
    required this.pointsAttribues,
    required this.statutPaiement,
    required this.dateCreation,
    this.dateConfirmation,
  });

  /// Crée un don à partir d'un JSON
  factory Don.fromJson(Map<String, dynamic> json) {
    return Don(
      idDon: json['id_don'],
      idUtilisateur: json['id_utilisateur'],
      montantUsd: json['montant_usd'],
      pointsAttribues: json['points_attribues'],
      statutPaiement: json['statut_paiement'],
      dateCreation: DateTime.parse(json['date_creation']),
      dateConfirmation: json['date_confirmation'] != null
          ? DateTime.parse(json['date_confirmation'])
          : null,
    );
  }

  /// Convertit le don en JSON
  Map<String, dynamic> toJson() {
    return {
      'id_don': idDon,
      'id_utilisateur': idUtilisateur,
      'montant_usd': montantUsd,
      'points_attribues': pointsAttribues,
      'statut_paiement': statutPaiement,
      'date_creation': dateCreation.toIso8601String(),
      'date_confirmation': dateConfirmation?.toIso8601String(),
    };
  }
}

/// Modèle pour les statistiques de dons (admin)
class DonStatistiques {
  final int totalDons;
  final int montantTotalUsd;
  final int pointsTotalDistribues;
  final double montantMoyenUsd;
  final List<TopDonateur> topDonateurs;

  DonStatistiques({
    required this.totalDons,
    required this.montantTotalUsd,
    required this.pointsTotalDistribues,
    required this.montantMoyenUsd,
    required this.topDonateurs,
  });

  factory DonStatistiques.fromJson(Map<String, dynamic> json) {
    return DonStatistiques(
      totalDons: json['total_dons'],
      montantTotalUsd: json['montant_total_usd'],
      pointsTotalDistribues: json['points_total_distribues'],
      montantMoyenUsd: (json['montant_moyen_usd'] as num).toDouble(),
      topDonateurs: (json['top_donateurs'] as List)
          .map((d) => TopDonateur.fromJson(d))
          .toList(),
    );
  }
}

class TopDonateur {
  final String nomUtilisateur;
  final String? photoProfil;
  final int totalDonne;
  final int nombreDons;

  TopDonateur({
    required this.nomUtilisateur,
    this.photoProfil,
    required this.totalDonne,
    required this.nombreDons,
  });

  factory TopDonateur.fromJson(Map<String, dynamic> json) {
    return TopDonateur(
      nomUtilisateur: json['nom_utilisateur'],
      photoProfil: json['photo_profil'],
      totalDonne: json['total_donne'],
      nombreDons: json['nombre_dons'],
    );
  }

  String? get photoProfilUrl {
    if (photoProfil == null || photoProfil!.isEmpty) return null;
    if (photoProfil!.startsWith('http://') ||
        photoProfil!.startsWith('https://')) {
      return photoProfil;
    }
    return '${ApiConstants.baseUrl}$photoProfil';
  }
}
