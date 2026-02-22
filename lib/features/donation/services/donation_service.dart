import '../../../core/api/api_client.dart';
import '../../../core/api/api_constants.dart';
import '../../../shared/models/don.dart';

/// Service de gestion des dons
class DonationService {
  final ApiClient _apiClient;

  DonationService(this._apiClient);

  /// Récupère l'historique des dons de l'utilisateur
  Future<List<Don>> obtenirMesDons() async {
    try {
      final response = await _apiClient.get(ApiConstants.mesDons);

      return (response.data as List).map((json) => Don.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des dons: $e');
    }
  }

  /// Récupère tous les dons (admin uniquement)
  Future<List<Map<String, dynamic>>> obtenirTousLesDons({
    int skip = 0,
    int limit = 100,
  }) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.adminTousLesDons}?skip=$skip&limit=$limit',
      );

      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      throw Exception('Erreur lors de la récupération de tous les dons: $e');
    }
  }

  /// Récupère les statistiques des dons (admin uniquement)
  Future<DonStatistiques> obtenirStatistiquesDons() async {
    try {
      final response = await _apiClient.get(
        ApiConstants.adminStatistiquesDons,
      );

      return DonStatistiques.fromJson(response.data);
    } catch (e) {
      throw Exception('Erreur lors de la récupération des statistiques: $e');
    }
  }
}
