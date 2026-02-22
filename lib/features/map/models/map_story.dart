import 'package:flutter/foundation.dart';

/// Modèle pour les stories géolocalisées
class MapStory {
  final String idStory;
  final String idUtilisateur;
  final String userName;
  final String? userProfilePhoto;
  final bool hasBlueBadge;
  final double latitude;
  final double longitude;
  final String? address;
  final String media1Url;
  final String media1Type;
  final int? media1Duration;
  final String? media1Caption;
  final String? media2Url;
  final String? media2Type;
  final int? media2Duration;
  final String? media2Caption;
  final int viewCount;
  final DateTime? createdAt;
  final DateTime expiresAt;
  final double? distanceKm;
  final bool isExpired;
  final bool isOwner;

  // Préfixe serveur pour les URLs
  static const String _serverPrefix = 'http://localhost:8007';

  MapStory({
    required this.idStory,
    required this.idUtilisateur,
    required this.userName,
    this.userProfilePhoto,
    required this.hasBlueBadge,
    required this.latitude,
    required this.longitude,
    this.address,
    required this.media1Url,
    required this.media1Type,
    this.media1Duration,
    this.media1Caption,
    this.media2Url,
    this.media2Type,
    this.media2Duration,
    this.media2Caption,
    required this.viewCount,
    this.createdAt,
    required this.expiresAt,
    this.distanceKm,
    this.isExpired = false,
    this.isOwner = false,
  });

  /// Ajoute le préfixe serveur si nécessaire
  static String _fixUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    // Ajouter le préfixe localhost pour le développement
    return '$_serverPrefix$url';
  }

  factory MapStory.fromJson(Map<String, dynamic> json) {
    return MapStory(
      idStory: json['id_story'] ?? '',
      idUtilisateur: json['id_utilisateur'] ?? '',
      userName: json['user_name'] ?? '',
      userProfilePhoto: _fixUrl(json['user_profile_photo']),
      hasBlueBadge: json['has_blue_badge'] ?? false,
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      address: json['address'],
      media1Url: _fixUrl(json['media_1_url']),
      media1Type: json['media_1_type'] ?? 'photo',
      media1Duration: json['media_1_duration'],
      media1Caption: json['media_1_caption'],
      media2Url: _fixUrl(json['media_2_url']),
      media2Type: json['media_2_type'],
      media2Duration: json['media_2_duration'],
      media2Caption: json['media_2_caption'],
      viewCount: json['view_count'] ?? 0,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at']) : DateTime.now().add(const Duration(hours: 24)),
      distanceKm: json['distance_km']?.toDouble(),
      isExpired: json['is_expired'] ?? false,
      isOwner: json['is_owner'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_story': idStory,
      'id_utilisateur': idUtilisateur,
      'user_name': userName,
      'user_profile_photo': userProfilePhoto,
      'has_blue_badge': hasBlueBadge,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'media_1_url': media1Url,
      'media_1_type': media1Type,
      'media_1_duration': media1Duration,
      'media_1_caption': media1Caption,
      'media_2_url': media2Url,
      'media_2_type': media2Type,
      'media_2_duration': media2Duration,
      'media_2_caption': media2Caption,
      'view_count': viewCount,
      'created_at': createdAt?.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'distance_km': distanceKm,
      'is_expired': isExpired,
      'is_owner': isOwner,
    };
  }

  /// Vérifie si la story est expirée
  bool get isStillValid => !isExpired && expiresAt.isAfter(DateTime.now());

  /// Récupère les médias disponibles avec leurs légendes
  List<Map<String, dynamic>> get mediaList {
    final list = [
      {
        'url': media1Url, 
        'type': media1Type, 
        'duration': media1Duration,
        'caption': media1Caption,
      },
    ];
    if (media2Url != null && media2Url!.isNotEmpty) {
      list.add({
        'url': media2Url, 
        'type': media2Type, 
        'duration': media2Duration,
        'caption': media2Caption,
      });
    }
    return list.cast<Map<String, dynamic>>();
  }
}

/// Modèle pour les statistiques de l'utilisateur sur ses stories
class MapStoryStats {
  final List<MapStory> stories;
  final int totalViews;
  final int storiesCount;

  MapStoryStats({
    required this.stories,
    required this.totalViews,
    required this.storiesCount,
  });

  factory MapStoryStats.fromJson(Map<String, dynamic> json) {
    return MapStoryStats(
      stories: (json['stories'] as List<dynamic>? ?? [])
          .map((e) => MapStory.fromJson(e))
          .toList(),
      totalViews: json['total_views'] ?? 0,
      storiesCount: json['stories_count'] ?? 0,
    );
  }
}
