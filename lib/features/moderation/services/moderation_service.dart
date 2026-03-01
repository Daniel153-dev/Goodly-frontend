import '../../../core/api/api_client.dart';
import '../../../core/api/api_constants.dart';
import '../../../shared/models/publication.dart';
import '../../../shared/models/signalement.dart';
import '../../../shared/models/badge.dart';
import '../../../shared/models/utilisateur.dart';

/// Service de gestion de la modération (admin)
class ModerationService {
  final ApiClient _apiClient;

  ModerationService(this._apiClient);

  // ==================== PUBLICATIONS ====================

  /// Récupère les publications en attente de modération
  Future<List<Publication>> obtenirPublicationsEnAttente() async {
    try {
      final response = await _apiClient.get(
        ApiConstants.publicationsEnAttente,
      );

      return (response.data as List)
          .map((json) => Publication.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des publications en attente: $e');
    }
  }

  /// Approuve une publication
  Future<void> approuverPublication(String publicationId) async {
    try {
      await _apiClient.post(
        ApiConstants.approuverPublication(publicationId),
      );
    } catch (e) {
      throw Exception('Erreur lors de l\'approbation de la publication: $e');
    }
  }

  /// Rejette une publication avec une raison
  Future<void> rejeterPublication(String publicationId, String raison) async {
    try {
      await _apiClient.post(
        ApiConstants.rejeterPublication(publicationId),
        data: {
          'raison_rejet': raison,
        },
      );
    } catch (e) {
      throw Exception('Erreur lors du rejet de la publication: $e');
    }
  }

  /// Supprime une publication (admin only)
  Future<void> supprimerPublication(String publicationId, {String? raison}) async {
    try {
      await _apiClient.delete(
        ApiConstants.supprimerPublicationAdmin(publicationId),
        queryParameters: {
          'raison': raison ?? 'Supprimée par un administrateur',
        },
      );
    } catch (e) {
      throw Exception('Erreur lors de la suppression de la publication: $e');
    }
  }

  // ==================== SIGNALEMENTS ====================

  /// Récupère les signalements en attente de traitement
  Future<List<Signalement>> obtenirSignalementsEnAttente() async {
    try {
      final response = await _apiClient.get(
        ApiConstants.signalementsEnAttente,
      );

      return (response.data as List)
          .map((json) => Signalement.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des signalements: $e');
    }
  }

  /// Traite un signalement (approuve ou ignore)
  Future<void> traiterSignalement(String signalementId, String action) async {
    try {
      await _apiClient.post(
        ApiConstants.traiterSignalement(signalementId),
        data: {'action': action},
      );
    } catch (e) {
      throw Exception('Erreur lors du traitement du signalement: $e');
    }
  }

  // ==================== BADGES ====================

  /// Récupère tous les badges disponibles
  Future<List<BadgeModel>> obtenirBadges() async {
    try {
      final response = await _apiClient.get(
        ApiConstants.badges,
      );

      return (response.data as List)
          .map((json) => BadgeModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des badges: $e');
    }
  }

  /// Attribue un badge à un utilisateur
  Future<void> attribuerBadge({
    required String userId,
    required String badgeId,
    String? message,
  }) async {
    try {
      await _apiClient.post(
        ApiConstants.attribuerBadge(userId),
        data: {
          'id_badge': badgeId,
          if (message != null) 'message': message,
        },
      );
    } catch (e) {
      throw Exception('Erreur lors de l\'attribution du badge: $e');
    }
  }

  /// Attribue des points à un utilisateur
  Future<void> attribuerPoints({
    required String userId,
    required int points,
  }) async {
    try {
      await _apiClient.post(
        ApiConstants.attribuerPoints(userId),
        data: {
          'points': points,
        },
      );
    } catch (e) {
      throw Exception('Erreur lors de l\'attribution des points: $e');
    }
  }

  /// Recherche des utilisateurs par nom ou email
  Future<List<Utilisateur>> rechercherUtilisateurs(String query) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.rechercherUtilisateurs,
        queryParameters: {'q': query},
      );

      return (response.data as List)
          .map((json) => Utilisateur.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la recherche d\'utilisateurs: $e');
    }
  }

  // ==================== STATISTIQUES ====================

  /// Récupère les statistiques globales de modération
  Future<Map<String, dynamic>> obtenirStatistiques() async {
    try {
      final response = await _apiClient.get(
        ApiConstants.statistiquesGlobales,
      );

      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Erreur lors de la récupération des statistiques: $e');
    }
  }

  // ==================== GESTION DES ADMINISTRATEURS ====================

  /// Récupère la liste de tous les utilisateurs
  Future<List<Utilisateur>> obtenirListeUtilisateurs() async {
    try {
      final response = await _apiClient.get(
        ApiConstants.listeUtilisateurs,
      );

      return (response.data as List)
          .map((json) => Utilisateur.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération de la liste des utilisateurs: $e');
    }
  }

  /// Promeut un utilisateur au rôle d'administrateur
  Future<void> promouvoirAdmin(String userId) async {
    try {
      await _apiClient.post(
        ApiConstants.promouvoirAdmin(userId),
      );
    } catch (e) {
      throw Exception('Erreur lors de la promotion de l\'administrateur: $e');
    }
  }

  /// Rétrograde un administrateur au rôle d'utilisateur
  Future<void> retrograderAdmin(String userId) async {
    try {
      await _apiClient.post(
        ApiConstants.retrograderAdmin(userId),
      );
    } catch (e) {
      throw Exception('Erreur lors de la rétrogradation de l\'administrateur: $e');
    }
  }
}
