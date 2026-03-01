import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../../../shared/models/publication.dart';
import '../services/publications_service.dart';

/// Provider pour la gestion des publications
class PublicationsProvider with ChangeNotifier {
  final PublicationsService _publicationsService;

  List<Publication> _publications = [];
  List<Publication> _mesPublications = [];
  List<Publication> _publicationsUtilisateur = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int _currentPage = 0;
  final int _pageSize = 20;
  bool _hasMoreData = true;
  String? _selectedCategorie;

  PublicationsProvider(this._publicationsService);

  // Getters
  List<Publication> get publications => _publications;
  List<Publication> get mesPublications => _mesPublications;
  List<Publication> get publicationsUtilisateur => _publicationsUtilisateur;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  bool get hasMoreData => _hasMoreData;
  String? get selectedCategorie => _selectedCategorie;

  /// Charge le flux de publications
  Future<void> chargerFlux({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 0;
      _publications.clear();
      _hasMoreData = true;
    }

    if (!_hasMoreData) return;

    if (_currentPage == 0) {
      _isLoading = true;
    } else {
      _isLoadingMore = true;
    }
    _errorMessage = null;
    notifyListeners();

    try {
      final nouvelles = await _publicationsService.obtenirFluxPublications(
        skip: _currentPage * _pageSize,
        limit: _pageSize,
        categorie: _selectedCategorie,
      );

      if (nouvelles.length < _pageSize) {
        _hasMoreData = false;
      }

      _publications.addAll(nouvelles);
      _currentPage++;

      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Filtre par catégorie
  Future<void> filtrerParCategorie(String? categorie) async {
    _selectedCategorie = categorie;
    await chargerFlux(refresh: true);
  }

  /// Charge mes publications
  Future<void> chargerMesPublications() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _mesPublications = await _publicationsService.obtenirMesPublications();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Charge les publications d'un utilisateur spécifique
  Future<void> chargerPublicationsUtilisateur(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    _publicationsUtilisateur = [];
    notifyListeners();

    try {
      _publicationsUtilisateur = await _publicationsService.obtenirPublicationsUtilisateur(userId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Crée une nouvelle publication
  Future<bool> creerPublication({
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
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final publication = await _publicationsService.creerPublication(
        titre: titre,
        description: description,
        typeContenu: typeContenu,
        imagesUrls: imagesUrls,
        videosUrls: videosUrls,
        videoThumbnail: videoThumbnail,
        categorie: categorie,
        geolocalisation: geolocalisation,
        latitude: latitude,
        longitude: longitude,
      );

      // Ajouter aux mes publications
      _mesPublications.insert(0, publication);

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

  /// Upload des images
  Future<List<String>?> uploadImages(List<XFile> files) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final urls = await _publicationsService.uploadImages(files);
      _isLoading = false;
      notifyListeners();
      return urls;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Upload des vidéos
  Future<List<String>?> uploadVideos(List<XFile> files) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final urls = await _publicationsService.uploadVideos(files);
      _isLoading = false;
      notifyListeners();
      return urls;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Ajoute une inspiration
  Future<bool> ajouterInspiration(String publicationId) async {
    try {
      await _publicationsService.ajouterInspiration(publicationId);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    }
  }

  /// Retire une inspiration
  Future<bool> retirerInspiration(String publicationId) async {
    try {
      await _publicationsService.retirerInspiration(publicationId);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    }
  }

  /// Met à jour l'état d'inspiration localement SANS modifier le compteur
  void updateInspiredStateLocally(String publicationId, bool inspired) {
    // Mettre à jour juste le flag aInspire dans le flux
    final indexFlux = _publications.indexWhere((p) => p.idPublication == publicationId);
    if (indexFlux != -1) {
      final pub = _publications[indexFlux];
      _publications[indexFlux] = pub.copyWith(
        aInspire: inspired,
      );
    }

    // Mettre à jour juste le flag aInspire dans mes publications
    final indexMes = _mesPublications.indexWhere((p) => p.idPublication == publicationId);
    if (indexMes != -1) {
      final pub = _mesPublications[indexMes];
      _mesPublications[indexMes] = pub.copyWith(
        aInspire: inspired,
      );
    }
    notifyListeners();
  }

  /// Supprime une publication
  Future<bool> supprimerPublication(String publicationId) async {
    try {
      await _publicationsService.supprimerPublication(publicationId);

      // Retirer localement
      _publications.removeWhere((p) => p.idPublication == publicationId);
      _mesPublications.removeWhere((p) => p.idPublication == publicationId);

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Signale une publication
  Future<bool> signalerPublication({
    required String publicationId,
    required String motif,
    String? description,
  }) async {
    try {
      await _publicationsService.signalerPublication(
        publicationId: publicationId,
        motif: motif,
        description: description,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Efface le message d'erreur
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Enregistre une vue sur une publication (après 30 secondes de visibilité)
  Future<void> enregistrerVue(String publicationId) async {
    try {
      final result = await _publicationsService.enregistrerVue(publicationId);

      // Mettre à jour localement si la vue a été enregistrée
      if (result['deja_vu'] == false) {
        _updateVueLocally(publicationId, result['nombre_vues'] ?? 0);
        notifyListeners();
      }
    } catch (e) {
      // Silencieux - pas d'erreur affichée pour les vues
      debugPrint('Erreur enregistrement vue: $e');
    }
  }

  /// Enregistre un captivant sur une publication (après 1 minute à 100% visible)
  Future<void> enregistrerCaptivant(String publicationId) async {
    try {
      final result = await _publicationsService.enregistrerCaptivant(publicationId);

      // Mettre à jour localement si le captivant a été enregistré
      if (result['deja_captive'] == false) {
        _updateCaptivantLocally(publicationId, result['nombre_captivants'] ?? 0);
        notifyListeners();
      }
    } catch (e) {
      // Silencieux - pas d'erreur affichée pour les captivants
      debugPrint('Erreur enregistrement captivant: $e');
    }
  }

  /// Met à jour le nombre de vues localement
  void _updateVueLocally(String publicationId, int nombreVues) {
    final indexFlux = _publications.indexWhere((p) => p.idPublication == publicationId);
    if (indexFlux != -1) {
      final pub = _publications[indexFlux];
      _publications[indexFlux] = pub.copyWith(
        nombreVues: nombreVues,
        aVu: true,
      );
    }
  }

  /// Met à jour le nombre de captivants localement
  void _updateCaptivantLocally(String publicationId, int nombreCaptivants) {
    final indexFlux = _publications.indexWhere((p) => p.idPublication == publicationId);
    if (indexFlux != -1) {
      final pub = _publications[indexFlux];
      _publications[indexFlux] = pub.copyWith(
        nombreCaptivants: nombreCaptivants,
        aCaptive: true,
      );
    }
  }
}
