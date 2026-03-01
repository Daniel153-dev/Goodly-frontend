/// Modèle pour les localisations d'événements
class EventLocation {
  final String? id;
  final String userId;
  final String userName;
  final String? userProfilePhoto;
  final bool hasBlueBadge;
  final String title;
  final String description;
  final String? imageUrl;
  final double latitude;
  final double longitude;
  final String address;
  final DateTime createdAt;
  final DateTime? eventDateTime;
  final bool isUserLocation;

  EventLocation({
    this.id,
    required this.userId,
    this.userName = '',
    this.userProfilePhoto,
    this.hasBlueBadge = false,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.createdAt,
    this.eventDateTime,
    this.isUserLocation = false,
  });

  factory EventLocation.fromJson(Map<String, dynamic> json) {
    return EventLocation(
      id: json['id']?.toString(),
      userId: json['user_id']?.toString() ?? json['id_utilisateur']?.toString() ?? '',
      userName: json['user_name'] ?? json['nom_utilisateur'] ?? '',
      userProfilePhoto: json['user_profile_photo'] ?? json['photo_profil'],
      hasBlueBadge: json['has_blue_badge'] ?? json['badge_bleu'] ?? false,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['image_url'],
      latitude: double.tryParse(json['latitude']?.toString() ?? '0') ?? 0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '0') ?? 0,
      address: json['address'] ?? '',
      createdAt: DateTime.tryParse(json['created_at'] ?? DateTime.now().toIso8601String()) ?? DateTime.now(),
      eventDateTime: json['event_datetime'] != null ? DateTime.tryParse(json['event_datetime']) : null,
      isUserLocation: json['is_user_location'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'user_profile_photo': userProfilePhoto,
      'has_blue_badge': hasBlueBadge,
      'title': title,
      'description': description,
      'image_url': imageUrl,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'created_at': createdAt.toIso8601String(),
      'event_datetime': eventDateTime?.toIso8601String(),
      'is_user_location': isUserLocation,
    };
  }

  EventLocation copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userProfilePhoto,
    bool? hasBlueBadge,
    String? title,
    String? description,
    String? imageUrl,
    double? latitude,
    double? longitude,
    String? address,
    DateTime? createdAt,
    DateTime? eventDateTime,
    bool? isUserLocation,
  }) {
    return EventLocation(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userProfilePhoto: userProfilePhoto ?? this.userProfilePhoto,
      hasBlueBadge: hasBlueBadge ?? this.hasBlueBadge,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      eventDateTime: eventDateTime ?? this.eventDateTime,
      isUserLocation: isUserLocation ?? this.isUserLocation,
    );
  }

  /// Vérifie si l'événement est expiré (date passée)
  /// Tolérance de 2 heures pour afficher les événements récemment terminés
  bool get isExpired {
    if (eventDateTime == null) return false;
    final now = DateTime.now();
    // L'événement est expiré s'il s'est terminé il y a plus de 2 heures
    return now.difference(eventDateTime!).inHours > 2;
  }
}
