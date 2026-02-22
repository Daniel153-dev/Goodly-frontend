/// Modèle pour les boutiques
class Shop {
  final String? id;
  final String userId;
  final String userName;
  final String? userProfilePhoto;
  final bool hasBlueBadge;
  final String shopName;
  final String? description;
  final String? logoUrl;
  final String? coverUrl;
  final double latitude;
  final double longitude;
  final String address;
  final String pays;
  final String? phone;
  final String? email;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Shop({
    this.id,
    required this.userId,
    this.userName = '',
    this.userProfilePhoto,
    this.hasBlueBadge = false,
    required this.shopName,
    this.description,
    this.logoUrl,
    this.coverUrl,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.pays,
    this.phone,
    this.email,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory Shop.fromJson(Map<String, dynamic> json) {
    return Shop(
      id: json['id']?.toString(),
      userId: json['user_id']?.toString() ?? json['id_utilisateur']?.toString() ?? '',
      userName: json['user_name'] ?? json['nom_utilisateur'] ?? '',
      userProfilePhoto: json['user_profile_photo'] ?? json['photo_profil'],
      hasBlueBadge: json['has_blue_badge'] ?? json['badge_bleu'] ?? false,
      shopName: json['shop_name'] ?? '',
      description: json['description'],
      logoUrl: json['logo_url'],
      coverUrl: json['cover_url'],
      latitude: double.tryParse(json['latitude']?.toString() ?? '0') ?? 0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '0') ?? 0,
      address: json['address'] ?? '',
      pays: json['pays'] ?? '',
      phone: json['phone'],
      email: json['email'],
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.tryParse(json['created_at'] ?? DateTime.now().toIso8601String()) ?? DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'user_profile_photo': userProfilePhoto,
      'has_blue_badge': hasBlueBadge,
      'shop_name': shopName,
      'description': description,
      'logo_url': logoUrl,
      'cover_url': coverUrl,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'pays': pays,
      'phone': phone,
      'email': email,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Shop copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userProfilePhoto,
    bool? hasBlueBadge,
    String? shopName,
    String? description,
    String? logoUrl,
    String? coverUrl,
    double? latitude,
    double? longitude,
    String? address,
    String? pays,
    String? phone,
    String? email,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Shop(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userProfilePhoto: userProfilePhoto ?? this.userProfilePhoto,
      hasBlueBadge: hasBlueBadge ?? this.hasBlueBadge,
      shopName: shopName ?? this.shopName,
      description: description ?? this.description,
      logoUrl: logoUrl ?? this.logoUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      pays: pays ?? this.pays,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
