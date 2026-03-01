import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../models/product.dart';
import '../models/shop.dart';
import '../services/product_service.dart';
import '../services/shop_service.dart';
import '../../../core/api/api_constants.dart';
import '../../../core/l10n/app_localizations.dart';

/// Écran de gestion des produits
class ManageProductsScreen extends StatefulWidget {
  final Shop shop;
  
  const ManageProductsScreen({super.key, required this.shop});

  @override
  State<ManageProductsScreen> createState() => _ManageProductsScreenState();
}

class _ManageProductsScreenState extends State<ManageProductsScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  static const storage = FlutterSecureStorage();
  
  List<Product> _products = [];
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isAddingProduct = false;
  
  XFile? _selectedImageFile;
  Uint8List? _imageBytes;  // Bytes de l'image (web et mobile)
  String? _imageUrl;
  
  static const Color _kVertFonce = Color(0xFF2E7D32);
  
  final List<String> _categories = [
    'Vêtements',
    'Électronique',
    'Maison',
    'Cosmétiques',
    'Alimentation',
    'Sports',
    'Livres',
    'Jouets',
    'Automobile',
    'Autres',
  ];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      print('Chargement des produits pour shop: ${widget.shop.id}');
      final products = await ProductService.getProductsByShop(widget.shop.id!);
      print('Produits chargés: ${products.length}');
      for (final p in products) {
        print('  - ${p.productName} (image: ${p.imageUrl})');
      }
      if (mounted) {
        setState(() {
          _products = products;
          _isLoading = false;
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

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      
      if (image != null) {
        // Charger les bytes pour Image.memory (web et mobile)
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImageFile = image;
          _imageBytes = bytes;
        });
      }
    } catch (e) {
      print('Erreur sélection image: $e');
    }
  }

  Future<String?> _uploadImage(XFile image) async {
    try {
      final bytes = await image.readAsBytes();
      final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.uploadProductImage}');
      final request = http.MultipartRequest('POST', uri);
      
      final token = await storage.read(key: 'access_token');
      print('Upload - Token présent: ${token != null}');
      print('Upload - URL: $uri');
      
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.headers['Accept'] = 'application/json';
      
      // Détecter le type d'image depuis les bytes
      String extension = 'jpg';
      if (bytes.length >= 8) {
        // PNG signature: 89 50 4E 47 0D 0A 1A 0A
        if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) {
          extension = 'png';
        }
        // JPEG signature: FF D8 FF
        else if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
          extension = 'jpg';
        }
        // GIF signature: 47 49 46 38
        else if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x38) {
          extension = 'gif';
        }
        // WebP signature: 52 49 46 46 ... 57 45 42 50
        else if (bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46) {
          extension = 'webp';
        }
      }
      
      final filename = 'product_${DateTime.now().millisecondsSinceEpoch}.$extension';
      print('Upload - Extension détectée: $extension, filename: $filename');
      
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: filename,
        ),
      );

      print('Upload - Envoi de ${bytes.length} bytes...');
      final response = await request.send();
      
      print('Upload - Status: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseBody = await response.stream.bytesToString();
        print('Upload - Response: $responseBody');
        final jsonResponse = json.decode(responseBody);
        final url = jsonResponse['url'] ?? jsonResponse['image_url'];
        print('Upload - URL retournée: $url');
        return url;
      } else {
        final errorBody = await response.stream.bytesToString();
        print('Upload - Erreur: $errorBody');
      }
      
      return null;
    } catch (e) {
      print('Erreur upload: $e');
      return null;
    }
  }

  Future<void> _addProduct() async {
    if (_productNameController.text.isEmpty || _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('name_price_required')), backgroundColor: Colors.red),
      );
      return;
    }

    if (mounted) {
      setState(() {
        _isSaving = true;
      });
    }

    try {
      String? imageUrl = _imageUrl;
      if (_selectedImageFile != null) {
        print('Upload de l\'image en cours...');
        imageUrl = await _uploadImage(_selectedImageFile!);
        print('URL image après upload: $imageUrl');
        
        if (imageUrl == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.tr('image_upload_error')),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      }
      
      print('Création produit avec imageUrl: $imageUrl');
      
      final product = Product(
        shopId: widget.shop.id!,
        userId: widget.shop.userId,
        userName: widget.shop.userName,
        userProfilePhoto: widget.shop.userProfilePhoto,
        hasBlueBadge: widget.shop.hasBlueBadge,
        productName: _productNameController.text,
        description: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
        price: double.parse(_priceController.text),
        currency: 'EUR',
        imageUrl: imageUrl,
        pays: widget.shop.pays,
        category: _categoryController.text.isNotEmpty ? _categoryController.text : null,
        condition: 'neuf',
        isAvailable: true,
        stock: int.tryParse(_stockController.text) ?? 0,
        createdAt: DateTime.now(),
      );

      final savedProduct = await ProductService.createProduct(product);
      
      if (savedProduct != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('product_added')), backgroundColor: _kVertFonce),
        );
        
        _clearForm();
        _loadProducts();
      }
    } catch (e) {
      print('Erreur ajout produit: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.trParams('product_error', {'error': e.toString()})), backgroundColor: Colors.red),
      );
    }

    if (mounted) {
      setState(() {
        _isSaving = false;
        _isAddingProduct = false;
      });
    }
  }

  Future<void> _deleteProduct(Product product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('delete_product')),
        content: Text(context.trParams('delete_product_confirm', {'name': product.productName})),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.tr('delete'), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final success = await ProductService.deleteProduct(product.id!);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('product_deleted')), backgroundColor: _kVertFonce),
        );
        _loadProducts();
      }
    } catch (e) {
      print('Erreur suppression: $e');
    }
  }

  void _clearForm() {
    _productNameController.clear();
    _descriptionController.clear();
    _priceController.clear();
    _categoryController.clear();
    _stockController.clear();
    _selectedImageFile = null;
    _imageBytes = null;
    _imageUrl = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(context.trParams('products_title', {'shop': widget.shop.shopName})),
        backgroundColor: _kVertFonce,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isAddingProduct ? Icons.close : Icons.add),
            onPressed: () => setState(() {
              _isAddingProduct = !_isAddingProduct;
              if (!_isAddingProduct) _clearForm();
            }),
            tooltip: _isAddingProduct ? context.tr('cancel') : context.tr('add_product_tooltip'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _kVertFonce))
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Header avec logo de la boutique
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.white,
                    child: Row(
                      children: [
                        // Logo de la boutique
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey[200],
                          ),
                          child: widget.shop.logoUrl != null && widget.shop.logoUrl!.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: CachedNetworkImage(
                                    imageUrl: widget.shop.logoUrl!.startsWith('http')
                                        ? widget.shop.logoUrl!
                                        : '${ApiConstants.baseUrl}${widget.shop.logoUrl}',
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorWidget: (context, url, error) => Icon(Icons.store, color: Colors.grey[400]),
                                  ),
                                )
                              : Icon(Icons.store, color: Colors.grey[400]),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.shop.shopName,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                context.trParams('products_count', {'count': _products.length.toString()}),
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Formulaire d'ajout de produit
                  if (_isAddingProduct) _buildAddProductForm(),
                  
                  // Titre de la liste
                  if (_products.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.inventory_2, color: _kVertFonce),
                          const SizedBox(width: 8),
                          Text(
                            context.tr('my_products'),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // Liste des produits
                  if (_products.isEmpty && !_isAddingProduct)
                    Container(
                      padding: const EdgeInsets.all(48),
                      child: Column(
                        children: [
                          Icon(Icons.inventory_2, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            context.tr('no_products'),
                            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          Text(context.tr('click_to_add_product')),
                        ],
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(8),
                      itemCount: _products.length,
                      itemBuilder: (context, index) {
                        final product = _products[index];
                        return _buildProductCard(product);
                      },
                    ),
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildAddProductForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('new_product'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          // Image
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: double.infinity,
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[400]!),
                color: Colors.grey[100],
              ),
              child: _selectedImageFile != null && _imageBytes != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey[500]),
                        const SizedBox(height: 8),
                        Text(
                          context.tr('add_photo'),
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Nom du produit
          TextField(
            controller: _productNameController,
            decoration: InputDecoration(
              labelText: context.tr('product_name_required'),
              border: const OutlineInputBorder(),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Description
          TextField(
            controller: _descriptionController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: context.tr('description'),
              border: const OutlineInputBorder(),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Prix et Stock
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: context.tr('price_eur'),
                    border: const OutlineInputBorder(),
                    prefixText: '£ ',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _stockController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: context.tr('stock'),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Catégorie
          DropdownButtonFormField<String>(
            value: _categoryController.text.isNotEmpty ? _categoryController.text : null,
            decoration: InputDecoration(
              labelText: context.tr('category'),
              border: const OutlineInputBorder(),
            ),
            items: _categories.map((category) {
              return DropdownMenuItem(
                value: category,
                child: Text(category),
              );
            }).toList(),
            onChanged: (value) {
              _categoryController.text = value ?? '';
            },
          ),
          
          const SizedBox(height: 16),
          
          // Bouton Enregistrer
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _addProduct,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kVertFonce,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: _isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(context.tr('add_product_button'), style: const TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    // Construire l'URL complète de l'image
    String? fullImageUrl = product.imageUrl;
    if (fullImageUrl != null && fullImageUrl.isNotEmpty) {
      if (!fullImageUrl.startsWith('http://') && !fullImageUrl.startsWith('https://')) {
        fullImageUrl = '${ApiConstants.baseUrl}${fullImageUrl.startsWith('/') ? '' : '/'}$fullImageUrl';
      }
    }
    
    print('Affichage produit: ${product.productName}, image: $fullImageUrl');
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Image du produit
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[200],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: fullImageUrl != null && fullImageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: fullImageUrl,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Center(
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey[400]),
                        ),
                        errorWidget: (context, url, error) {
                          print('Erreur chargement image: $url, error: $error');
                          return Icon(Icons.image, color: Colors.grey[400]);
                        },
                      )
                    : Icon(Icons.image, color: Colors.grey[400]),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Infos produit
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.productName.isNotEmpty ? product.productName : context.tr('unnamed_product'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  if (product.description != null && product.description!.isNotEmpty)
                    Text(
                      product.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${product.price.toStringAsFixed(2)} £',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _kVertFonce,
                        ),
                      ),
                      if (product.category != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            product.category!,
                            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            
            // Bouton supprimer
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteProduct(product),
            ),
          ],
        ),
      ),
    );
  }
}
