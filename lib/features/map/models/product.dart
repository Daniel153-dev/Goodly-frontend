/// Modèle pour les produits
class Product {
  final String? id;
  final String shopId;
  final String userId;
  final String userName;
  final String? userProfilePhoto;
  final bool hasBlueBadge;
  final String productName;
  final String? description;
  final double price;
  final String currency;
  final String? imageUrl;
  final List<String>? additionalImages;
  final String pays;
  final String? category;
  final String? condition; // neuf, occasion, etc.
  final bool isAvailable;
  final int stock;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Product({
    this.id,
    required this.shopId,
    required this.userId,
    this.userName = '',
    this.userProfilePhoto,
    this.hasBlueBadge = false,
    required this.productName,
    this.description,
    required this.price,
    this.currency = 'EUR',
    this.imageUrl,
    this.additionalImages,
    required this.pays,
    this.category,
    this.condition,
    this.isAvailable = true,
    this.stock = 0,
    required this.createdAt,
    this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id']?.toString(),
      shopId: json['shop_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? json['id_utilisateur']?.toString() ?? '',
      userName: json['user_name'] ?? json['nom_utilisateur'] ?? '',
      userProfilePhoto: json['user_profile_photo'] ?? json['photo_profil'],
      hasBlueBadge: json['has_blue_badge'] ?? json['badge_bleu'] ?? false,
      productName: json['product_name'] ?? '',
      description: json['description'],
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0,
      currency: json['currency'] ?? 'EUR',
      imageUrl: json['image_url'],
      additionalImages: json['additional_images'] != null 
          ? List<String>.from(json['additional_images']) 
          : null,
      pays: json['pays'] ?? '',
      category: json['category'],
      condition: json['condition'],
      isAvailable: json['is_available'] ?? true,
      stock: json['stock'] ?? 0,
      createdAt: DateTime.tryParse(json['created_at'] ?? DateTime.now().toIso8601String()) ?? DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shop_id': shopId,
      'user_id': userId,
      'user_name': userName,
      'user_profile_photo': userProfilePhoto,
      'has_blue_badge': hasBlueBadge,
      'product_name': productName,
      'description': description,
      'price': price,
      'currency': currency,
      'image_url': imageUrl,
      'additional_images': additionalImages,
      'pays': pays,
      'category': category,
      'condition': condition,
      'is_available': isAvailable,
      'stock': stock,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Product copyWith({
    String? id,
    String? shopId,
    String? userId,
    String? userName,
    String? userProfilePhoto,
    bool? hasBlueBadge,
    String? productName,
    String? description,
    double? price,
    String? currency,
    String? imageUrl,
    List<String>? additionalImages,
    String? pays,
    String? category,
    String? condition,
    bool? isAvailable,
    int? stock,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userProfilePhoto: userProfilePhoto ?? this.userProfilePhoto,
      hasBlueBadge: hasBlueBadge ?? this.hasBlueBadge,
      productName: productName ?? this.productName,
      description: description ?? this.description,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      imageUrl: imageUrl ?? this.imageUrl,
      additionalImages: additionalImages ?? this.additionalImages,
      pays: pays ?? this.pays,
      category: category ?? this.category,
      condition: condition ?? this.condition,
      isAvailable: isAvailable ?? this.isAvailable,
      stock: stock ?? this.stock,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
