import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:intl/intl.dart'; // Add this import for DateFormat
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_constants.dart';
import '../../../shared/models/utilisateur.dart';
import '../../../shared/models/user_session.dart';

/// Service d'authentification
class AuthService {
  final ApiClient _apiClient;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String _sessionsKey = 'memorized_sessions';
  static const String _currentSessionKey = 'current_session';

  // Configuration Google Sign-In
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  AuthService(this._apiClient);

  /// Inscription d'un nouvel utilisateur
  Future<Utilisateur> inscription({
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
    try {
      final requestData = {
        'nom_utilisateur': nomUtilisateur,
        'email': email,
        'mot_de_passe': motDePasse,
        'numero_telephone': numeroTelephone,
        'code_pays': codePays,
        if (pays != null) 'pays': pays,
        if (dateNaissance != null) 'date_naissance': DateFormat('yyyy-MM-dd').format(dateNaissance),
        if (sexe != null) 'sexe': sexe,
        if (biographie != null) 'biographie': biographie,
      };

      final response = await _apiClient.post(
        ApiConstants.inscription,
        data: requestData,
      );

      // Stocker les tokens
      await _stockerTokens(
        response.data['access_token'],
        response.data['refresh_token'],
      );

      // Récupérer et retourner le profil de l'utilisateur
      final user = await obtenirProfil();
      
      // Sauvegarder la session mémorisée
      await sauvegarderSession(user, provider: 'email');
      
      return user;
    } catch (e) {
      throw Exception('Erreur lors de l\'inscription: $e');
    }
  }

  /// Connexion d'un utilisateur existant
  Future<Utilisateur> connexion({
    required String email,
    required String motDePasse,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.connexion,
        data: {
          'email': email,
          'mot_de_passe': motDePasse,
        },
      );

      // Logs de debug supprimés pour la sécurité - ne jamais logger les tokens

      // Stocker les tokens
      final accessToken = response.data['access_token'];
      final refreshToken = response.data['refresh_token'];
      
      if (accessToken != null) {
        await _storage.write(key: 'access_token', value: accessToken);
      }
      if (refreshToken != null) {
        await _storage.write(key: 'refresh_token', value: refreshToken);
      } else {
        print('WARNING: refresh_token est null dans la réponse du backend!');
      }

      // Récupérer le profil de l'utilisateur
      final user = await obtenirProfil();
      
      // Sauvegarder la session mémorisée
      await sauvegarderSession(user, provider: 'email');
      
      return user;
    } catch (e) {
      throw Exception('Erreur lors de la connexion: $e');
    }
  }

  /// Connexion avec Google
  Future<Utilisateur> connexionGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Connexion Google annulée');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception('Impossible d\'obtenir le token Google');
      }

      // Envoyer le token au backend pour vérification et création/connexion du compte
      final response = await _apiClient.post(
        '/auth/connexion-sociale',
        data: {
          'provider': 'google',
          'id_token': idToken,
          'email': googleUser.email,
          'nom': googleUser.displayName ?? googleUser.email.split('@')[0],
          'photo_url': googleUser.photoUrl,
        },
      );

      // Stocker les tokens
      await _stockerTokens(
        response.data['access_token'],
        response.data['refresh_token'],
      );

      // Récupérer le profil et sauvegarder la session
      final user = await obtenirProfil();
      await sauvegarderSession(user, provider: 'google');
      
      return user;
    } catch (e) {
      throw Exception('Erreur lors de la connexion Google: $e');
    }
  }

  /// Connexion avec Apple (iCloud)
  Future<Utilisateur> connexionApple() async {
    try {
      // Vérifier si Apple Sign In est disponible
      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        throw Exception('Apple Sign In n\'est pas disponible sur cet appareil');
      }

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final String? idToken = credential.identityToken;
      if (idToken == null) {
        throw Exception('Impossible d\'obtenir le token Apple');
      }

      // Construire le nom complet
      String? fullName;
      if (credential.givenName != null || credential.familyName != null) {
        fullName = '${credential.givenName ?? ''} ${credential.familyName ?? ''}'.trim();
      }

      // Envoyer le token au backend pour vérification et création/connexion du compte
      final response = await _apiClient.post(
        '/auth/connexion-sociale',
        data: {
          'provider': 'apple',
          'id_token': idToken,
          'email': credential.email,
          'nom': fullName,
          'user_identifier': credential.userIdentifier,
        },
      );

      // Stocker les tokens
      await _stockerTokens(
        response.data['access_token'],
        response.data['refresh_token'],
      );

      // Récupérer le profil et sauvegarder la session
      final user = await obtenirProfil();
      await sauvegarderSession(user, provider: 'apple');
      
      return user;
    } catch (e) {
      throw Exception('Erreur lors de la connexion Apple: $e');
    }
  }

  /// Connexion avec Yahoo
  /// Note: Yahoo utilise OAuth 2.0 standard, nécessite une configuration dans Yahoo Developer Console
  Future<Utilisateur> connexionYahoo() async {
    try {
      // Yahoo OAuth flow - on utilise le backend pour gérer le flow OAuth
      // Le frontend redirige vers l'URL d'autorisation Yahoo fournie par le backend
      final response = await _apiClient.post(
        '/auth/connexion-sociale/yahoo/initier',
        data: {},
      );

      // Le backend retourne l'URL d'autorisation Yahoo
      // Cette méthode sera appelée après le callback OAuth
      throw Exception(
        'Veuillez suivre le lien d\'autorisation Yahoo. '
        'La connexion Yahoo nécessite une redirection vers Yahoo.com'
      );
    } catch (e) {
      throw Exception('Erreur lors de la connexion Yahoo: $e');
    }
  }

  /// Finalise la connexion OAuth après le callback
  Future<Utilisateur> finaliserConnexionOAuth({
    required String provider,
    required String code,
    String? state,
  }) async {
    try {
      final response = await _apiClient.post(
        '/auth/connexion-sociale/callback',
        data: {
          'provider': provider,
          'code': code,
          if (state != null) 'state': state,
        },
      );

      // Stocker les tokens
      await _stockerTokens(
        response.data['access_token'],
        response.data['refresh_token'],
      );

      return await obtenirProfil();
    } catch (e) {
      throw Exception('Erreur lors de la finalisation de la connexion: $e');
    }
  }

  /// Déconnexion
  /// Garde les tokens et sessions pour permettre une reconnexion rapide (comme Facebook)
  Future<void> deconnexion() async {
    try {
      // Ne pas supprimer les sessions et tokens
      // L'utilisateur peut ainsi se reconnecter automatiquement sans entrer email/mot de passe
      // La déconnexion ferme seulement la session courante dans l'app
      // Les tokens restent valides et peuvent être réutilisés
    } catch (e) {
      throw Exception('Erreur lors de la déconnexion: $e');
    }
  }

  /// Déconnexion complète
  /// Supprime tout - l'utilisateur devra se reconnecter avec email et mot de passe
  Future<void> deconnexionComplete() async {
    try {
      // Supprimer toutes les sessions mémorisées
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionsKey);
      await prefs.remove(_currentSessionKey);
      // Supprimer tous les tokens
      await _storage.deleteAll();
    } catch (e) {
      throw Exception('Erreur lors de la déconnexion: $e');
    }
  }

  /// Récupère le profil de l'utilisateur connecté
  Future<Utilisateur> obtenirProfil() async {
    try {
      final response = await _apiClient.get(ApiConstants.profil);
      return Utilisateur.fromJson(response.data);
    } catch (e) {
      throw Exception('Erreur lors de la récupération du profil: $e');
    }
  }

  /// Récupère le profil d'un utilisateur par son ID
  Future<Utilisateur> obtenirProfilUtilisateur(String userId) async {
    try {
      final response = await _apiClient.get('${ApiConstants.profil}/$userId');
      return Utilisateur.fromJson(response.data);
    } catch (e) {
      throw Exception('Erreur lors de la récupération du profil: $e');
    }
  }

  /// Met à jour le profil de l'utilisateur
  Future<Utilisateur> mettreAJourProfil({
    String? nomUtilisateur,
    String? biographie,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (nomUtilisateur != null) data['nom_utilisateur'] = nomUtilisateur;
      if (biographie != null) data['biographie'] = biographie;

      final response = await _apiClient.put(
        ApiConstants.mettreAJourProfil,
        data: data,
      );

      return Utilisateur.fromJson(response.data);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du profil: $e');
    }
  }

  /// Upload une photo de profil
  Future<String> uploadPhotoProfil(XFile file) async {
    try {
      final response = await _apiClient.uploadFiles(
        ApiConstants.uploadPhotoProfil,
        [file],
        fieldName: 'file',  // Backend attend 'file' au singulier pour photo profil
      );

      return response.data['url'];
    } catch (e) {
      throw Exception('Erreur lors de l\'upload de la photo: $e');
    }
  }

  /// Upload une photo de galerie (position 1, 2 ou 3)
  Future<String> uploadPhotoGalerie(XFile file, int position) async {
    if (position < 1 || position > 3) {
      throw Exception('La position doit être 1, 2 ou 3');
    }

    try {
      final response = await _apiClient.uploadFiles(
        ApiConstants.uploadPhotoGalerie(position),
        [file],
        fieldName: 'file',  // Backend attend 'file' au singulier pour photo galerie
      );

      return response.data['url'];
    } catch (e) {
      throw Exception('Erreur lors de l\'upload de la photo: $e');
    }
  }

  /// Supprime le compte de l'utilisateur
  Future<void> supprimerCompte() async {
    try {
      await _apiClient.delete(ApiConstants.supprimerCompte);
      await _storage.deleteAll();
    } catch (e) {
      throw Exception('Erreur lors de la suppression du compte: $e');
    }
  }

  /// Vérifie si l'utilisateur est connecté
  Future<bool> estConnecte() async {
    final token = await _storage.read(key: 'access_token');
    return token != null;
  }

  /// Stocke les tokens d'authentification
  Future<void> _stockerTokens(String accessToken, String refreshToken) async {
    await _storage.write(key: 'access_token', value: accessToken);
    await _storage.write(key: 'refresh_token', value: refreshToken);
  }

  // ========== GESTION DES SESSIONS MEMORISEES ==========

  /// Sauvegarde la session actuelle dans les sessions mémorisées
  Future<void> sauvegarderSession(Utilisateur user, {String? provider}) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Récupérer les sessions existantes
    final sessionsJson = prefs.getStringList(_sessionsKey) ?? [];
    final sessions = sessionsJson
        .map((json) => UserSession.fromJsonString(json))
        .where((session) => session != null)
        .cast<UserSession>()
        .toList();
    
    // Vérifier si l'utilisateur existe déjà
    final existingIndex = sessions.indexWhere((s) => s.idUtilisateur == user.idUtilisateur);
    
    // Créer la nouvelle session
    final newSession = UserSession(
      idUtilisateur: user.idUtilisateur,
      nomUtilisateur: user.nomUtilisateur,
      email: user.email,
      photoProfil: user.photoProfil,
      hasBlueBadge: user.badgeBleu,
      dateConnexion: DateTime.now(),
      provider: provider ?? 'email',
    );
    
    if (existingIndex >= 0) {
      // Mettre à jour la session existante
      sessions[existingIndex] = newSession;
    } else {
      // Ajouter la nouvelle session
      sessions.insert(0, newSession);
    }
    
    // Garder seulement les 5 dernières sessions
    if (sessions.length > 5) {
      sessions.removeRange(5, sessions.length);
    }
    
    // Sauvegarder
    await prefs.setStringList(
      _sessionsKey,
      sessions.map((s) => s.toJsonString()).toList(),
    );
    
    // Sauvegarder la session actuelle
    await prefs.setString(_currentSessionKey, newSession.toJsonString());
  }

  /// Récupère toutes les sessions mémorisées
  Future<List<UserSession>> getSessionsMemorisees() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionsJson = prefs.getStringList(_sessionsKey) ?? [];
    
    return sessionsJson
        .map((json) => UserSession.fromJsonString(json))
        .where((session) => session != null)
        .cast<UserSession>()
        .toList();
  }

  /// Récupère la dernière session utilisée
  Future<UserSession?> getSessionActuelle() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionJson = prefs.getString(_currentSessionKey);
    
    if (sessionJson != null) {
      return UserSession.fromJsonString(sessionJson);
    }
    return null;
  }

  /// Supprime une session mémorisée
  Future<void> supprimerSession(String idUtilisateur) async {
    final prefs = await SharedPreferences.getInstance();
    final sessionsJson = prefs.getStringList(_sessionsKey) ?? [];
    
    final sessions = sessionsJson
        .map((json) => UserSession.fromJsonString(json))
        .where((session) => session != null && session.idUtilisateur != idUtilisateur)
        .cast<UserSession>()
        .toList();
    
    await prefs.setStringList(
      _sessionsKey,
      sessions.map((s) => s.toJsonString()).toList(),
    );
  }

  /// Efface toutes les sessions mémorisées
  Future<void> effacerToutesSessions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionsKey);
    await prefs.remove(_currentSessionKey);
  }

  /// Se reconnecte avec une session mémorisée
  Future<Utilisateur> reconnecterSession(UserSession session) async {
    try {
      // Tenter directement d'obtenir le profil
      print('DEBUG reconnecterSession: Tentative de reconnexion pour ${session.email}');
      
      final response = await _apiClient.get(ApiConstants.profil);
      
      print('DEBUG reconnecterSession: Profil obtenu avec succès');
      
      // Créer l'utilisateur à partir de la réponse
      final user = Utilisateur.fromJson(response.data);
      
      // Mettre à jour la session avec les nouvelles données (incluant la photo)
      await sauvegarderSession(user, provider: session.provider);
      
      return user;
    } on DioException catch (e) {
      print('DEBUG reconnecterSession: DioError - ${e.response?.statusCode} - ${e.message}');
      
      // Si 401, vérifier si on a un refresh token
      if (e.response?.statusCode == 401) {
        final refreshToken = await _storage.read(key: 'refresh_token');
        
        if (refreshToken == null) {
          print('DEBUG reconnecterSession: refreshToken est null dans secure storage - l\'utilisateur doit se reconnecter');
          throw Exception('Session expirée. Veuillez vous connecter à nouveau.');
        }
        
        print('DEBUG reconnecterSession: Token expiré, tentative de refresh...');
        final refreshed = await _rafraichirTokenManuel();
        
        if (refreshed) {
          // Réessayer avec le nouveau token
          final response = await _apiClient.get(ApiConstants.profil);
          await _mettreAJourDateConnexion(session.idUtilisateur);
          return Utilisateur.fromJson(response.data);
        } else {
          throw Exception('Session expirée. Veuillez vous connecter à nouveau.');
        }
      }
      
      throw Exception('Erreur de connexion: ${e.response?.statusCode ?? 'Inconnu'}');
    } catch (e) {
      print('DEBUG reconnecterSession: Erreur - $e');
      if (e.toString().contains('Session expirée')) {
        rethrow;
      }
      // Gestion de l'erreur "Not authenticated" ou отсутствие de refresh token
      if (e.toString().contains('Not authenticated') || 
          e.toString().contains('refreshToken est null') ||
          e.toString().contains('refresh token')) {
        throw Exception('Session expirée. Veuillez vous connecter à nouveau.');
      }
      throw Exception('Impossible de se reconnecter: $e');
    }
  }

  /// Rafraîchit le token manuellement
  Future<bool> _rafraichirTokenManuel() async {
    try {
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken == null) return false;

      final response = await _apiClient.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200) {
        final newAccessToken = response.data['access_token'];
        final newRefreshToken = response.data['refresh_token'];
        
        await _stockerTokens(newAccessToken, newRefreshToken ?? refreshToken);
        print('DEBUG _rafraichirTokenManuel: Token rafraîchi avec succès');
        return true;
      }
      return false;
    } catch (e) {
      print('DEBUG _rafraichirTokenManuel: Erreur - $e');
      return false;
    }
  }

  /// Met à jour la date de connexion d'une session
  Future<void> _mettreAJourDateConnexion(String idUtilisateur) async {
    final prefs = await SharedPreferences.getInstance();
    final sessionsJson = prefs.getStringList(_sessionsKey) ?? [];
    
    final sessions = sessionsJson
        .map((json) => UserSession.fromJsonString(json))
        .where((session) => session != null)
        .cast<UserSession>()
        .toList();
    
    for (var i = 0; i < sessions.length; i++) {
      if (sessions[i].idUtilisateur == idUtilisateur) {
        sessions[i] = UserSession(
          idUtilisateur: sessions[i].idUtilisateur,
          nomUtilisateur: sessions[i].nomUtilisateur,
          email: sessions[i].email,
          photoProfil: sessions[i].photoProfil,
          dateConnexion: DateTime.now(),
          provider: sessions[i].provider,
        );
        break;
      }
    }
    
    await prefs.setStringList(
      _sessionsKey,
      sessions.map((s) => s.toJsonString()).toList(),
    );
  }
}
