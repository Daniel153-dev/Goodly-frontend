import 'package:flutter/foundation.dart';
import '../../../shared/models/don.dart';
import '../services/donation_service.dart';

/// Provider pour la gestion des dons
class DonationProvider with ChangeNotifier {
  final DonationService _donationService;

  List<Map<String, dynamic>> _tousLesDons = [];
  DonStatistiques? _statistiques;

  bool _isLoading = false;
  String? _errorMessage;

  DonationProvider(this._donationService);

  // Getters
  List<Map<String, dynamic>> get tousLesDons => _tousLesDons;
  DonStatistiques? get statistiques => _statistiques;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Charge tous les dons (admin uniquement)
  Future<void> chargerTousLesDons({int skip = 0, int limit = 100}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _tousLesDons = await _donationService.obtenirTousLesDons(
        skip: skip,
        limit: limit,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Charge les statistiques des dons
  Future<void> chargerStatistiques() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _statistiques = await _donationService.obtenirStatistiquesDons();
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
}
