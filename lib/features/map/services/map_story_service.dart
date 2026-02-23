import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_constants.dart';
import '../models/map_story.dart';

/// Service pour gérer les stories géolocalisées
class MapStoryService {
  static final ApiClient _apiClient = ApiClient();

  /// Crée une nouvelle story
  static Future<Map<String, dynamic>> createStory({
    required double latitude,
    required double longitude,
    String? address,
    required String media1Url,
    required String media1Type,
    int? media1Duration,
    String? media1Caption,
    String? media2Url,
    String? media2Type,
    int? media2Duration,
    String? media2Caption,
  }) async {
    print('=== CREATE STORY ===');
    print('Latitude: $latitude, Longitude: $longitude');
    print('Media 1: $media1Url, Type: $media1Type');
    
    try {
      final body = {
        'latitude': latitude,
        'longitude': longitude,
        'address': address ?? '',
        'media_1_url': media1Url,
        'media_1_type': media1Type,
        if (media1Type == 'video' && media1Duration != null)
          'media_1_duration': media1Duration,
        if (media1Caption != null && media1Caption.isNotEmpty)
          'media_1_caption': media1Caption,
        if (media2Url != null) 'media_2_url': media2Url,
        if (media2Type != null) 'media_2_type': media2Type,
        if (media2Type == 'video' && media2Duration != null)
          'media_2_duration': media2Duration,
        if (media2Caption != null && media2Caption.isNotEmpty)
          'media_2_caption': media2Caption,
      };
      
      final url = '${ApiConstants.baseUrlStories}/create';
      print('Body: $body');
      print('URL: $url');

      final response = await _apiClient.post(
        url,
        data: body,
      );

      print('Response status: ${response.statusCode}');
      print('Response data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      } else {
        throw Exception(response.data['detail'] ?? 'Erreur lors de la création de la story');
      }
    } catch (e) {
      print('ERREUR createStory: $e');
      throw Exception('Erreur réseau: $e');
    }
  }

  /// Récupère les stories à proximité
  static Future<List<MapStory>> getNearbyStories({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
  }) async {
    print('=== GET NEARBY STORIES ===');
    print('Latitude: $latitude, Longitude: $longitude, Radius: $radiusKm');
    
    try {
      // baseUrlStories contient déjà /api/stories en production
      final url = '${ApiConstants.baseUrlStories}/nearby?latitude=$latitude&longitude=$longitude&radius=$radiusKm';
      print('URL: $url');

      final response = await _apiClient.get(url);

      print('Response status: ${response.statusCode}');
      print('Response data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data as List<dynamic>;
        final stories = data
            .map((e) => MapStory.fromJson(e))
            .toList();
        return stories.where((story) => story.isStillValid).toList();
      } else {
        throw Exception('Erreur lors de la récupération des stories');
      }
    } catch (e) {
      print('ERREUR getNearbyStories: $e');
      throw Exception('Erreur réseau: $e');
    }
  }

  /// Récupère une story spécifique
  static Future<MapStory> getStory(String storyId) async {
    print('=== GET STORY $storyId ===');
    
    try {
      // baseUrlStories contient déjà /api/stories en production
      final url = '${ApiConstants.baseUrlStories}/$storyId';
      final response = await _apiClient.get(url);

      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return MapStory.fromJson(response.data);
      } else if (response.statusCode == 404) {
        throw Exception('Story non trouvée');
      } else {
        throw Exception('Erreur lors de la récupération de la story');
      }
    } catch (e) {
      print('ERREUR getStory: $e');
      throw Exception('Erreur réseau: $e');
    }
  }

  /// Enregistre qu'un utilisateur a vu une story
  static Future<void> viewStory(String storyId) async {
    print('=== VIEW STORY $storyId ===');
    
    try {
      final url = '${ApiConstants.baseUrlStories}/$storyId/view';
      final response = await _apiClient.post(url, data: {});

      print('Response status: ${response.statusCode}');

      if (response.statusCode != 200) {
        throw Exception('Erreur lors de l\'enregistrement de la vue');
      }
    } catch (e) {
      // Ne pas bloquer en cas d'erreur de réseau
      print('Erreur vue story: $e');
    }
  }

  /// Récupère les statistiques des stories de l'utilisateur
  static Future<MapStoryStats> getMyStats() async {
    try {
      final url = '${ApiConstants.baseUrlStories}/my/stats';
      final response = await _apiClient.get(url);

      if (response.statusCode == 200) {
        return MapStoryStats.fromJson(response.data);
      } else {
        throw Exception('Erreur lors de la récupération des statistiques');
      }
    } catch (e) {
      throw Exception('Erreur réseau: $e');
    }
  }

  /// Supprime une story
  static Future<void> deleteStory(String storyId) async {
    print('=== DELETE STORY $storyId ===');
    
    try {
      final url = '${ApiConstants.baseUrlStories}/$storyId';
      final response = await _apiClient.delete(url);

      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 403) {
        throw Exception('Vous n\'êtes pas autorisé à supprimer cette story');
      } else if (response.statusCode == 404) {
        throw Exception('Story non trouvée');
      } else {
        throw Exception('Erreur lors de la suppression de la story');
      }
    } catch (e) {
      print('ERREUR deleteStory: $e');
      throw Exception('Erreur réseau: $e');
    }
  }
}
