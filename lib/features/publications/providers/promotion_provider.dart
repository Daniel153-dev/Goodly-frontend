import 'package:flutter/foundation.dart';
import '../../../shared/models/publication.dart';
import '../services/promotion_service.dart';

/// Provider pour la gestion de la promotion de posts
class PromotionProvider with ChangeNotifier {
  final PromotionService _promotionService;

  List<Publication> _publicationsEligibles = [];
  bool _isLoading = false;
  String? _errorMessage;

  PromotionProvider(this._promotionService);

  List<Publication> get publicationsEligibles => _publicationsEligibles;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Charge les publications éligibles
  Future<void> chargerPublicationsEligibles() async {
    if (_isLoading) return; // Éviter les requêtes multiples
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final publications = await _promotionService.obtenirPublicationsEligibles();
      _publicationsEligibles = publications ?? [];
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
      
      if (kDebugMode) {
        print('✓ ${_publicationsEligibles.length} publications éligibles chargées');
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _publicationsEligibles = [];
      _isLoading = false;
      notifyListeners();
      
      if (kDebugMode) {
        print('✗ Erreur lors du chargement: $_errorMessage');
      }
    }
  }

  /// Crée une session de paiement
  Future<Map<String, dynamic>?> creerSessionPaiement(String publicationId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final session = await _promotionService.creerSessionPaiement(publicationId);
      _isLoading = false;
      notifyListeners();
      return session;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Confirme le paiement (pour web - via session_id)
  Future<bool> confirmerPaiement(String sessionId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _promotionService.confirmerPaiement(sessionId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Confirme le paiement mobile (via payment_intent_id)
  Future<bool> confirmerPaiementMobile(String paymentIntentId, String publicationId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _promotionService.confirmerPaiementMobile(paymentIntentId, publicationId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
