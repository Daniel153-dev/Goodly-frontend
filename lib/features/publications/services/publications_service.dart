import 'package:image_picker/image_picker.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_constants.dart';
import '../../../shared/models/publication.dart';

/// Service de gestion des publications
class PublicationsService {
  final ApiClient _apiClient;

  PublicationsService(this._apiClient);

  /// Crée une nouvelle publication
  Future<Publication> creerPublication({
    required String titre,
    required String description,
    required String typeContenu,
    List<String> imagesUrls = const [],
    List<String> videosUrls = const [],
    String? videoThumbnail,
    String? categorie,
    String? geolocalisation,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.creerPublication,
        data: {
          'titre': titre,
          'description': description,
          'type_contenu': typeContenu,
          if (imagesUrls.isNotEmpty) 'images_urls': imagesUrls,
          if (videosUrls.isNotEmpty) 'videos_urls': videosUrls,
          if (videoThumbnail != null) 'video_thumbnail': videoThumbnail,
          if (categorie != null) 'categorie': categorie,
          if (geolocalisation != null) 'geolocalisation': geolocalisation,
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
        },
      );

      return Publication.fromJson(response.data);
    } catch (e) {
      throw Exception('Erreur lors de la création de la publication: $e');
    }
  }

  /// Récupère le flux des publications approuvées
  Future<List<Publication>> obtenirFluxPublications({
    int skip = 0,
    int limit = 20,
    String? categorie,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'skip': skip,
        'limit': limit,
        if (categorie != null) 'categorie': categorie,
      };

      final response = await _apiClient.get(
        ApiConstants.fluxPublications,
        queryParameters: queryParams,
      );

      return (response.data as List)
          .map((json) => Publication.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération du flux: $e');
    }
  }

  /// Récupère les publications de l'utilisateur connecté
  Future<List<Publication>> obtenirMesPublications() async {
    try {
      final response = await _apiClient.get(ApiConstants.mesPublications);

      return (response.data as List)
          .map((json) => Publication.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des publications: $e');
    }
  }

  /// Récupère les publications d'un utilisateur spécifique par son ID
  Future<List<Publication>> obtenirPublicationsUtilisateur(String userId) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.publicationsUtilisateur(userId),
      );

      return (response.data as List)
          .map((json) => Publication.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des publications de l\'utilisateur: $e');
    }
  }

  /// Récupère une publication par son ID
  Future<Publication> obtenirPublication(String publicationId) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.publication(publicationId),
      );

      return Publication.fromJson(response.data);
    } catch (e) {
      throw Exception('Erreur lors de la récupération de la publication: $e');
    }
  }

  /// Supprime une publication
  Future<void> supprimerPublication(String publicationId) async {
    try {
      await _apiClient.delete(
        ApiConstants.supprimerPublication(publicationId),
      );
    } catch (e) {
      throw Exception('Erreur lors de la suppression de la publication: $e');
    }
  }

  /// Upload des images pour une publication
  Future<List<String>> uploadImages(List<XFile> files) async {
    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        final response = await _apiClient.uploadFiles(
          ApiConstants.uploadImages,
          files,
        );

        return List<String>.from(response.data['urls']);
      } catch (e) {
        retryCount++;
        if (retryCount >= maxRetries) {
          throw Exception('Erreur lors de l\'upload des images après $maxRetries tentatives: $e');
        }
        // Attendre avant de réessayer
        await Future.delayed(Duration(seconds: retryCount));
      }
    }
    
    throw Exception('Erreur lors de l\'upload des images');
  }

  /// Upload des vidéos pour une publication
  Future<List<String>> uploadVideos(List<XFile> files) async {
    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        final response = await _apiClient.uploadFiles(
          ApiConstants.uploadVideos,
          files,
        );

        return List<String>.from(response.data['urls']);
      } catch (e) {
        retryCount++;
        if (retryCount >= maxRetries) {
          throw Exception('Erreur lors de l\'upload des vidéos après $maxRetries tentatives: $e');
        }
        // Attendre avant de réessayer
        await Future.delayed(Duration(seconds: retryCount));
      }
    }
    
    throw Exception('Erreur lors de l\'upload des vidéos');
  }

  /// Ajoute une inspiration à une publication
  Future<void> ajouterInspiration(String publicationId) async {
    try {
      await _apiClient.post(
        ApiConstants.ajouterInspiration,
        data: {'id_publication': publicationId},
      );
    } catch (e) {
      throw Exception('Erreur lors de l\'ajout de l\'inspiration: $e');
    }
  }

  /// Retire une inspiration d'une publication
  Future<void> retirerInspiration(String publicationId) async {
    try {
      await _apiClient.delete(
        ApiConstants.retirerInspiration(publicationId),
      );
    } catch (e) {
      throw Exception('Erreur lors du retrait de l\'inspiration: $e');
    }
  }

  /// Compte le nombre d'inspirations d'une publication
  Future<int> compterInspirations(String publicationId) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.compterInspirations(publicationId),
      );

      return response.data['count'];
    } catch (e) {
      throw Exception('Erreur lors du comptage des inspirations: $e');
    }
  }

  /// Signale une publication
  Future<void> signalerPublication({
    required String publicationId,
    required String motif,
    String? description,
  }) async {
    try {
      await _apiClient.post(
        ApiConstants.signalerPublication,
        data: {
          'id_publication': publicationId,
          'motif': motif,
          if (description != null) 'description': description,
        },
      );
    } catch (e) {
      throw Exception('Erreur lors du signalement de la publication: $e');
    }
  }

  /// Enregistre une vue sur une publication (après 30 secondes de visibilité)
  Future<Map<String, dynamic>> enregistrerVue(String publicationId) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.enregistrerVue(publicationId),
      );

      return response.data;
    } catch (e) {
      throw Exception('Erreur lors de l\'enregistrement de la vue: $e');
    }
  }

  /// Enregistre un captivant sur une publication (après 1 minute à 100% visible)
  Future<Map<String, dynamic>> enregistrerCaptivant(String publicationId) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.enregistrerCaptivant(publicationId),
      );

      return response.data;
    } catch (e) {
      throw Exception('Erreur lors de l\'enregistrement du captivant: $e');
    }
  }
}
