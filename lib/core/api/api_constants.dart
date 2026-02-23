import 'dart:io';
import 'package:flutter/foundation.dart';

/// Constantes pour l'API GOODLY
/// Support des environnements: development (local) et production (AWS)
class ApiConstants {
  // Détection de l'environnement (défini au build via --dart-define)
  static const String _environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  // URL de l'API pour développement (localhost)
  static const String _devApiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:8000',
  );

  // URL de l'API pour production (Render backend)
  static const String _prodApiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://goodly-backend-6vhs.onrender.com',
  );

  /// URL de base dynamique selon l'environnement et la plateforme
  ///
  /// - Production: Utilise toujours l'URL de production
  /// - Development: Adapte l'URL selon la plateforme (Web, Android, iOS)
  static String get baseUrl {
    // En production, utiliser l'URL de production
    if (_environment == 'production') {
      return _prodApiUrl;
    }
    
    // Détection automatique pour le web en production
    if (kIsWeb) {
      // Si on n'est pas sur localhost, on est en production
      final currentHost = Uri.base.host;
      if (currentHost != 'localhost' && currentHost != '127.0.0.1') {
        return _prodApiUrl;
      }
      return _devApiUrl;
    }

    // Pour l'émulateur Android en développement, utiliser l'alias 10.0.2.2
    if (!kIsWeb && Platform.isAndroid) {
      return _devApiUrl.replaceAll('localhost', '10.0.2.2');
    }

    // Pour les autres plateformes mobiles (iOS, etc.) en développement
    return _devApiUrl;
  }

  /// Vérifie si on est en production
  static bool get isProduction {
    // Si défini explicitement via --dart-define
    if (_environment == 'production') {
      return true;
    }
    // Détection automatique pour le web
    if (kIsWeb) {
      final currentHost = Uri.base.host;
      return currentHost != 'localhost' && currentHost != '127.0.0.1';
    }
    return false;
  }

  /// Vérifie si on est en développement
  static bool get isDevelopment => !isProduction;

  // Endpoints d'authentification
  static const String inscription = '/auth/inscription';
  static const String connexion = '/auth/connexion';
  static const String profil = '/auth/profil';
  static const String mettreAJourProfil = '/auth/profil';
  static const String uploadPhotoProfil = '/auth/profil/photo-profil';
  static String uploadPhotoGalerie(int position) =>
      '/auth/profil/photo-galerie/$position';
  static const String supprimerCompte = '/auth/profil';

  // Endpoints de publications
  static const String creerPublication = '/publications/publications';
  static const String fluxPublications = '/publications/publications/flux';
  static const String mesPublications = '/publications/publications/mes-publications';
  static String publicationsUtilisateur(String userId) => '/publications/publications/utilisateur/$userId';
  static String publication(String id) => '/publications/publications/$id';
  static String supprimerPublication(String id) => '/publications/publications/$id';
  static const String uploadImages = '/publications/upload-images';
  static const String uploadVideos = '/publications/upload-videos';

  // Endpoints d'inspirations
  static const String ajouterInspiration = '/publications/inspirations';
  static String retirerInspiration(String publicationId) =>
      '/publications/inspirations/$publicationId';
  static String compterInspirations(String publicationId) =>
      '/publications/inspirations/$publicationId/count';

  // Endpoints de vues et captivants
  static String enregistrerVue(String publicationId) =>
      '/publications/vues/$publicationId';
  static String enregistrerCaptivant(String publicationId) =>
      '/publications/captivants/$publicationId';

  // Endpoints de signalements
  static const String signalerPublication = '/publications/signalements';

  // Endpoints de modération (admin uniquement)
  static const String publicationsEnAttente =
      '/moderation/publications/en-attente';
  static String approuverPublication(String id) =>
      '/moderation/publications/$id/approuver';
  static String rejeterPublication(String id) =>
      '/moderation/publications/$id/rejeter';
  static String supprimerPublicationAdmin(String id) =>
      '/moderation/publications/$id/supprimer';
  static const String statistiquesPublications =
      '/moderation/publications/statistiques';

  static const String signalementsEnAttente =
      '/moderation/signalements/en-attente';
  static String traiterSignalement(String id) =>
      '/moderation/signalements/$id/traiter';
  static const String statistiquesSignalements =
      '/moderation/signalements/statistiques';

  static String suspendreUtilisateur(String id) =>
      '/moderation/utilisateurs/$id/suspendre';
  static String reactiverUtilisateur(String id) =>
      '/moderation/utilisateurs/$id/reactiver';

  // Endpoints de badges (admin uniquement)
  static const String badges = '/moderation/badges';
  static String attribuerBadge(String userId) =>
      '/moderation/utilisateurs/$userId/attribuer-badge';
  static String attribuerPoints(String userId) =>
      '/moderation/utilisateurs/$userId/attribuer-points';
  static const String rechercherUtilisateurs =
      '/moderation/utilisateurs/rechercher';
  static const String leaderboard = '/moderation/leaderboard';
  static const String statistiquesGlobales =
      '/moderation/statistiques';

  // Endpoints de gestion des administrateurs
  static const String listeUtilisateurs =
      '/moderation/utilisateurs/liste';
  static String promouvoirAdmin(String userId) =>
      '/moderation/utilisateurs/$userId/promouvoir-admin';
  static String retrograderAdmin(String userId) =>
      '/moderation/utilisateurs/$userId/retrograder-admin';

  // Endpoints de badge bleu (certification)
  static const String demanderBadgeBleu = '/moderation/badge-bleu/demande';
  static const String maDemandeBadgeBleu = '/moderation/badge-bleu/ma-demande';
  static const String listeDemandesBadgeBleu = '/moderation/badge-bleu/demandes';
  static String traiterDemandeBadgeBleu(String demandeId) =>
      '/moderation/badge-bleu/demandes/$demandeId/traiter';
  static const String creerSessionPaiement = '/moderation/badge-bleu/creer-session-paiement';
  static String confirmerPaiement(String demandeId) =>
      '/moderation/badge-bleu/confirmer-paiement/$demandeId';
  static const String annulerAbonnement = '/moderation/badge-bleu/annuler-abonnement';
  static String attribuerBadgeBleuAdmin(String userId) =>
      '/moderation/badge-bleu/admin/attribuer/$userId';
  static String retirerBadgeBleuAdmin(String userId) =>
      '/moderation/badge-bleu/admin/retirer/$userId';

  // Endpoints de dons
  static const String creerSessionPaiementDon =
      '/moderation/dons/creer-session-paiement';
  static String confirmerPaiementDon(String paymentIntentId) =>
      '/moderation/dons/confirmer-paiement/$paymentIntentId';
  static const String mesDons = '/moderation/dons/mes-dons';
  static const String adminTousLesDons = '/moderation/dons/admin/tous-les-dons';
  static const String adminStatistiquesDons =
      '/moderation/dons/admin/statistiques';

  // Endpoints de promotion de posts
  static const String publicationsEligibles =
      '/publications/promotion/mes-publications-eligibles';
  static const String creerSessionPaiementPromotion =
      '/publications/promotion/creer-session-paiement';
  static String confirmerPaiementPromotion(String sessionId) =>
      '/publications/promotion/confirmer-paiement/$sessionId';
  static String confirmerPaiementPromotionMobile(String paymentIntentId) =>
      '/publications/promotion/confirmer-paiement-mobile/$paymentIntentId';

  /// Clé publique Stripe selon l'environnement
  ///
  /// - Development: Clé de test
  /// - Production: Clé de production (MODE RÉEL ACTIVÉ)
  static String get stripePublishableKey {
    if (isProduction) {
      // En production, utiliser la VRAIE clé Stripe (ARGENT RÉEL)
      return 'pk_live_51SKnmLIfcuLkeM9x7h2H3fUiSogQjJbuPF8lW1g2BUEAE0r2Jp0qshlSnfzMm4tuvVIFICx7byKebA9zlINZsyI400Jjd3JbtZ';
    }
    // En développement, utiliser la clé de test Stripe (MODE TEST)
    return 'pk_test_51SKnmLIfcuLkeM9xexample'; // TODO: Remplacer par votre vraie clé de test
  }

  // Health check
  static const String health = '/health';

  // Endpoints Analytics
  static const String analyticsStatus = '/moderation/analytics/status';
  static const String analyticsStats = '/moderation/analytics/mes-statistiques';
  static String analyticsPublication(String publicationId) =>
      '/moderation/analytics/publication/$publicationId';
  static const String analyticsSubscribe = '/moderation/analytics/souscrire';
  static String analyticsConfirmPayment(String subscriptionId) =>
      '/moderation/analytics/confirmer-paiement/$subscriptionId';

  // Endpoints Gagnants Mensuels
  static const String monthlyWinners = '/moderation/monthly-winners';
  static String monthlyWinnersByMonth(int annee, int mois) =>
      '/moderation/monthly-winners/$annee/$mois';
  static const String monthlyWinnersEnregistrer = '/moderation/monthly-winners/enregistrer';

  // Endpoints de localisations et événements
  static const String getAllEvents = '/events';
  static String getUserEvents(String userId) => '/events/user/$userId';
  static const String createEvent = '/events';
  static String deleteEvent(String eventId) => '/events/$eventId';
  static const String uploadEventImage = '/upload-event-image';

  // Endpoints de chat/messagerie
  static String get chatConversations => '/api/chat/conversations';
  static String chatConversation(String conversationId) => '/api/chat/conversations/$conversationId';
  static String chatConversationMessages(String conversationId) => '/api/chat/conversations/$conversationId/messages';
  static String chatConversationAccept(String conversationId) => '/api/chat/conversations/$conversationId/accept';
  static String chatConversationReject(String conversationId) => '/api/chat/conversations/$conversationId/reject';
  static String chatConversationInvitation(String conversationId) => '/api/chat/conversations/$conversationId/invitation';
  static String chatConversationDelete(String conversationId) => '/api/chat/conversations/$conversationId';

  // Endpoints de boutiques
  static const String getAllShops = '/shops';
  static const String myShop = '/shops/my-shop';
  static const String createShop = '/shops';
  static const String updateShop = '/shops';
  static const String deleteShop = '/shops';
  static const String nearbyShops = '/shops/nearby';
  static const String shopsByCountry = '/shops/country';
  static const String uploadShopLogo = '/upload-shop-logo';
  static const String uploadShopCover = '/upload-shop-cover';
  static const String uploadProductImage = '/upload-product-image';

  // Endpoints de produits
  static const String getShopProducts = '/products';
  static const String createProduct = '/products';
  static const String updateProduct = '/products';
  static const String deleteProduct = '/products';
  static String getProduct(String productId) => '/products/$productId';

  // ============================================
  // Endpoints de stories géolocalisées
  // En production: /api/stories sur le backend monolithique
  // En développement: port 8007 pour le story_service
  // ============================================
  static String get baseUrlStories {
    if (isProduction) {
      return '$baseUrl/api/stories';
    }
    // En développement, utiliser le port 8007 pour le story_service
    if (kIsWeb) {
      return 'http://localhost:8007';
    }
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:8007';
    }
    return 'http://localhost:8007';
  }

  // ============================================
  // Endpoints du service de publications
  // En production: /publications sur le backend monolithique
  // En développement: port 8002 pour le publications_service
  // ============================================
  static String get publicationsService {
    if (isProduction) {
      return '$baseUrl/publications';
    }
    // En développement, utiliser le port 8002 pour le publications_service
    if (kIsWeb) {
      return 'http://localhost:8002';
    }
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:8002';
    }
    return 'http://localhost:8002';
  }

  // Endpoints de classement local (par zone géographique)
  static const String leaderboardPays = '/leaderboard/pays';
  static String leaderboardVilles(String paysId) => '/leaderboard/villes/$paysId';
  static String leaderboardQuartiers(String villeId) => '/leaderboard/quartiers/$villeId';
  static String leaderboardTop300Pays(String paysId) => '/leaderboard/pays/$paysId/top300';
  static String leaderboardTop300Ville(String villeId) => '/leaderboard/ville/$villeId/top300';
  static String leaderboardTop300Quartier(String quartierId) => '/leaderboard/quartier/$quartierId/top300';
  static const String leaderboardUpdateLocation = '/leaderboard/update-user-location';
  static const String leaderboardRecalculate = '/leaderboard/recalculate';
}