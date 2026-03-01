import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/api/api_constants.dart';
import '../models/event_location.dart';

/// Service de gestion des événements via l'API backend.
class LocationStorageService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  /// Récupère le token d'authentification de l'utilisateur.
  static Future<String?> _getAuthToken() async {
    return await _storage.read(key: 'access_token');
  }

  /// Crée les headers d'authentification pour les requêtes API.
  static Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _getAuthToken();
    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };
  }

  /// Ajouter un événement en l'envoyant au backend (avec form-data).
  static Future<EventLocation> addEventLocation(EventLocation event) async {
    try {
      final token = await _getAuthToken();
      print('[LocationStorageService] Token: ${token?.substring(0, 20)}...');
      
      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.createEvent}');
      print('[LocationStorageService] Envoi événement vers: $url');
      
      // Utiliser multipart/form-data car le backend attend des champs de formulaire
      final request = http.MultipartRequest('POST', url);
      
      // Ajouter le token
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
        print('[LocationStorageService] Authorization header ajouté');
      } else {
        print('[LocationStorageService] ERREUR: Pas de token!');
      }
      request.headers['Accept'] = 'application/json';
      
      // Ajouter les champs du formulaire
      request.fields['title'] = event.title;
      request.fields['description'] = event.description;
      request.fields['latitude'] = event.latitude.toString();
      request.fields['longitude'] = event.longitude.toString();
      request.fields['address'] = event.address;
      request.fields['user_id'] = event.userId;
      request.fields['user_name'] = event.userName;
      request.fields['has_blue_badge'] = event.hasBlueBadge.toString();
      
      if (event.userProfilePhoto != null) {
        request.fields['user_profile_photo'] = event.userProfilePhoto!;
      }
      if (event.imageUrl != null) {
        request.fields['image_url'] = event.imageUrl!;
      }
      if (event.eventDateTime != null) {
        request.fields['event_datetime'] = event.eventDateTime!.toIso8601String();
      }
      
      print('[LocationStorageService] Champs envoyés: ${request.fields}');
      
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      
      print('[LocationStorageService] Réponse création événement: ${response.statusCode} - $responseBody');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = json.decode(responseBody);
        if (jsonResponse is Map) {
          return EventLocation.fromJson(jsonResponse['event'] ?? jsonResponse);
        }
        throw Exception('Format de réponse invalide');
      } else if (response.statusCode == 401) {
        throw Exception('Non autorisé. Veuillez vous reconnecter.');
      } else {
        throw Exception('Erreur lors de la création: ${response.statusCode} - $responseBody');
      }
    } catch (e) {
      print('[LocationStorageService] Erreur addEventLocation: $e');
      rethrow;
    }
  }

  /// Obtenir tous les événements depuis le backend.
  static Future<List<EventLocation>> getEventsLocations() async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.getAllEvents}');
      
      print('[LocationStorageService] Récupération événements depuis: $url');
      
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      });

      print('[LocationStorageService] Réponse getEventsLocations: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Vérifier si la réponse est du JSON valide
        try {
          final jsonResponse = json.decode(response.body);
          
          // Gérer différents formats de réponse
          List<dynamic> jsonList = [];
          if (jsonResponse is List) {
            jsonList = jsonResponse;
          } else if (jsonResponse is Map) {
            // Le format peut être {"events": [...]} ou directement [...]
            if (jsonResponse['events'] != null && jsonResponse['events'] is List) {
              jsonList = jsonResponse['events'];
            } else if (jsonResponse['data'] != null && jsonResponse['data'] is List) {
              jsonList = jsonResponse['data'];
            }
          }
          
          print('[LocationStorageService] ${jsonList.length} événements chargés');
          return jsonList.map((json) => EventLocation.fromJson(json)).toList();
        } catch (e) {
          print('[LocationStorageService] Erreur parsing JSON: $e');
          // Retourner une liste vide au lieu de planter
          return [];
        }
      } else if (response.statusCode == 401) {
        throw Exception('Non autorisé. Veuillez vous reconnecter.');
      } else {
        print('[LocationStorageService] Erreur HTTP: ${response.statusCode}');
        // Retourner une liste vide au lieu de planter
        return [];
      }
    } catch (e) {
      print('[LocationStorageService] Erreur getEventsLocations: $e');
      // Retourner une liste vide au lieu de planter en cas d'erreur réseau
      return [];
    }
  }

  /// Obtenir les événements d'un utilisateur spécifique depuis le backend.
  static Future<List<EventLocation>> getUserEventsLocations(String userId) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.getUserEvents(userId)}');
      
      print('[LocationStorageService] Récupération événements utilisateur: $url');
      
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      });

      if (response.statusCode == 200) {
        try {
          final jsonResponse = json.decode(response.body);
          
          List<dynamic> jsonList = [];
          if (jsonResponse is List) {
            jsonList = jsonResponse;
          } else if (jsonResponse is Map && jsonResponse['events'] != null) {
            jsonList = jsonResponse['events'];
          }
          
          return jsonList.map((json) => EventLocation.fromJson(json)).toList();
        } catch (e) {
          print('[LocationStorageService] Erreur parsing JSON utilisateur: $e');
          return [];
        }
      } else {
        print('[LocationStorageService] Erreur HTTP utilisateur: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('[LocationStorageService] Erreur getUserEventsLocations: $e');
      return [];
    }
  }

  /// Supprimer un événement sur le backend.
  static Future<void> deleteEventLocation(String eventId) async {
    try {
      final headers = await _getAuthHeaders();
      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.deleteEvent(eventId)}');
      
      print('[LocationStorageService] Suppression événement: $url');
      
      final response = await http.delete(url, headers: headers);

      if (response.statusCode == 200 || response.statusCode == 204) {
        print('[LocationStorageService] Événement supprimé avec succès');
      } else if (response.statusCode == 401) {
        throw Exception('Non autorisé. Veuillez vous reconnecter.');
      } else if (response.statusCode == 404) {
        throw Exception('Événement non trouvé.');
      } else {
        throw Exception('Erreur lors de la suppression: ${response.statusCode}');
      }
    } catch (e) {
      print('[LocationStorageService] Erreur deleteEventLocation: $e');
      rethrow;
    }
  }

  /// Récupère l'adresse à partir des coordonnées GPS
  static Future<String> getAddressFromLatLng(double latitude, double longitude) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?'
        'lat=$latitude&lon=$longitude&format=json&addressdetails=1&language=fr',
      );

      final response = await http.get(url, headers: {
        'User-Agent': 'GoodlyApp/1.0',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['display_name'] != null) {
          return data['display_name'];
        }
        // Construire l'adresse à partir des composants
        final address = data['address'];
        if (address != null) {
          final parts = [];
          if (address['road'] != null) parts.add(address['road']);
          if (address['city'] != null) parts.add(address['city']);
          if (address['postcode'] != null) parts.add(address['postcode']);
          if (address['country'] != null) parts.add(address['country']);
          return parts.join(', ');
        }
      }
      return '$latitude, $longitude';
    } catch (e) {
      print('[LocationStorageService] Erreur getAddressFromLatLng: $e');
      return '$latitude, $longitude';
    }
  }
}
