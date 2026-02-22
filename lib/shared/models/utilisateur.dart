import '../../core/api/api_constants.dart';
import 'utilisateur_badge.dart';

/// Modele Utilisateur pour GOODLY
class Utilisateur {
  final String idUtilisateur;
  final String nomUtilisateur;
  final String email;
  final String? photoProfil;
  final String? photoGalerie1;
  final String? photoGalerie2;
  final String? photoGalerie3;
  final String? biographie;
  final String role;
  final String statutCompte;
  final DateTime dateCreation;
  final DateTime? derniereConnexion;
  final int totalPoints;
  final int pointsSaisonActuelle;
  final List<UtilisateurBadge> badges;
  final bool badgeBleu;
  final String? pays;
  final DateTime? dateNaissance;
  final DateTime? analyticsDateDebut;
  final bool analyticsAbonnementActif;
  final DateTime? analyticsDateExpiration;

  // Propriété calculée pour vérifier si l'utilisateur est admin
  bool get isAdmin => role == 'administrateur' || role == 'admin';

  Utilisateur({
    required this.idUtilisateur,
    required this.nomUtilisateur,
    required this.email,
    this.photoProfil,
    this.photoGalerie1,
    this.photoGalerie2,
    this.photoGalerie3,
    this.biographie,
    required this.role,
    required this.statutCompte,
    required this.dateCreation,
    this.derniereConnexion,
    this.totalPoints = 0,
    this.pointsSaisonActuelle = 0,
    this.badges = const [],
    this.badgeBleu = false,
    this.pays,
    this.dateNaissance,
    this.analyticsDateDebut,
    this.analyticsAbonnementActif = false,
    this.analyticsDateExpiration,
  });

  /// Calcule l'age de l'utilisateur
  int? get age {
    if (dateNaissance == null) return null;
    final today = DateTime.now();
    int calculatedAge = today.year - dateNaissance!.year;
    if (today.month < dateNaissance!.month ||
        (today.month == dateNaissance!.month && today.day < dateNaissance!.day)) {
      calculatedAge--;
    }
    return calculatedAge;
  }

  /// Cree un utilisateur a partir d'un JSON
  factory Utilisateur.fromJson(Map<String, dynamic> json) {
    return Utilisateur(
      idUtilisateur: json['id_utilisateur'],
      nomUtilisateur: json['nom_utilisateur'],
      email: json['email'],
      photoProfil: json['photo_profil'],
      photoGalerie1: json['photo_galerie_1'],
      photoGalerie2: json['photo_galerie_2'],
      photoGalerie3: json['photo_galerie_3'],
      biographie: json['biographie'],
      role: json['role'],
      statutCompte: json['statut_compte'],
      dateCreation: DateTime.parse(json['date_creation']),
      derniereConnexion: json['derniere_connexion'] != null
          ? DateTime.parse(json['derniere_connexion'])
          : null,
      totalPoints: json['total_points'] ?? 0,
      pointsSaisonActuelle: json['points_saison_actuelle'] ?? 0,
      badges: json['badges'] != null
          ? (json['badges'] as List)
              .map((badge) => UtilisateurBadge.fromJson(badge))
              .toList()
          : [],
      badgeBleu: json['badge_bleu'] ?? false,
      pays: json['pays'],
      dateNaissance: json['date_naissance'] != null
          ? DateTime.parse(json['date_naissance'])
          : null,
      analyticsDateDebut: json['analytics_date_debut'] != null
          ? DateTime.parse(json['analytics_date_debut'])
          : null,
      analyticsAbonnementActif: json['analytics_abonnement_actif'] ?? false,
      analyticsDateExpiration: json['analytics_date_expiration'] != null
          ? DateTime.parse(json['analytics_date_expiration'])
          : null,
    );
  }

  /// Convertit l'utilisateur en JSON
  Map<String, dynamic> toJson() {
    return {
      'id_utilisateur': idUtilisateur,
      'nom_utilisateur': nomUtilisateur,
      'email': email,
      'photo_profil': photoProfil,
      'photo_galerie_1': photoGalerie1,
      'photo_galerie_2': photoGalerie2,
      'photo_galerie_3': photoGalerie3,
      'biographie': biographie,
      'role': role,
      'statut_compte': statutCompte,
      'date_creation': dateCreation.toIso8601String(),
      'derniere_connexion': derniereConnexion?.toIso8601String(),
      'total_points': totalPoints,
      'points_saison_actuelle': pointsSaisonActuelle,
      'badges': badges.map((badge) => badge.toJson()).toList(),
      'badge_bleu': badgeBleu,
      'pays': pays,
      'date_naissance': dateNaissance?.toIso8601String(),
      'analytics_date_debut': analyticsDateDebut?.toIso8601String(),
      'analytics_abonnement_actif': analyticsAbonnementActif,
      'analytics_date_expiration': analyticsDateExpiration?.toIso8601String(),
    };
  }

  /// Copie l'utilisateur avec des modifications
  Utilisateur copyWith({
    String? idUtilisateur,
    String? nomUtilisateur,
    String? email,
    String? photoProfil,
    String? photoGalerie1,
    String? photoGalerie2,
    String? photoGalerie3,
    String? biographie,
    String? role,
    String? statutCompte,
    DateTime? dateCreation,
    DateTime? derniereConnexion,
    int? totalPoints,
    int? pointsSaisonActuelle,
    List<UtilisateurBadge>? badges,
    bool? badgeBleu,
    String? pays,
    DateTime? dateNaissance,
    DateTime? analyticsDateDebut,
    bool? analyticsAbonnementActif,
    DateTime? analyticsDateExpiration,
  }) {
    return Utilisateur(
      idUtilisateur: idUtilisateur ?? this.idUtilisateur,
      nomUtilisateur: nomUtilisateur ?? this.nomUtilisateur,
      email: email ?? this.email,
      photoProfil: photoProfil ?? this.photoProfil,
      photoGalerie1: photoGalerie1 ?? this.photoGalerie1,
      photoGalerie2: photoGalerie2 ?? this.photoGalerie2,
      photoGalerie3: photoGalerie3 ?? this.photoGalerie3,
      biographie: biographie ?? this.biographie,
      role: role ?? this.role,
      statutCompte: statutCompte ?? this.statutCompte,
      dateCreation: dateCreation ?? this.dateCreation,
      derniereConnexion: derniereConnexion ?? this.derniereConnexion,
      totalPoints: totalPoints ?? this.totalPoints,
      pointsSaisonActuelle: pointsSaisonActuelle ?? this.pointsSaisonActuelle,
      badges: badges ?? this.badges,
      badgeBleu: badgeBleu ?? this.badgeBleu,
      pays: pays ?? this.pays,
      dateNaissance: dateNaissance ?? this.dateNaissance,
      analyticsDateDebut: analyticsDateDebut ?? this.analyticsDateDebut,
      analyticsAbonnementActif: analyticsAbonnementActif ?? this.analyticsAbonnementActif,
      analyticsDateExpiration: analyticsDateExpiration ?? this.analyticsDateExpiration,
    );
  }

  /// Convertit une URL relative en URL absolue
  String? _getFullImageUrl(String? relativeUrl) {
    if (relativeUrl == null || relativeUrl.isEmpty) return null;
    if (relativeUrl.startsWith('http://') || relativeUrl.startsWith('https://')) {
      return relativeUrl;
    }

    String normalizedUrl = relativeUrl.replaceAll('\\', '/');
    if (!normalizedUrl.startsWith('/')) {
      normalizedUrl = '/$normalizedUrl';
    }

    return '${ApiConstants.baseUrl}$normalizedUrl';
  }

  /// URL complete de la photo de profil
  String? get photoProfilUrl => _getFullImageUrl(photoProfil);

  /// URL complete de la photo de galerie 1
  String? get photoGalerie1Url => _getFullImageUrl(photoGalerie1);

  /// URL complete de la photo de galerie 2
  String? get photoGalerie2Url => _getFullImageUrl(photoGalerie2);

  /// URL complete de la photo de galerie 3
  String? get photoGalerie3Url => _getFullImageUrl(photoGalerie3);

  /// Recupere toutes les photos de galerie non nulles
  List<String> get photosGalerie {
    return [photoGalerie1, photoGalerie2, photoGalerie3]
        .where((photo) => photo != null && photo.isNotEmpty)
        .cast<String>()
        .toList();
  }
}
