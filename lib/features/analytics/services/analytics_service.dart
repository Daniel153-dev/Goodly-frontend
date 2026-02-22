import '../../../core/api/api_client.dart';
import '../../../core/api/api_constants.dart';

/// Service pour les analytics des publications
class AnalyticsService {
  final ApiClient _apiClient;

  AnalyticsService(this._apiClient);

  /// Vérifie le statut de l'abonnement analytics
  Future<Map<String, dynamic>> getAnalyticsStatus() async {
    try {
      final response = await _apiClient.get(ApiConstants.analyticsStatus);
      return response.data;
    } catch (e) {
      throw Exception('Erreur lors de la vérification du statut analytics: $e');
    }
  }

  /// Récupère les statistiques globales de l'utilisateur
  Future<Map<String, dynamic>> getMyStatistics() async {
    try {
      final response = await _apiClient.get(ApiConstants.analyticsStats);
      return response.data;
    } catch (e) {
      throw Exception('Erreur lors de la récupération des statistiques: $e');
    }
  }

  /// Récupère les statistiques d'une publication spécifique
  Future<Map<String, dynamic>> getPublicationStatistics(String publicationId) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.analyticsPublication(publicationId),
      );
      return response.data;
    } catch (e) {
      throw Exception('Erreur lors de la récupération des statistiques: $e');
    }
  }

  /// Crée une session de paiement pour l'abonnement analytics
  Future<Map<String, dynamic>> createSubscriptionSession({
    String platform = 'mobile',
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.analyticsSubscribe,
        queryParameters: {'platform': platform},
      );
      return response.data;
    } catch (e) {
      throw Exception('Erreur lors de la création de la session de paiement: $e');
    }
  }

  /// Confirme le paiement de l'abonnement analytics
  Future<Map<String, dynamic>> confirmPayment(String subscriptionId) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.analyticsConfirmPayment(subscriptionId),
      );
      return response.data;
    } catch (e) {
      throw Exception('Erreur lors de la confirmation du paiement: $e');
    }
  }
}
