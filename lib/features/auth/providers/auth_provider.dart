import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../shared/models/utilisateur.dart';
import '../../../shared/models/user_session.dart';
import '../services/auth_service.dart';

/// Provider pour la gestion de l'authentification
class AuthProvider with ChangeNotifier {
  final AuthService _authService;

  Utilisateur? _utilisateur;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isAuthenticated = false;
  List<UserSession> _sessionsMemorisees = [];
  bool _isCheckingAuth = true;

  AuthProvider(this._authService) {
    _checkAuthStatus();
  }

  // Getters
  Utilisateur? get utilisateur => _utilisateur;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _isAuthenticated;
  bool get isAdmin => _utilisateur?.isAdmin ?? false;
  List<UserSession> get sessionsMemorisees => _sessionsMemorisees;
  bool get isCheckingAuth => _isCheckingAuth;

  /// Vérifie le statut d'authentification au démarrage
  Future<void> _checkAuthStatus() async {
    _isCheckingAuth = true;
    notifyListeners();
    
    try {
      _isAuthenticated = await _authService.estConnecte();
      
      // Charger les sessions mémorisées
      _sessionsMemorisees = await _authService.getSessionsMemorisees();
      
      if (_isAuthenticated) {
        await loadUserProfile();
      }
    } catch (e) {
      _isAuthenticated = false;
    }
    _isCheckingAuth = false;
    notifyListeners();
  }

  /// Inscription d'un nouvel utilisateur
  Future<bool> inscription({
    required String nomUtilisateur,
    required String email,
    required String motDePasse,
    required String numeroTelephone,
    required String codePays,
    String? pays,
    DateTime? dateNaissance,
    String? sexe,
    String? biographie,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _utilisateur = await _authService.inscription(
        nomUtilisateur: nomUtilisateur,
        email: email,
        motDePasse: motDePasse,
        numeroTelephone: numeroTelephone,
        codePays: codePays,
        pays: pays,
        dateNaissance: dateNaissance,
        sexe: sexe,
        biographie: biographie,
      );

      _isAuthenticated = true;
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  /// Connexion d'un utilisateur
  Future<bool> connexion({
    required String email,
    required String motDePasse,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _utilisateur = await _authService.connexion(
        email: email,
        motDePasse: motDePasse,
      );

      _isAuthenticated = true;
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  /// Connexion avec Google
  Future<bool> connexionGoogle() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _utilisateur = await _authService.connexionGoogle();
      _isAuthenticated = true;
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  /// Connexion avec Apple (iCloud)
  Future<bool> connexionApple() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _utilisateur = await _authService.connexionApple();
      _isAuthenticated = true;
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  /// Connexion avec Yahoo
  Future<bool> connexionYahoo() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _utilisateur = await _authService.connexionYahoo();
      _isAuthenticated = true;
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  /// Déconnexion
  Future<void> deconnexion() async {
    await _authService.deconnexion();
    _utilisateur = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  /// Charge le profil de l'utilisateur
  Future<void> loadUserProfile() async {
    try {
      _utilisateur = await _authService.obtenirProfil();
      print('[AUTH] Profil chargé: ${_utilisateur?.nomUtilisateur}');
      print('[AUTH] Photo profil: ${_utilisateur?.photoProfil}');
      print('[AUTH] Photo profil URL: ${_utilisateur?.photoProfilUrl}');
      _isAuthenticated = true;
      notifyListeners();
    } catch (e) {
      print('[AUTH] Erreur lors du chargement du profil: $e');
      _errorMessage = e.toString();
      _isAuthenticated = false;
      notifyListeners();
    }
  }

  /// Met à jour le profil
  Future<bool> mettreAJourProfil({
    String? nomUtilisateur,
    String? biographie,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _utilisateur = await _authService.mettreAJourProfil(
        nomUtilisateur: nomUtilisateur,
        biographie: biographie,
      );

      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  /// Upload une photo de profil
  Future<bool> uploadPhotoProfil(XFile file) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      // Sauvegarder l'ancienne URL pour nettoyer le cache
      final ancienneUrl = _utilisateur?.photoProfilUrl;

      // Uploader la photo
      await _authService.uploadPhotoProfil(file);

      // Nettoyer le cache de l'ancienne image si elle existe
      if (ancienneUrl != null) {
        await CachedNetworkImage.evictFromCache(ancienneUrl);
      }

      // Recharger le profil pour obtenir la nouvelle URL complète
      await loadUserProfile();
      
      // Nettoyer le cache de la nouvelle URL pour forcer le rechargement
      final nouvelleUrl = _utilisateur?.photoProfilUrl;
      if (nouvelleUrl != null) {
        await CachedNetworkImage.evictFromCache(nouvelleUrl);
      }

      // Notifier les listeners pour mettre à jour l'UI
      notifyListeners();

      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  /// Upload une photo de galerie
  Future<bool> uploadPhotoGalerie(XFile file, int position) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      // Sauvegarder l'ancienne URL pour nettoyer le cache
      String? ancienneUrl;
      if (position == 1) ancienneUrl = _utilisateur?.photoGalerie1Url;
      if (position == 2) ancienneUrl = _utilisateur?.photoGalerie2Url;
      if (position == 3) ancienneUrl = _utilisateur?.photoGalerie3Url;

      // Uploader la photo
      await _authService.uploadPhotoGalerie(file, position);

      // Nettoyer le cache de l'ancienne image si elle existe
      if (ancienneUrl != null) {
        await CachedNetworkImage.evictFromCache(ancienneUrl);
      }

      // Recharger le profil pour obtenir la nouvelle URL complète
      await loadUserProfile();
      
      // Nettoyer le cache de la nouvelle URL pour forcer le rechargement
      String? nouvelleUrl;
      if (position == 1) nouvelleUrl = _utilisateur?.photoGalerie1Url;
      if (position == 2) nouvelleUrl = _utilisateur?.photoGalerie2Url;
      if (position == 3) nouvelleUrl = _utilisateur?.photoGalerie3Url;
      
      if (nouvelleUrl != null) {
        await CachedNetworkImage.evictFromCache(nouvelleUrl);
      }

      // Notifier les listeners pour mettre à jour l'UI
      notifyListeners();

      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  /// Récupère le profil d'un autre utilisateur par son ID
  Future<Utilisateur?> obtenirProfilUtilisateur(String userId) async {
    try {
      return await _authService.obtenirProfilUtilisateur(userId);
    } catch (e) {
      return null;
    }
  }

  /// Efface le message d'erreur
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Définit l'état de chargement
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // ========== SESSIONS MEMORISEES ==========

  /// Charge les sessions mémorisées
  Future<void> loadSessionsMemorisees() async {
    _sessionsMemorisees = await _authService.getSessionsMemorisees();
    notifyListeners();
  }

  /// Se reconnecte avec une session mémorisée
  Future<bool> reconnecterSession(UserSession session) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _utilisateur = await _authService.reconnecterSession(session);
      _isAuthenticated = true;
      _setLoading(false);
      return true;
    } catch (e) {
      final errorStr = e.toString().replaceAll('Exception: ', '');
      // Message en français
      if (errorStr.contains('401') || 
          errorStr.contains('Non autorisé') || 
          errorStr.contains('Session expirée') ||
          errorStr.contains('Token') ||
          errorStr.contains('Not authenticated') ||
          errorStr.contains('refreshToken')) {
        _errorMessage = 'Session expirée. Veuillez vous connecter à nouveau.';
      } else {
        _errorMessage = errorStr;
      }
      _setLoading(false);
      return false;
    }
  }

  /// Supprime une session mémorisée
  Future<void> supprimerSession(String idUtilisateur) async {
    await _authService.supprimerSession(idUtilisateur);
    await loadSessionsMemorisees();
  }

  /// Efface toutes les sessions mémorisées
  Future<void> effacerToutesSessions() async {
    await _authService.effacerToutesSessions();
    _sessionsMemorisees = [];
    notifyListeners();
  }
}
