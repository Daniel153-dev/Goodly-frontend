import '../../../core/api/api_client.dart';
import '../../../core/api/api_constants.dart';
import '../../../shared/models/publication.dart';

/// Service de gestion de la promotion de posts
class PromotionService {
  final ApiClient _apiClient;

  PromotionService(this._apiClient);

  /// Récupère les publications éligibles pour la promotion
  Future<List<Publication>> obtenirPublicationsEligibles() async {
    try {
      final response = await _apiClient.get(
        ApiConstants.publicationsEligibles,
      );

      if (response.data == null) {
        throw Exception('Aucune données reçues du serveur');
      }

      // Gérer le cas où la réponse est une liste vide
      if (response.data is! List) {
        throw Exception('Format de réponse invalide: attendu une liste');
      }

      final publications = (response.data as List)
          .map((json) {
            try {
              return Publication.fromJson(json as Map<String, dynamic>);
            } catch (e) {
              throw Exception('Erreur lors du décodage de la publication: $e');
            }
          })
          .toList();

      return publications;
    } catch (e) {
      throw Exception('Erreur lors de la récupération des publications éligibles: $e');
    }
  }

  /// Crée une session de paiement Stripe pour promouvoir une publication
  Future<Map<String, dynamic>> creerSessionPaiement(String publicationId, {String platform = 'mobile'}) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.creerSessionPaiementPromotion,
        queryParameters: {
          'publication_id': publicationId,
          'platform': platform,
        },
      );

      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Erreur lors de la création de la session de paiement: $e');
    }
  }

  /// Confirme le paiement de la promotion (web - via session_id)
  Future<void> confirmerPaiement(String sessionId) async {
    try {
      await _apiClient.post(
        ApiConstants.confirmerPaiementPromotion(sessionId),
      );
    } catch (e) {
      throw Exception('Erreur lors de la confirmation du paiement: $e');
    }
  }

  /// Confirme le paiement de la promotion (mobile - via payment_intent_id)
  Future<void> confirmerPaiementMobile(String paymentIntentId, String publicationId) async {
    try {
      await _apiClient.post(
        ApiConstants.confirmerPaiementPromotionMobile(paymentIntentId),
        queryParameters: {'publication_id': publicationId},
      );
    } catch (e) {
      throw Exception('Erreur lors de la confirmation du paiement: $e');
    }
  }
}
