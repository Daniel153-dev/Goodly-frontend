import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/shop.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../../../core/api/api_constants.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../profile/screens/user_profile_screen.dart';

/// Modal pour afficher les produits d'une boutique avec filtres
class ShopProductsModal extends StatefulWidget {
  final Shop shop;
  
  const ShopProductsModal({super.key, required this.shop});

  @override
  State<ShopProductsModal> createState() => _ShopProductsModalState();
}

class _ShopProductsModalState extends State<ShopProductsModal> {
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = true;
  bool _showFilters = false;
  
  // Filtres
  String? _selectedCategory;
  RangeValues _priceRange = const RangeValues(0, 10000);
  double _minPrice = 0;
  double _maxPrice = 10000;
  
  static const Color _kVertFonce = Color(0xFF2E7D32);
  static const Color _kRouge = Color(0xFFE53935);
  
  // Catégories disponibles
  List<String> _getCategories(BuildContext context) {
    return [
      context.tr('all'),
      context.tr('category_clothing'),
      context.tr('category_electronics'),
      context.tr('category_home'),
      context.tr('category_cosmetics'),
      context.tr('category_food'),
      context.tr('category_sports'),
      context.tr('category_books'),
      context.tr('category_toys'),
      context.tr('category_automotive'),
      context.tr('category_others'),
    ];
  }

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final products = await ProductService.getProductsByShop(widget.shop.id!);
      if (mounted) {
        setState(() {
          _products = products;
          _isLoading = false;
          
          // Calculer les prix min/max
          if (products.isNotEmpty) {
            _minPrice = products.map((p) => p.price).reduce((a, b) => a < b ? a : b);
            _maxPrice = products.map((p) => p.price).reduce((a, b) => a > b ? a : b);
            _priceRange = RangeValues(_minPrice, _maxPrice);
          }
          
          _applyFilters();
        });
      }
    } catch (e) {
      print('Erreur chargement produits: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  void _applyFilters() {
    setState(() {
      _filteredProducts = _products.where((product) {
        // Filtre par catégorie
        if (_selectedCategory != null && 
            _selectedCategory != 'Toutes' && 
            product.category != _selectedCategory) {
          return false;
        }
        
        // Filtre par prix
        if (product.price < _priceRange.start || product.price > _priceRange.end) {
          return false;
        }
        
        return true;
      }).toList();
    });
  }

  String _getFullImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    return '${ApiConstants.baseUrl}${url.startsWith('/') ? '' : '/'}$url';
  }

  void _showProductDetail(Product product) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 500,
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Image du produit en grand
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: Container(
                      height: 300,
                      width: double.infinity,
                      color: Colors.grey[200],
                      child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: _getFullImageUrl(product.imageUrl),
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Center(
                                child: CircularProgressIndicator(color: Colors.grey[400]),
                              ),
                              errorWidget: (context, url, error) => Icon(
                                Icons.image,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                            )
                          : Icon(Icons.image, size: 80, color: Colors.grey[400]),
                    ),
                  ),
                  // Bouton fermer
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                  // Badge catégorie
                  if (product.category != null)
                    Positioned(
                      bottom: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _kRouge,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          product.category!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              
              // Informations du produit
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nom et prix
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              product.productName.isNotEmpty ? product.productName : context.tr('product'),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _kVertFonce,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${product.price.toStringAsFixed(2)} £',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Profil du vendeur
                      GestureDetector(
                        onTap: () {
                          print('ShopProductsModal - userId: ${widget.shop.userId}');
                          print('ShopProductsModal - userName: ${widget.shop.userName}');
                          if (widget.shop.userId.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(context.tr('profile_access_error')),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UserProfileScreen(
                                userId: widget.shop.userId,
                                userName: widget.shop.userName,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              // Photo de profil sans badge bleu (déjà affiché à côté du nom)
                              CircleAvatar(
                                radius: 24,
                                backgroundImage: widget.shop.userProfilePhoto != null && 
                                                widget.shop.userProfilePhoto!.isNotEmpty
                                    ? CachedNetworkImageProvider(_getFullImageUrl(widget.shop.userProfilePhoto))
                                    : null,
                                child: widget.shop.userProfilePhoto == null || 
                                       widget.shop.userProfilePhoto!.isEmpty
                                    ? Icon(Icons.person, color: Colors.grey[400])
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            widget.shop.userName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        // Badge bleu à côté du nom
                                        if (widget.shop.hasBlueBadge)
                                          Padding(
                                            padding: const EdgeInsets.only(left: 4),
                                            child: Image.asset(
                                              'assets/images/badge_bleu.png',
                                              width: 16,
                                              height: 16,
                                            ),
                                          ),
                                      ],
                                    ),
                                    Text(
                                      context.tr('view_profile'),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Description
                      if (product.description != null && product.description!.isNotEmpty) ...[
                        Text(
                          context.tr('description'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          product.description!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 16),
                      
                      // Informations supplémentaires
                      Row(
                        children: [
                          if (product.stock > 0)
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.green[200]!),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.inventory, color: Colors.green[700], size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      context.trParams('stock_label', {'count': product.stock.toString()}),
                                      style: TextStyle(
                                        color: Colors.green[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (product.condition != null) ...[
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blue[200]!),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      product.condition!,
                                      style: TextStyle(
                                        color: Colors.blue[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // URL de la photo de profil
    String? profilePhotoUrl = widget.shop.userProfilePhoto;
    if (profilePhotoUrl != null && profilePhotoUrl.isNotEmpty) {
      profilePhotoUrl = _getFullImageUrl(profilePhotoUrl);
    }
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle pour glisser
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header avec profil du créateur
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              children: [
                // Photo de profil du créateur (cliquable)
                GestureDetector(
                  onTap: () {
                    if (widget.shop.userId.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(context.tr('profile_access_error_short')),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserProfileScreen(
                          userId: widget.shop.userId,
                          userName: widget.shop.userName,
                        ),
                      ),
                    );
                  },
                  child: CircleAvatar(
                    radius: 28,
                    backgroundImage: profilePhotoUrl != null && profilePhotoUrl.isNotEmpty
                        ? CachedNetworkImageProvider(profilePhotoUrl)
                        : null,
                    child: profilePhotoUrl == null || profilePhotoUrl.isEmpty
                        ? Icon(Icons.person, size: 28, color: Colors.grey[400])
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (widget.shop.userId.isEmpty) return;
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserProfileScreen(
                            userId: widget.shop.userId,
                            userName: widget.shop.userName,
                          ),
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                widget.shop.userName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Badge bleu à côté du nom
                            if (widget.shop.hasBlueBadge)
                              Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Image.asset(
                                  'assets/images/badge_bleu.png',
                                  width: 18,
                                  height: 18,
                                ),
                              ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.open_in_new,
                              size: 14,
                              color: Colors.grey[400],
                            ),
                          ],
                        ),
                        Text(
                          widget.shop.shopName,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${_filteredProducts.length}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _kRouge,
                      ),
                    ),
                    Text(
                      context.tr('products'),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          
          // Adresse de la boutique
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey[50],
            child: Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    widget.shop.address,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          
          // Bouton filtres
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _showFilters = !_showFilters;
                      });
                    },
                    icon: Icon(
                      _showFilters ? Icons.filter_list_off : Icons.filter_list,
                      size: 18,
                    ),
                    label: Text(_showFilters ? context.tr('hide_filters') : context.tr('filters')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _kVertFonce,
                      side: BorderSide(color: _kVertFonce),
                    ),
                  ),
                ),
                if (_selectedCategory != null && _selectedCategory != 'Toutes') ...[
                  const SizedBox(width: 8),
                  InputChip(
                    label: Text(_selectedCategory!),
                    onDeleted: () {
                      setState(() {
                        _selectedCategory = null;
                        _applyFilters();
                      });
                    },
                    backgroundColor: _kVertFonce.withOpacity(0.1),
                    labelStyle: TextStyle(color: _kVertFonce),
                    deleteIconColor: _kVertFonce,
                  ),
                ],
              ],
            ),
          ),
          
          // Panneau de filtres
          if (_showFilters)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(
                  bottom: BorderSide(color: Colors.grey[200]!),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filtre par catégorie
                  Text(
                    context.tr('category'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 40,
                    child: Builder(
                      builder: (context) {
                        final categories = _getCategories(context);
                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: categories.length,
                          itemBuilder: (context, index) {
                            final category = categories[index];
                            final isSelected = _selectedCategory == category || 
                                (category == context.tr('all') && _selectedCategory == null);
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(category),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedCategory = category == context.tr('all') ? null : category;
                                    _applyFilters();
                                  });
                                },
                                selectedColor: _kVertFonce.withOpacity(0.2),
                                checkmarkColor: _kVertFonce,
                                labelStyle: TextStyle(
                                  color: isSelected ? _kVertFonce : Colors.grey[700],
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Filtre par prix
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.tr('price'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_priceRange.start.toStringAsFixed(0)} £ - ${_priceRange.end.toStringAsFixed(0)} £',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  RangeSlider(
                    values: _priceRange,
                    min: _minPrice,
                    max: _maxPrice,
                    divisions: 20,
                    activeColor: _kVertFonce,
                    inactiveColor: Colors.grey[300],
                    labels: RangeLabels(
                      '${_priceRange.start.toStringAsFixed(0)} £',
                      '${_priceRange.end.toStringAsFixed(0)} £',
                    ),
                    onChanged: (values) {
                      setState(() {
                        _priceRange = values;
                      });
                    },
                    onChangeEnd: (values) {
                      _applyFilters();
                    },
                  ),
                  
                  // Bouton réinitialiser
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedCategory = null;
                          _priceRange = RangeValues(_minPrice, _maxPrice);
                          _applyFilters();
                        });
                      },
                      icon: const Icon(Icons.refresh, size: 16),
                      label: Text(context.tr('reset')),
                      style: TextButton.styleFrom(
                        foregroundColor: _kRouge,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          // Liste des produits
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: _kVertFonce))
                : _filteredProducts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              _products.isEmpty ? context.tr('no_products') : context.tr('no_products_filters'),
                              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _products.isEmpty 
                                  ? context.tr('shop_no_products')
                                  : context.tr('try_change_filters'),
                              style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.65,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: _filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = _filteredProducts[index];
                          return _buildProductCard(product);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return GestureDetector(
      onTap: () => _showProductDetail(product),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image du produit
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      color: Colors.grey[200],
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: _getFullImageUrl(product.imageUrl),
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.grey[400],
                                ),
                              ),
                              errorWidget: (context, url, error) => Icon(
                                Icons.image,
                                size: 40,
                                color: Colors.grey[400],
                              ),
                            )
                          : Icon(Icons.image, size: 40, color: Colors.grey[400]),
                    ),
                  ),
                  // Indicateur cliquable
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.zoom_in,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Infos produit
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.productName.isNotEmpty ? product.productName : context.tr('product'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (product.description != null && product.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      product.description!,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        '${product.price.toStringAsFixed(2)} £',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _kRouge,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Détails supplémentaires
                  Row(
                    children: [
                      if (product.category != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: _kRouge.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            product.category!,
                            style: TextStyle(fontSize: 10, color: _kRouge, fontWeight: FontWeight.w500),
                          ),
                        ),
                      if (product.stock > 0) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.inventory, size: 10, color: Colors.green[700]),
                              const SizedBox(width: 2),
                              Text(
                                '${product.stock}',
                                style: TextStyle(fontSize: 10, color: Colors.green[700], fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
