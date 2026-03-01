import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../models/shop.dart';
import '../services/shop_service.dart';
import 'manage_products_screen.dart';
import '../../../core/api/api_constants.dart';
import '../../../core/l10n/app_localizations.dart';

/// Retourne l'URL absolue pour une photo
String _getPhotoUrl(String? photoUrl) {
  if (photoUrl == null || photoUrl.isEmpty) return '';
  if (photoUrl.startsWith('http://') || photoUrl.startsWith('https://')) {
    return photoUrl;
  }
  String normalizedUrl = photoUrl.replaceAll('\\', '/');
  if (!normalizedUrl.startsWith('/')) {
    normalizedUrl = '/$normalizedUrl';
  }
  return '${ApiConstants.baseUrl}$normalizedUrl';
}

Future<Map<String, dynamic>> _getCurrentUserInfo() async {
  final prefs = await SharedPreferences.getInstance();
  final sessionJson = prefs.getString('current_session') ?? prefs.getString('user_session');
  
  if (sessionJson != null) {
    try {
      final sessionData = json.decode(sessionJson);
      
      String userName = '';
      if (sessionData['nom_utilisateur'] != null && sessionData['nom_utilisateur'].toString().isNotEmpty) {
        userName = sessionData['nom_utilisateur'];
      } else if (sessionData['prenom'] != null || sessionData['nom'] != null) {
        userName = '${sessionData['prenom'] ?? ''} ${sessionData['nom'] ?? ''}'.trim();
      }
      
      String? profilePhoto = sessionData['photo_profil'] ?? sessionData['profile_picture'];
      if (profilePhoto != null && profilePhoto.isNotEmpty) {
        profilePhoto = _getPhotoUrl(profilePhoto);
      }
      
      return {
        'id': sessionData['id_utilisateur']?.toString() ?? 'anonymous',
        'name': userName.isNotEmpty ? userName : 'Anonyme',
        'profilePhoto': profilePhoto ?? '',
        'hasBlueBadge': sessionData['has_blue_badge'] ?? false,
      };
    } catch (e) {
      return {'id': 'anonymous', 'name': 'Anonyme', 'profilePhoto': '', 'hasBlueBadge': false};
    }
  }
  return {'id': 'anonymous', 'name': 'Anonyme', 'profilePhoto': '', 'hasBlueBadge': false};
}

/// Écran de création de boutique
class CreateShopScreen extends StatefulWidget {
  const CreateShopScreen({super.key});

  @override
  State<CreateShopScreen> createState() => _CreateShopScreenState();
}

class _CreateShopScreenState extends State<CreateShopScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _shopNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  
  bool _isLoading = false;
  bool _isSaving = false;
  bool _hasExistingShop = false;
  Shop? _existingShop;
  
  final MapController _mapController = MapController();
  LatLng? _selectedPosition;
  String? _selectedAddress;
  List<dynamic> _searchResults = [];
  bool _isSearching = false;
  bool _isAddMode = false;
  
  XFile? _selectedLogoFile;
  Uint8List? _logoBytes;  // Bytes de l'image (web et mobile)
  String? _logoUrl;
  
  XFile? _selectedCoverFile;
  Uint8List? _coverBytes;  // Bytes de l'image (web et mobile)
  String? _coverUrl;

  static const Color _kVertFonce = Color(0xFF2E7D32);

  @override
  void initState() {
    super.initState();
    _loadExistingShop();
  }

  Future<void> _loadExistingShop() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final shop = await ShopService.getMyShop();
      if (shop != null) {
        _existingShop = shop;
        _hasExistingShop = true;
        _shopNameController.text = shop.shopName;
        _descriptionController.text = shop.description ?? '';
        _phoneController.text = shop.phone ?? '';
        _emailController.text = shop.email ?? '';
        _selectedPosition = LatLng(shop.latitude, shop.longitude);
        _selectedAddress = shop.address;
        _logoUrl = shop.logoUrl;
        _coverUrl = shop.coverUrl;
        
        _mapController.move(_selectedPosition!, 15.0);
      }
    } catch (e) {
      print('Erreur chargement boutique: $e');
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _searchPlace(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=5&addressdetails=1',
        ),
        headers: {'User-Agent': 'GoodlyApp/1.0'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _searchResults = data;
        });
      }
    } catch (e) {
      print('Erreur recherche: $e');
    }

    setState(() {
      _isSearching = false;
    });
  }

  void _selectSearchResult(dynamic result) {
    final lat = double.parse(result['lat']);
    final lon = double.parse(result['lon']);
    final newPosition = LatLng(lat, lon);
    final address = result['display_name'] ?? '${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)}';
    
    _mapController.move(newPosition, 15.0);
    
    setState(() {
      _selectedPosition = newPosition;
      _selectedAddress = address;
      _searchResults = [];
      _searchController.clear();
      _isAddMode = true;
    });
  }

  Future<void> _centerOnUserLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showPermissionDialog();
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final newPosition = LatLng(position.latitude, position.longitude);
      _mapController.move(newPosition, 15.0);
      
      setState(() {
        _selectedPosition = newPosition;
        _selectedAddress = '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
        _isAddMode = true;
      });
    } catch (e) {
      print('Erreur: $e');
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('permission_required')),
        content: Text(context.tr('geolocation_required_shop')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  Future<void> _pickLogo() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 80,
      );
      
      if (image != null) {
        // Charger les bytes pour Image.memory (web et mobile)
        final bytes = await image.readAsBytes();
        
        setState(() {
          _selectedLogoFile = image;
          _logoBytes = bytes;
          _logoUrl = null; // Afficher le fichier local sélectionné
        });
      }
    } catch (e) {
      print('Erreur sélection logo: $e');
    }
  }

  Future<void> _pickCover() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 400,
        imageQuality: 80,
      );
      
      if (image != null) {
        // Charger les bytes pour Image.memory (web et mobile)
        final bytes = await image.readAsBytes();
        
        setState(() {
          _selectedCoverFile = image;
          _coverBytes = bytes;
          _coverUrl = null; // Afficher le fichier local sélectionné
        });
      }
    } catch (e) {
      print('Erreur sélection couverture: $e');
    }
  }

  Future<String?> _uploadImage(XFile image, String endpoint) async {
    try {
      print('[$endpoint] Début upload image: ${image.name}');
      final bytes = await image.readAsBytes();
      print('[$endpoint] Taille image: ${bytes.length} bytes');
      
      final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      print('[$endpoint] URL upload: $uri');
      
      final request = http.MultipartRequest('POST', uri);
      
      // Récupérer le token depuis FlutterSecureStorage
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'access_token');
      print('[$endpoint] Token présent: ${token != null}');
      
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.headers['Accept'] = 'application/json';
      
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: 'image_${DateTime.now().millisecondsSinceEpoch}.webp',
        ),
      );

      print('[$endpoint] Envoi de la requête...');
      final response = await request.send();
      print('[$endpoint] Réponse status: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseBody = await response.stream.bytesToString();
        print('[$endpoint] Réponse: $responseBody');
        final jsonResponse = json.decode(responseBody);
        return jsonResponse['url'] ?? jsonResponse['image_url'];
      } else {
        final responseBody = await response.stream.bytesToString();
        print('[$endpoint] Erreur: $responseBody');
      }
      
      return null;
    } catch (e) {
      print('[$endpoint] ERREUR upload: $e');
      return null;
    }
  }

  Future<void> _saveShop() async {
    if (_shopNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('shop_name_required')), backgroundColor: Colors.red),
      );
      return;
    }

    if (_selectedPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('select_position_map')), backgroundColor: Colors.red),
      );
      return;
    }

    print('=== DÉBUT SAUVEGARDE BOUTIQUE ===');
    print('Nom: ${_shopNameController.text}');
    print('Position: $_selectedPosition');
    print('Logo sélectionné: ${_selectedLogoFile != null}');
    print('Cover sélectionné: ${_selectedCoverFile != null}');

    if (mounted) {
      setState(() {
        _isSaving = true;
      });
    }

    try {
      final userInfo = await _getCurrentUserInfo();
      print('User info: $userInfo');
      
      // ÉTAPE 1 : Créer la boutique SANS les médias
      final pays = _selectedAddress?.split(',').last.trim() ?? '';
      print('Pays: $pays');
      
      final shop = Shop(
        id: _existingShop?.id,
        userId: userInfo['id']!,
        userName: userInfo['name']!,
        userProfilePhoto: userInfo['profilePhoto'],
        hasBlueBadge: userInfo['hasBlueBadge'] ?? false,
        shopName: _shopNameController.text,
        description: _descriptionController.text,
        logoUrl: _logoUrl, // Utiliser l'URL existante si elle existe
        coverUrl: _coverUrl, // Utiliser l'URL existante si elle existe
        latitude: _selectedPosition!.latitude,
        longitude: _selectedPosition!.longitude,
        address: _selectedAddress ?? '',
        pays: pays,
        phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
        email: _emailController.text.isNotEmpty ? _emailController.text : null,
        isActive: true,
        createdAt: _existingShop?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      print('Appel API création boutique...');
      Shop? savedShop;
      if (_hasExistingShop) {
        savedShop = await ShopService.updateShop(_existingShop!.id!, shop);
      } else {
        savedShop = await ShopService.createShop(shop);
      }

      print('Réponse API: $savedShop');

      if (savedShop == null) {
        print('ERREUR: savedShop est null - Création échouée');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('shop_creation_error')), backgroundColor: Colors.red),
        );
        return;
      }

      // ÉTAPE 2 : Uploader les médias si nécessaire (maintenant que la boutique existe)
      if (_selectedLogoFile != null) {
        print('Upload logo...');
        final logoUrl = await _uploadImage(_selectedLogoFile!, ApiConstants.uploadShopLogo);
        print('Logo URL: $logoUrl');
      }
      
      if (_selectedCoverFile != null) {
        print('Upload cover...');
        final coverUrl = await _uploadImage(_selectedCoverFile!, ApiConstants.uploadShopCover);
        print('Cover URL: $coverUrl');
      }

      if (mounted) {
        print('=== BOUTIQUE CRÉÉE AVEC SUCCÈS ===');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_hasExistingShop 
              ? context.tr('shop_updated') 
              : context.tr('shop_created')),
            backgroundColor: _kVertFonce,
          ),
        );
        
        // Naviguer vers la gestion des produits
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ManageProductsScreen(shop: savedShop!),
          ),
        );
      }
    } catch (e) {
      print('ERREUR EXCEPTION: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${context.tr('error')}: $e'), backgroundColor: Colors.red),
      );
    }

    if (mounted) {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(_hasExistingShop ? context.tr('my_shop') : context.tr('create_my_shop')),
        backgroundColor: _kVertFonce,
        foregroundColor: Colors.white,
        actions: [
          if (_hasExistingShop && _existingShop != null)
            IconButton(
              icon: const Icon(Icons.inventory_2),
              tooltip: context.tr('manage_products'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ManageProductsScreen(shop: _existingShop!),
                  ),
                );
              },
            ),
          TextButton(
            onPressed: _isSaving ? null : _saveShop,
            child: Text(
              _isSaving ? context.tr('saving') : context.tr('save'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _kVertFonce))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section Logo
                  _buildSectionTitle(context.tr('shop_logo')),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _pickLogo,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey[200],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: _selectedLogoFile != null && _logoBytes != null
                                ? Image.memory(
                                    _logoBytes!,
                                    fit: BoxFit.cover,
                                    key: ValueKey(_selectedLogoFile!.path),
                                  )
                                : _logoUrl != null && _logoUrl!.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: _logoUrl!,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) =>
                                            Icon(Icons.image, size: 40, color: Colors.grey[400]),
                                        errorWidget: (context, url, error) =>
                                            Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey[500]),
                                      )
                                    : Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey[500]),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          context.tr('click_add_logo'),
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Section Couverture
                  _buildSectionTitle(context.tr('cover_photo')),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickCover,
                    child: Container(
                      width: double.infinity,
                      height: 150,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey[200],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _selectedCoverFile != null && _coverBytes != null
                            ? Image.memory(
                                _coverBytes!,
                                fit: BoxFit.cover,
                                key: ValueKey(_selectedCoverFile!.path),
                              )
                            : _coverUrl != null && _coverUrl!.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: _coverUrl!,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.image, size: 40, color: Colors.grey[400]),
                                        const SizedBox(height: 8),
                                        Text(context.tr('loading'), style: TextStyle(color: Colors.grey[600])),
                                      ],
                                    ),
                                    errorWidget: (context, url, error) => Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey[500]),
                                        const SizedBox(height: 8),
                                        Text(
                                          context.tr('add_cover_photo'),
                                          style: TextStyle(color: Colors.grey[600]),
                                        ),
                                      ],
                                    ),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey[500]),
                                      const SizedBox(height: 8),
                                      Text(
                                        context.tr('add_cover_photo'),
                                        style: TextStyle(color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Section Infos Boutique
                  _buildSectionTitle(context.tr('shop_info')),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _shopNameController,
                    label: '${context.tr('shop_name')} *',
                    icon: Icons.store,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _descriptionController,
                    label: context.tr('description'),
                    icon: Icons.description,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _phoneController,
                          label: context.tr('phone'),
                          icon: Icons.phone,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          controller: _emailController,
                          label: context.tr('email'),
                          icon: Icons.email,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Section Localisation
                  _buildSectionTitle('${context.tr('location')} *'),
                  const SizedBox(height: 8),
                  
                  // Barre de recherche
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: context.tr('search_place'),
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _isSearching
                          ? const CircularProgressIndicator(strokeWidth: 2)
                          : IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchResults = [];
                                });
                              },
                            ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: _searchPlace,
                  ),
                  
                  // Résultats de recherche
                  if (_searchResults.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4),
                        ],
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final result = _searchResults[index];
                          return ListTile(
                            leading: const Icon(Icons.location_on, color: Colors.red),
                            title: Text(
                              result['display_name']?.toString().split(',').take(3).join(',') ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () => _selectSearchResult(result),
                          );
                        },
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 8),
                  
                  // Bouton position actuelle
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _centerOnUserLocation,
                      icon: const Icon(Icons.my_location),
                      label: Text(context.tr('use_current_location')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kVertFonce,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Carte
                  Container(
                    height: 250,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _selectedPosition ?? const LatLng(48.8566, 2.3522),
                        initialZoom: 13.0,
                        onTap: (tapPosition, point) {
                          setState(() {
                            _selectedPosition = point;
                            _isAddMode = true;
                          });
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.goodly.app',
                        ),
                        if (_selectedPosition != null)
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _selectedPosition!,
                                width: 40,
                                height: 40,
                                child: GestureDetector(
                                  onTap: () {
                                    // Permet de supprimer le marqueur en tapant dessus
                                    setState(() {
                                      _selectedPosition = null;
                                      _selectedAddress = null;
                                    });
                                  },
                                  child: const Icon(
                                    Icons.location_pin,
                                    color: Colors.red,
                                    size: 40,
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  
                  if (_selectedAddress != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on, color: _kVertFonce),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedAddress!,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                  
                  // Bouton Enregistrer
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveShop,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kVertFonce,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              _hasExistingShop ? context.tr('update') : context.tr('create_my_shop'),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  
                  // Bouton pour gérer les produits (si boutique existe)
                  if (_hasExistingShop && _existingShop != null) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ManageProductsScreen(shop: _existingShop!),
                            ),
                          );
                        },
                        icon: const Icon(Icons.inventory_2),
                        label: Text(context.tr('manage_my_products')),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _kVertFonce,
                          side: const BorderSide(color: _kVertFonce),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: _kVertFonce,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _kVertFonce),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

