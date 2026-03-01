import 'package:flutter/foundation.dart';
import '../../../shared/models/publication.dart';
import '../../../shared/models/signalement.dart';
import '../../../shared/models/badge.dart';
import '../../../shared/models/utilisateur.dart';
import '../services/moderation_service.dart';

/// Provider pour la gestion de la modération (admin)
class ModerationProvider with ChangeNotifier {
  final ModerationService _moderationService;

  List<Publication> _publicationsEnAttente = [];
  List<Signalement> _signalementsEnAttente = [];
  List<BadgeModel> _badges = [];
  List<Utilisateur> _utilisateursRecherche = [];
  Map<String, dynamic>? _statistiques;

  bool _isLoading = false;
  bool _isProcessing = false;
  String? _errorMessage;

  ModerationProvider(this._moderationService);

  // Getters
  List<Publication> get publicationsEnAttente => _publicationsEnAttente;
  List<Signalement> get signalementsEnAttente => _signalementsEnAttente;
  List<BadgeModel> get badges => _badges;
  List<Utilisateur> get utilisateursRecherche => _utilisateursRecherche;
  Map<String, dynamic>? get statistiques => _statistiques;
  bool get isLoading => _isLoading;
  bool get isProcessing => _isProcessing;
  String? get errorMessage => _errorMessage;

  // ==================== PUBLICATIONS ====================

  /// Charge les publications en attente de modération
  Future<void> chargerPublicationsEnAttente() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _publicationsEnAttente = await _moderationService.obtenirPublicationsEnAttente();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Approuve une publication
  Future<bool> approuverPublication(String publicationId) async {
    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _moderationService.approuverPublication(publicationId);

      // Retirer de la liste des publications en attente
      _publicationsEnAttente.removeWhere(
        (pub) => pub.idPublication == publicationId,
      );

      _isProcessing = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isProcessing = false;
      notifyListeners();
      return false;
    }
  }

  /// Rejette une publication
  Future<bool> rejeterPublication(String publicationId, String raison) async {
    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _moderationService.rejeterPublication(publicationId, raison);

      // Retirer de la liste des publications en attente
      _publicationsEnAttente.removeWhere(
        (pub) => pub.idPublication == publicationId,
      );

      _isProcessing = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isProcessing = false;
      notifyListeners();
      return false;
    }
  }

  /// Supprime une publication (admin only)
  Future<bool> supprimerPublication(String publicationId, {String? raison}) async {
    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _moderationService.supprimerPublication(publicationId, raison: raison);

      // Retirer de la liste des publications en attente si présente
      _publicationsEnAttente.removeWhere(
        (pub) => pub.idPublication == publicationId,
      );

      _isProcessing = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isProcessing = false;
      notifyListeners();
      return false;
    }
  }

  // ==================== SIGNALEMENTS ====================

  /// Charge les signalements en attente
  Future<void> chargerSignalementsEnAttente() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _signalementsEnAttente = await _moderationService.obtenirSignalementsEnAttente();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Traite un signalement (approuve ou ignore)
  Future<bool> traiterSignalement(String signalementId, String action) async {
    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _moderationService.traiterSignalement(signalementId, action);

      // Retirer de la liste des signalements en attente
      _signalementsEnAttente.removeWhere(
        (sig) => sig.idSignalement == signalementId,
      );

      _isProcessing = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isProcessing = false;
      notifyListeners();
      return false;
    }
  }

  // ==================== BADGES ====================

  /// Charge tous les badges disponibles
  Future<void> chargerBadges() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _badges = await _moderationService.obtenirBadges();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Attribue un badge à un utilisateur
  Future<bool> attribuerBadge({
    required String userId,
    required String badgeId,
    String? message,
  }) async {
    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _moderationService.attribuerBadge(
        userId: userId,
        badgeId: badgeId,
        message: message,
      );

      _isProcessing = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isProcessing = false;
      notifyListeners();
      return false;
    }
  }

  /// Attribue des points à un utilisateur
  Future<bool> attribuerPoints({
    required String userId,
    required int points,
  }) async {
    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _moderationService.attribuerPoints(
        userId: userId,
        points: points,
      );

      _isProcessing = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isProcessing = false;
      notifyListeners();
      return false;
    }
  }

  /// Recherche des utilisateurs
  Future<void> rechercherUtilisateurs(String query) async {
    if (query.isEmpty) {
      _utilisateursRecherche = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _utilisateursRecherche = await _moderationService.rechercherUtilisateurs(query);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Efface les résultats de recherche
  void effacerRecherche() {
    _utilisateursRecherche = [];
    notifyListeners();
  }

  // ==================== STATISTIQUES ====================

  /// Charge les statistiques globales
  Future<void> chargerStatistiques() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _statistiques = await _moderationService.obtenirStatistiques();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Efface le message d'erreur
  void effacerErreur() {
    _errorMessage = null;
    notifyListeners();
  }

  // ==================== GESTION DES ADMINISTRATEURS ====================

  /// Charge la liste de tous les utilisateurs
  Future<List<Utilisateur>> chargerListeUtilisateurs() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final utilisateurs = await _moderationService.obtenirListeUtilisateurs();
      _isLoading = false;
      notifyListeners();
      return utilisateurs;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Promeut un utilisateur au rôle d'administrateur
  Future<void> promouvoirAdmin(String userId) async {
    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _moderationService.promouvoirAdmin(userId);
      _isProcessing = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isProcessing = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Rétrograde un administrateur au rôle d'utilisateur
  Future<void> retrograderAdmin(String userId) async {
    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _moderationService.retrograderAdmin(userId);
      _isProcessing = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isProcessing = false;
      notifyListeners();
      rethrow;
    }
  }
}
