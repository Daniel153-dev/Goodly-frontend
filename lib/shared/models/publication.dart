import '../../core/api/api_constants.dart';

/// Modèle Publication pour GOODLY
class Publication {
  final String idPublication;
  final String idUtilisateur;
  final String titre;
  final String description;
  final String typeContenu;
  final List<String> imagesUrls;
  final List<String> videosUrls;
  final String? videoThumbnail;
  final String? categorie;
  final String? geolocalisation;
  final double? latitude;
  final double? longitude;
  // Champs de localisation automatique (via reverse geocoding)
  final String? quartier;
  final String? ville;
  final String? paysLocation;
  final String statut;
  final String? raisonRejet;
  final int nombreInspirations;
  final int nombreVues;
  final int nombreCaptivants;
  final DateTime dateCreation;
  final DateTime? dateValidation;

  // Champs additionnels pour PublicationAvecUtilisateur
  final String? nomUtilisateur;
  final String? photoProfil;
  final bool? badgeBleu;
  final bool aInspire;
  final bool aVu;
  final bool aCaptive;

  // Champs de promotion
  final bool estPromu;
  final DateTime? dateFinPromotion;

  Publication({
    required this.idPublication,
    required this.idUtilisateur,
    required this.titre,
    required this.description,
    required this.typeContenu,
    required this.imagesUrls,
    this.videosUrls = const [],
    this.videoThumbnail,
    this.categorie,
    this.geolocalisation,
    this.latitude,
    this.longitude,
    this.quartier,
    this.ville,
    this.paysLocation,
    required this.statut,
    this.raisonRejet,
    required this.nombreInspirations,
    this.nombreVues = 0,
    this.nombreCaptivants = 0,
    required this.dateCreation,
    this.dateValidation,
    this.nomUtilisateur,
    this.photoProfil,
    this.badgeBleu,
    this.aInspire = false,
    this.aVu = false,
    this.aCaptive = false,
    this.estPromu = false,
    this.dateFinPromotion,
  });

  /// Crée une publication à partir d'un JSON
  factory Publication.fromJson(Map<String, dynamic> json) {
    return Publication(
      idPublication: json['id_publication'],
      idUtilisateur: json['id_utilisateur'],
      titre: json['titre'],
      description: json['description'],
      typeContenu: json['type_contenu'],
      imagesUrls: List<String>.from(json['images_urls'] ?? []),
      videosUrls: List<String>.from(json['videos_urls'] ?? []),
      videoThumbnail: json['video_thumbnail'],
      categorie: json['categorie'],
      geolocalisation: json['geolocalisation'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      quartier: json['quartier'],
      ville: json['ville'],
      paysLocation: json['pays_location'],
      statut: json['statut'],
      raisonRejet: json['raison_rejet'],
      nombreInspirations: json['nombre_inspirations'] ?? 0,
      nombreVues: json['nombre_vues'] ?? 0,
      nombreCaptivants: json['nombre_captivants'] ?? 0,
      dateCreation: DateTime.parse(json['date_creation']),
      dateValidation: json['date_validation'] != null
          ? DateTime.parse(json['date_validation'])
          : null,
      nomUtilisateur: json['nom_utilisateur'],
      photoProfil: json['photo_profil'],
      badgeBleu: json['badge_bleu'],
      aInspire: json['a_inspire'] ?? false,
      aVu: json['a_vu'] ?? false,
      aCaptive: json['a_captive'] ?? false,
      estPromu: json['est_promu'] ?? false,
      dateFinPromotion: json['date_fin_promotion'] != null
          ? DateTime.parse(json['date_fin_promotion'])
          : null,
    );
  }

  /// Convertit la publication en JSON
  Map<String, dynamic> toJson() {
    return {
      'id_publication': idPublication,
      'id_utilisateur': idUtilisateur,
      'titre': titre,
      'description': description,
      'type_contenu': typeContenu,
      'images_urls': imagesUrls,
      'videos_urls': videosUrls,
      'video_thumbnail': videoThumbnail,
      'categorie': categorie,
      'geolocalisation': geolocalisation,
      'latitude': latitude,
      'longitude': longitude,
      'quartier': quartier,
      'ville': ville,
      'pays_location': paysLocation,
      'statut': statut,
      'raison_rejet': raisonRejet,
      'nombre_inspirations': nombreInspirations,
      'nombre_vues': nombreVues,
      'nombre_captivants': nombreCaptivants,
      'date_creation': dateCreation.toIso8601String(),
      'date_validation': dateValidation?.toIso8601String(),
      'nom_utilisateur': nomUtilisateur,
      'photo_profil': photoProfil,
      'badge_bleu': badgeBleu,
      'a_inspire': aInspire,
      'a_vu': aVu,
      'a_captive': aCaptive,
      'est_promu': estPromu,
      'date_fin_promotion': dateFinPromotion?.toIso8601String(),
    };
  }

  /// Copie la publication avec des modifications
  Publication copyWith({
    String? idPublication,
    String? idUtilisateur,
    String? titre,
    String? description,
    String? typeContenu,
    List<String>? imagesUrls,
    List<String>? videosUrls,
    String? videoThumbnail,
    String? categorie,
    String? geolocalisation,
    double? latitude,
    double? longitude,
    String? quartier,
    String? ville,
    String? paysLocation,
    String? statut,
    String? raisonRejet,
    int? nombreInspirations,
    int? nombreVues,
    int? nombreCaptivants,
    DateTime? dateCreation,
    DateTime? dateValidation,
    String? nomUtilisateur,
    String? photoProfil,
    bool? badgeBleu,
    bool? aInspire,
    bool? aVu,
    bool? aCaptive,
    bool? estPromu,
    DateTime? dateFinPromotion,
  }) {
    return Publication(
      idPublication: idPublication ?? this.idPublication,
      idUtilisateur: idUtilisateur ?? this.idUtilisateur,
      titre: titre ?? this.titre,
      description: description ?? this.description,
      typeContenu: typeContenu ?? this.typeContenu,
      imagesUrls: imagesUrls ?? this.imagesUrls,
      videosUrls: videosUrls ?? this.videosUrls,
      videoThumbnail: videoThumbnail ?? this.videoThumbnail,
      categorie: categorie ?? this.categorie,
      geolocalisation: geolocalisation ?? this.geolocalisation,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      quartier: quartier ?? this.quartier,
      ville: ville ?? this.ville,
      paysLocation: paysLocation ?? this.paysLocation,
      statut: statut ?? this.statut,
      raisonRejet: raisonRejet ?? this.raisonRejet,
      nombreInspirations: nombreInspirations ?? this.nombreInspirations,
      nombreVues: nombreVues ?? this.nombreVues,
      nombreCaptivants: nombreCaptivants ?? this.nombreCaptivants,
      dateCreation: dateCreation ?? this.dateCreation,
      dateValidation: dateValidation ?? this.dateValidation,
      nomUtilisateur: nomUtilisateur ?? this.nomUtilisateur,
      photoProfil: photoProfil ?? this.photoProfil,
      badgeBleu: badgeBleu ?? this.badgeBleu,
      aInspire: aInspire ?? this.aInspire,
      aVu: aVu ?? this.aVu,
      aCaptive: aCaptive ?? this.aCaptive,
      estPromu: estPromu ?? this.estPromu,
      dateFinPromotion: dateFinPromotion ?? this.dateFinPromotion,
    );
  }

  /// Retourne la localisation formatée pour l'affichage
  String get locationDisplay {
    final parts = <String>[];
    if (quartier != null && quartier != 'Inconnu' && quartier!.isNotEmpty) {
      parts.add(quartier!);
    }
    if (ville != null && ville != 'Inconnu' && ville!.isNotEmpty) {
      parts.add(ville!);
    }
    if (paysLocation != null && paysLocation != 'Inconnu' && paysLocation!.isNotEmpty) {
      parts.add(paysLocation!);
    }
    if (parts.isEmpty && geolocalisation != null && geolocalisation!.isNotEmpty) {
      return geolocalisation!;
    }
    return parts.join(', ');
  }

  /// Vérifie si c'est une photo unique
  bool get isPhotoUnique => typeContenu == 'photo_unique';

  /// Vérifie si c'est un carrousel
  bool get isCarrousel => typeContenu == 'carrousel';

  /// Vérifie si la publication est approuvée
  bool get isApprouvee => statut == 'approuve';

  /// Vérifie si la publication est en attente
  bool get isEnAttente => statut == 'en_attente';

  /// Vérifie si la publication est rejetée
  bool get isRejetee => statut == 'rejete';

  /// Convertit une URL relative en URL absolue
  String? _getFullImageUrl(String? relativeUrl) {
    if (relativeUrl == null || relativeUrl.isEmpty) return null;
    if (relativeUrl.startsWith('http://') || relativeUrl.startsWith('https://')) {
      return relativeUrl; // Déjà une URL absolue
    }

    // Normaliser les backslashes en forward slashes pour le web
    String normalizedUrl = relativeUrl.replaceAll('\\', '/');

    // Assurer qu'il y a un / au début du path si nécessaire
    if (!normalizedUrl.startsWith('/')) {
      normalizedUrl = '/$normalizedUrl';
    }

    return '${ApiConstants.baseUrl}$normalizedUrl';
  }

  /// URL complète de la photo de profil de l'utilisateur
  String? get photoProfilUrl => _getFullImageUrl(photoProfil);

  /// URLs complètes des images de la publication
  List<String> get imagesUrlsFull {
    return imagesUrls.map((url) => _getFullImageUrl(url) ?? url).toList();
  }

  /// URLs complètes des vidéos de la publication
  List<String> get videosUrlsFull {
    return videosUrls.map((url) => _getFullImageUrl(url) ?? url).toList();
  }

  /// URL complète de la miniature vidéo
  String? get videoThumbnailUrl => _getFullImageUrl(videoThumbnail);

  /// Récupère l'icône de la catégorie
  String get categorieIcon {
    switch (categorie) {
      case 'environnement':
        return '🌱';
      case 'social':
        return '🤝';
      case 'aide_animaliere':
        return '🐾';
      case 'education':
        return '📚';
      case 'sante':
        return '💊';
      default:
        return '❤️';
    }
  }

  /// Récupère le label de la catégorie
  String get categorieLabel {
    switch (categorie) {
      case 'environnement':
        return 'Environnement';
      case 'social':
        return 'Social';
      case 'aide_animaliere':
        return 'Aide animalière';
      case 'education':
        return 'Éducation';
      case 'sante':
        return 'Santé';
      default:
        return 'Autre';
    }
  }
}
