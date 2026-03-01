import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/scheduler.dart';
import '../models/event_location.dart';
import '../models/shop.dart';
import '../models/map_story.dart';
import '../services/location_storage_service.dart';
import '../services/shop_service.dart';
import '../services/map_story_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/api/api_constants.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../profile/screens/user_profile_screen.dart';
import 'shop_products_modal.dart';
import 'create_story_modal.dart';
import 'story_viewer_screen.dart';

/// Écran Map Interactive avec OpenStreetMap
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  bool _isLoading = false;
  bool _isSearching = false;
  bool _isUserLocationLoading = false;
  bool _isEventsLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  String? _currentAddress;
  Position? _currentPosition;
  
  LatLng _initialPosition = const LatLng(48.8566, 2.3522);
  final MapController _mapController = MapController();

  // Suggestions de recherche
  List<dynamic> _searchSuggestions = [];
  bool _showSuggestions = false;

  // Marqueurs sur la carte
  final List<Marker> _markers = [];

  // Événements
  List<EventLocation> _events = [];
  bool _showEventsOnMap = false;

  // Boutiques
  List<Shop> _shops = [];
  bool _showShopsOnMap = false;
  bool _isShopsLoading = false;

  // Stories
  List<MapStory> _stories = [];
  bool _showStoriesOnMap = false;
  bool _isStoriesLoading = false;
  
  // Cercles de floutage pour les stories (protection vie privée)
  List<CircleMarker> _storyBlurCircles = [];

  // Niveau de zoom actuel
  double _currentZoom = 14.0;
  static const double _minZoom = 3.0;
  static const double _maxZoom = 19.0;

  String? _currentUserId;
  bool _dataLoaded = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_pulseController);
    _getCurrentLocation();
    _loadUserInfo();
    // Charger et afficher les stories automatiquement au démarrage
    _showStoriesOnMap = true;
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    final userInfo = await _getCurrentUserInfo();
    if (mounted) {
      setState(() {
        _currentUserId = userInfo['id'];
      });
    }
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
          profilePhoto = _getProfilePhotoUrl(profilePhoto);
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    // Éviter les chargements multiples
    if (_isEventsLoading) return;

    if (mounted) {
      setState(() {
        _isEventsLoading = true;
        _hasError = false;
        _errorMessage = '';
      });
    }

    try {
      print('Fetching events from backend...');
      final allEvents = await LocationStorageService.getEventsLocations();
      
      print('Backend returned ${allEvents.length} events');
      
      // Debug: afficher les dates de chaque événement
      for (final event in allEvents) {
        final hoursAgo = event.eventDateTime != null 
            ? DateTime.now().difference(event.eventDateTime!).inMinutes 
            : 0;
        print('Event: ${event.title}');
        print('  eventDateTime: ${event.eventDateTime}');
        print('  isExpired: ${event.isExpired} ($hoursAgo minutes ago)');
      }
      
      // Filtrer les événements non expirés (date non passée)
      final validEvents = allEvents.where((e) => !e.isExpired).toList();
      
      print('Valid events after filter: ${validEvents.length}');
      
      if (mounted) {
        setState(() {
          _events = validEvents;
          _isEventsLoading = false;
          _dataLoaded = true;
          print('${_events.length} valid events loaded.');
        });
        _refreshMarkers();
      }
    } catch (e) {
      print('Erreur chargement événements: $e');
      if (mounted) {
        setState(() {
          _isEventsLoading = false;
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isUserLocationLoading = true;
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showPermissionDialog();
          setState(() {
            _isUserLocationLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showPermissionDialog();
        setState(() {
          _isUserLocationLoading = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _currentPosition = position;
          _initialPosition = LatLng(position.latitude, position.longitude);
          _isUserLocationLoading = false;
        });

        _centerOnUserLocation();
        
        // Charger automatiquement les stories au démarrage
        if (_showStoriesOnMap) {
          _loadStories();
        }
      }
    } catch (e) {
      print('Erreur de localisation: $e');
      setState(() {
        _isUserLocationLoading = false;
      });
    }
  }

  void _centerOnUserLocation() {
    if (_currentPosition != null) {
      final userPosition = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
      
      _mapController.move(userPosition, _currentZoom);
      
      setState(() {
        _markers.removeWhere((m) => m.point.latitude == userPosition.latitude && 
                                       m.point.longitude == userPosition.longitude);
        _markers.add(
          Marker(
            point: userPosition,
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const Icon(
                    Icons.location_pin,
                    color: Colors.red,
                    size: 40,
                  ),
                ],
              ),
            ),
          ),
        );
      });
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('location_permission')),
        content: Text(context.tr('enable_location_settings')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Recherche de lieux avec Nominatim
  Future<void> _searchPlaces(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchSuggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?'
        'q=$query'
        '&format=json'
        '&limit=5'
        '&addressdetails=1'
        '&language=fr'
      );

      final response = await http.get(url, headers: {
        'User-Agent': 'GoodlyApp/1.0',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List && data.isNotEmpty) {
          setState(() {
            _searchSuggestions = data;
            _showSuggestions = true;
          });
        } else {
          setState(() {
            _searchSuggestions = [];
            _showSuggestions = false;
          });
        }
      }
    } catch (e) {
      print('Erreur de recherche: $e');
      setState(() {
        _searchSuggestions = [];
      });
    }

    setState(() {
      _isSearching = false;
    });
  }

  void _selectPlace(dynamic place) {
    final lat = double.parse(place['lat']);
    final lon = double.parse(place['lon']);
    final newPosition = LatLng(lat, lon);
    final displayName = place['display_name'] ?? 'Lieu trouvé';

    setState(() {
      _showSuggestions = false;
      _currentAddress = displayName;
      _searchController.text = '';
      _showEventsOnMap = false;
    });

    setState(() {
      _markers.clear();
      _markers.add(
        Marker(
          point: newPosition,
          child: const Icon(
            Icons.location_pin,
            color: Colors.red,
            size: 40,
          ),
        ),
      );
    });

    _mapController.move(newPosition, _currentZoom);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchSuggestions = [];
      _showSuggestions = false;
      _markers.clear();
    });
  }

  void _refreshMarkers() {
    if (mounted) {
      print('=== _refreshMarkers appelé ===');
      print('_showShopsOnMap=$_showShopsOnMap, _showEventsOnMap=$_showEventsOnMap, _showStoriesOnMap=$_showStoriesOnMap');
      setState(() {
        _markers.clear();
        
        // Ajouter la position de l'utilisateur
        if (_currentPosition != null) {
          final userPosition = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
          _markers.add(
            Marker(
              point: userPosition,
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const Icon(
                      Icons.location_pin,
                      color: Colors.red,
                      size: 40,
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        
        if (_showShopsOnMap) {
          print('Appel de _addShopMarkers depuis _refreshMarkers');
          _addShopMarkers();
        }
        
        if (_showEventsOnMap) {
          print('Appel de _addEventMarkers depuis _refreshMarkers');
          _addEventMarkers();
        }
        
        if (_showStoriesOnMap) {
          _addStoryMarkers();
        }
      });
    }
  }

  void _toggleEventsOnMap() {
    if (mounted) {
      print('=== _toggleEventsOnMap ===');
      print('Avant: _showEventsOnMap=$_showEventsOnMap, _showShopsOnMap=$_showShopsOnMap');
      setState(() {
        _showEventsOnMap = !_showEventsOnMap;
        // Si on active les événements, désactiver les stories (exclusives)
        // Mais on garde les boutiques actives
        if (_showEventsOnMap) {
          _showStoriesOnMap = false;
        }
        print('Après: _showEventsOnMap=$_showEventsOnMap, _showShopsOnMap=$_showShopsOnMap');
        if (_showEventsOnMap && _events.isEmpty) {
          _loadEvents();
        } else {
          _refreshMarkers();
        }
      });
    }
  }

  // ============ BOUTIQUES ============

  Future<void> _loadShops() async {
    if (_isShopsLoading) return;

    if (mounted) {
      setState(() {
        _isShopsLoading = true;
      });
    }

    try {
      final shops = await ShopService.getAllShops();
      if (mounted) {
        setState(() {
          _shops = shops;
          _isShopsLoading = false;
        });
        _refreshMarkers();
      }
    } catch (e) {
      print('Erreur chargement boutiques: $e');
      if (mounted) {
        setState(() {
          _isShopsLoading = false;
        });
      }
    }
  }

  void _toggleShopsOnMap() {
    if (mounted) {
      print('=== _toggleShopsOnMap ===');
      print('Avant: _showShopsOnMap=$_showShopsOnMap, _showEventsOnMap=$_showEventsOnMap');
      setState(() {
        _showShopsOnMap = !_showShopsOnMap;
        // Si on active les boutiques, désactiver les stories (exclusives)
        // Mais on garde les événements actifs
        if (_showShopsOnMap) {
          _showStoriesOnMap = false;
        }
        print('Après: _showShopsOnMap=$_showShopsOnMap, _showEventsOnMap=$_showEventsOnMap');
        if (_showShopsOnMap && _shops.isEmpty) {
          _loadShops();
        } else {
          _refreshMarkers();
        }
      });
    }
  }

  void _addShopMarkers() {
    print('=== _addShopMarkers appelé, _shops.length = ${_shops.length} ===');
    // Ne pas effacer les autres marqueurs, juste ajouter les boutiques
    for (final shop in _shops) {
      print('Ajout marqueur boutique: ${shop.shopName} à ${shop.latitude}, ${shop.longitude}');
      _markers.add(
        Marker(
          point: LatLng(shop.latitude, shop.longitude),
          child: GestureDetector(
            onTap: () => _showShopDetails(shop),
            child: _buildShopMarker(shop),
          ),
        ),
      );
    }
    print('Total marqueurs après boutiques: ${_markers.length}');
  }

  Widget _buildShopMarker(Shop shop) {
    // Construire l'URL de la photo de profil
    String? profilePhotoUrl = shop.userProfilePhoto;
    if (profilePhotoUrl != null && profilePhotoUrl.isNotEmpty) {
      if (!profilePhotoUrl.startsWith('http://') && !profilePhotoUrl.startsWith('https://')) {
        profilePhotoUrl = '${ApiConstants.baseUrl}${profilePhotoUrl.startsWith('/') ? '' : '/'}$profilePhotoUrl';
      }
    }
    
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = 1.0 + _pulseController.value * 0.1;
        final glowOpacity = 0.4 + _pulseController.value * 0.4;
        return OverflowBox(
          maxWidth: 90,
          maxHeight: 90,
          minWidth: 60,
          minHeight: 60,
          alignment: Alignment.center,
          child: Transform.scale(
            scale: scale,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Photo de profil avec glow
                Container(
                  width: 60,
                  height: 60,
                  padding: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.red.withOpacity(0.8),
                        Colors.red.withOpacity(0.6),
                        Colors.red.withOpacity(0.4),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(glowOpacity),
                        blurRadius: 6 + _pulseController.value * 6,
                        spreadRadius: 1 + _pulseController.value * 2,
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 29,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 28,
                      backgroundImage: profilePhotoUrl != null && profilePhotoUrl.isNotEmpty
                          ? CachedNetworkImageProvider(profilePhotoUrl)
                          : null,
                      child: profilePhotoUrl == null || profilePhotoUrl.isEmpty
                          ? Icon(Icons.store, size: 24, color: Colors.grey[400])
                          : null,
                    ),
                  ),
                ),
                // Badge bleu - positionné en bas à droite HORS du cercle
                if (shop.hasBlueBadge)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.verified, color: Colors.white, size: 14),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDefaultShopIcon() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF2E7D32),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.store,
        color: Colors.white,
        size: 40,
      ),
    );
  }

  void _showShopDetails(Shop shop) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ShopProductsModal(shop: shop),
    );
  }

  // ============ STORIES ============

  Future<void> _loadStories() async {
    if (_isStoriesLoading) return;
    if (_currentPosition == null) return;

    if (mounted) {
      setState(() {
        _isStoriesLoading = true;
      });
    }

    try {
      final stories = await MapStoryService.getNearbyStories(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        radiusKm: 50, // 50km de rayon
      );
      if (mounted) {
        setState(() {
          _stories = stories;
          _isStoriesLoading = false;
        });
        _refreshMarkers();
      }
    } catch (e) {
      print('Erreur chargement stories: $e');
      if (mounted) {
        setState(() {
          _isStoriesLoading = false;
        });
      }
    }
  }

  void _toggleStoriesOnMap() {
    if (mounted) {
      setState(() {
        _showStoriesOnMap = !_showStoriesOnMap;
        // Si on active les stories, désactiver les événements et boutiques (stories exclusives)
        if (_showStoriesOnMap) {
          _showEventsOnMap = false;
          _showShopsOnMap = false;
        }
        if (_showStoriesOnMap && _stories.isEmpty) {
          _loadStories();
        } else {
          _refreshMarkers();
        }
      });
    }
  }

  /// Floute les coordonnées pour la vie privée (rayon de 500m-1km)
  /// Utilisé pour les stories afin de ne pas révéler la position exacte
  /// Utilise un seed basé sur l'ID pour que le floutage soit stable
  LatLng _blurLocation(double latitude, double longitude, String seed) {
    // Rayon de floutage entre 500m et 1km pour une protection efficace et visible
    // 1 degré de latitude ≈ 111 km
    // Pour la longitude, ça dépend de la latitude: 1 degré ≈ 111km * cos(latitude)
    
    // Générer un décalage pseudo-aléatoire mais stable basé sur le seed (ID de la story)
    final hash = seed.hashCode;
    
    // Distance entre 500m et 1000m (pour que le floutage soit bien visible sur la carte)
    final distanceMeters = 500.0 + ((hash.abs() % 10000) / 10000.0) * 500.0; // 500-1000m
    
    // Angle aléatoire basé sur le hash
    final angle = ((hash.abs() ~/ 7) % 360) * math.pi / 180;
    
    // Calculer les décalages en degrés
    final double latOffset = distanceMeters / 111000;
    final double lngOffset = distanceMeters / (111000 * (latitude.abs() > 80 ? 0.17 : math.cos(latitude * math.pi / 180)));
    
    final double deltaLat = latOffset * math.sin(angle);
    final double deltaLng = lngOffset * math.cos(angle);
    
    print('Story blur: seed=$seed');
    print('  Original: ($latitude, $longitude)');
    print('  Blurred:  (${latitude + deltaLat}, ${longitude + deltaLng})');
    print('  Distance: ${distanceMeters.toStringAsFixed(1)}m');
    
    return LatLng(latitude + deltaLat, longitude + deltaLng);
  }

  void _addStoryMarkers() {
    print('=== Adding story markers with blur ===');
    print('Number of stories: ${_stories.length}');
    _storyBlurCircles.clear();
    
    for (final story in _stories) {
      print('Story: ${story.userName}, hasBlueBadge: ${story.hasBlueBadge}');
      // Appliquer le floutage pour la vie privée
      // Utiliser l'ID de la story comme seed pour un floutage stable
      final seed = story.idStory.isNotEmpty ? story.idStory : '${story.latitude}_${story.longitude}';
      final blurredLocation = _blurLocation(
        story.latitude, 
        story.longitude, 
        seed,
      );
      
      // Ajouter le marqueur à la position floutée
      _markers.add(
        Marker(
          point: blurredLocation,
          child: GestureDetector(
            onTap: () => _showStoryViewer(story),
            child: _buildStoryMarker(story),
          ),
        ),
      );
      
      // Ajouter un cercle de floutage autour de la position floutée
      // Rayon de 700 mètres pour masquer vraiment la position
      final blurRadius = 700.0; // 700 mètres
      _storyBlurCircles.add(
        CircleMarker(
          point: blurredLocation,
          radius: blurRadius, // Rayon en mètres
          useRadiusInMeter: true,
          color: const Color(0xFF1B5E20), // Vert foncé totalement opaque
          borderStrokeWidth: 6.0,
          borderColor: const Color(0xFF0D3D0D), // Bordure vert très foncé
        ),
      );
    }
    print('Added ${_storyBlurCircles.length} blur circles');
    print('=== End adding story markers ===');
  }

  Widget _buildStoryMarker(MapStory story) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = 1.0 + _pulseController.value * 0.2;
        final glowOpacity = 0.4 + _pulseController.value * 0.4;
        return OverflowBox(
          maxWidth: 90,
          maxHeight: 90,
          minWidth: 60,
          minHeight: 60,
          alignment: Alignment.center,
          child: Transform.scale(
            scale: scale,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Photo de profil avec glow
                Container(
                  width: 60,
                  height: 60,
                  padding: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF1B5E20),
                        const Color(0xFF2E7D32),
                        const Color(0xFF1B5E20),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF006400).withOpacity(glowOpacity),
                        blurRadius: 6 + _pulseController.value * 6,
                        spreadRadius: 1 + _pulseController.value * 2,
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 29,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 28,
                      backgroundImage: story.userProfilePhoto != null && story.userProfilePhoto!.isNotEmpty
                          ? CachedNetworkImageProvider(story.userProfilePhoto!)
                          : null,
                      child: story.userProfilePhoto == null || story.userProfilePhoto!.isEmpty
                          ? Icon(Icons.person, size: 24, color: Colors.grey[400])
                          : null,
                    ),
                  ),
                ),
                // Badge bleu - positionné en bas à droite HORS du cercle
                if (story.hasBlueBadge)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.verified, color: Colors.white, size: 14),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDefaultStoryIcon() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF006400), Color(0xFF228B22)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.camera_alt,
        color: Colors.white,
        size: 24,
      ),
    );
  }

  void _showStoryViewer(MapStory story) {
    // Grouper les stories par utilisateur pour l'affichage
    final userStories = <String, List<MapStory>>{};
    for (final s in _stories) {
      if (!userStories.containsKey(s.idUtilisateur)) {
        userStories[s.idUtilisateur] = [];
      }
      userStories[s.idUtilisateur]!.add(s);
    }

    // Trouver l'index initial
    int initialIndex = 0;
    for (final userId in userStories.keys) {
      if (userId == story.idUtilisateur) {
        initialIndex = userStories.values
            .takeWhile((list) => list.first.idUtilisateur != story.idUtilisateur)
            .fold(0, (sum, list) => sum + list.length);
        break;
      }
    }

    final allUserStories = userStories[story.idUtilisateur]!;

    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: true,
        pageBuilder: (context, animation, secondaryAnimation) =>
            StoryViewerScreen(
          stories: allUserStories,
          initialIndex: 0,
          currentUserId: _currentUserId ?? '',
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _openCreateStoryModal() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => CreateStoryModal(
        currentPosition: _currentPosition,
        onStoryCreated: () {
          // Recharger les stories après création
          if (_showStoriesOnMap) {
            _loadStories();
          }
        },
      ),
    );
  }

  void _removeShopMarkers() {
    _markers.removeWhere((marker) {
      //标识 les marqueurs de boutiques (ceux avec un GestureDetector qui appelle _showShopDetails)
      return true; // Simplifié: on retire tout et on re-construit
    });
    _refreshMarkers();
  }

  /// Retourne le bon ImageProvider pour une image d'événement
  ImageProvider _getEventImageProvider(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return const AssetImage('assets/images/placeholder.png');
    }

    // 1. URL absolue (http/https)
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return CachedNetworkImageProvider(imageUrl);
    }

    // 2. Chemin du backend (commence par /) - treated as backend URL
    if (imageUrl.startsWith('/')) {
      final fullUrl = '${ApiConstants.baseUrl}$imageUrl';
      return CachedNetworkImageProvider(fullUrl);
    }

    // 3. Chemin de fichier local (pas de / au début)
    return FileImage(File(imageUrl));
  }

  /// Retourne l'URL absolue pour une photo de profil
  String _getProfilePhotoUrl(String? photoUrl) {
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

  void _addEventMarkers() {
    // Ne pas effacer les marqueurs ici - _refreshMarkers() le fait déjà
    // Debug
    print('[MAP] _addEventMarkers appelé, _events.length = ${_events.length}');

    // Add user's current location marker if available
    if (_currentPosition != null) {
      final userPosition = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
      _markers.add(
        Marker(
          point: userPosition,
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                ),
                const Icon(
                  Icons.location_pin,
                  color: Colors.red,
                  size: 40,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Filtrer les événements expirés (utilise la tolérance de 2h)
    final now = DateTime.now();
    final validEvents = _events.where((event) {
      final isValid = !event.isExpired;
      print('[MAP] Événement: ${event.title}, isExpired: ${event.isExpired}, isValid: $isValid');
      return isValid;
    }).toList();

    print('[MAP] Événements valides: ${validEvents.length} / ${_events.length}');

    for (final event in validEvents) {
      print('[MAP] Ajout marqueur pour: ${event.title} à ${event.latitude}, ${event.longitude}');
      _markers.add(
        Marker(
          point: LatLng(event.latitude, event.longitude),
          child: GestureDetector(
            onTap: () => _showEventDetails(event),
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final scale = 1.0 + _pulseController.value * 0.1;
                final glowOpacity = 0.4 + _pulseController.value * 0.4;
                return OverflowBox(
                  maxWidth: 90,
                  maxHeight: 90,
                  minWidth: 60,
                  minHeight: 60,
                  alignment: Alignment.center,
                  child: Transform.scale(
                    scale: scale,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        // Photo du créateur avec glow
                        Container(
                          width: 60,
                          height: 60,
                          padding: const EdgeInsets.all(1),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.orange.withOpacity(0.8),
                                Colors.orange.withOpacity(0.6),
                                Colors.orange.withOpacity(0.4),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withOpacity(glowOpacity),
                                blurRadius: 6 + _pulseController.value * 6,
                                spreadRadius: 1 + _pulseController.value * 2,
                              ),
                              BoxShadow(
                                color: Colors.black.withOpacity(0.4),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 29,
                            backgroundColor: Colors.white,
                            child: CircleAvatar(
                              radius: 28,
                              backgroundImage: event.userProfilePhoto != null && event.userProfilePhoto!.isNotEmpty
                                  ? CachedNetworkImageProvider(_getProfilePhotoUrl(event.userProfilePhoto))
                                  : null,
                              child: event.userProfilePhoto == null || event.userProfilePhoto!.isEmpty
                                  ? Icon(Icons.person, size: 24, color: Colors.grey[400])
                                  : null,
                            ),
                          ),
                        ),
                        // Badge bleu - positionné en bas à droite HORS du cercle
                        if (event.hasBlueBadge)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 3,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.verified, color: Colors.white, size: 14),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
    }
  }

  void _removeEventMarkers() {
    _markers.clear();
    if (_currentPosition != null) {
      final userPosition = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
      _markers.add(
        Marker(
          point: userPosition,
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                ),
                const Icon(
                  Icons.location_pin,
                  color: Colors.red,
                  size: 40,
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.split(' ').where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.elementAt(1)[0]}'.toUpperCase();
  }

  void _showEventDetails(EventLocation event) {
    final dateFormat = DateFormat('dd/MM/yyyy à HH:mm');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo de l'événement - GRAND FORMAT
              if (event.imageUrl != null && event.imageUrl!.isNotEmpty)
                Container(
                  width: double.infinity,
                  height: 250,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    image: DecorationImage(
                      image: _getEventImageProvider(event.imageUrl), 
                      fit: BoxFit.cover
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Badge expiré
                      if (event.isExpired)
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Expiré',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ),
                    ],
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: const Color(0xFF2E7D32),
                  ),
                  child: const Icon(Icons.event, color: Colors.white, size: 80),
                ),
              const SizedBox(height: 16),
              
              // Titre de l'événement
              Text(
                event.title,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              
              // Photo de profil utilisateur cliquable
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (event.userId.isEmpty) {
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
                          builder: (_) => UserProfileScreen(
                            userId: event.userId,
                            userName: event.userName,
                          ),
                        ),
                      );
                    },
                    child: Stack(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey[300]!, width: 3),
                            image: event.userProfilePhoto != null && event.userProfilePhoto!.isNotEmpty
                                ? DecorationImage(image: _getEventImageProvider(event.userProfilePhoto), fit: BoxFit.cover)
                                : null,
                            color: event.userProfilePhoto == null || event.userProfilePhoto!.isEmpty
                                ? const Color(0xFF2E7D32)
                                : null,
                          ),
                          child: event.userProfilePhoto == null || event.userProfilePhoto!.isEmpty
                              ? Center(
                                  child: Text(
                                    _getInitials(event.userName),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        // Badge bleu
                        if (event.hasBlueBadge)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.verified, color: Colors.white, size: 14),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nom utilisateur cliquable
                        GestureDetector(
                          onTap: () {
                            if (event.userId.isEmpty) {
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
                                builder: (_) => UserProfileScreen(
                                  userId: event.userId,
                                  userName: event.userName,
                                ),
                              ),
                            );
                          },
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  event.userName.isNotEmpty ? event.userName : 'Utilisateur',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.blue[700],
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (event.hasBlueBadge)
                                Icon(Icons.verified, color: Colors.blue[700], size: 18),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Organisateur',
                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Date et heure
              if (event.eventDateTime != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 20, color: Color(0xFF2E7D32)),
                      const SizedBox(width: 10),
                      Text(
                        'Le ${dateFormat.format(event.eventDateTime!)}',
                        style: const TextStyle(
                          fontSize: 15, 
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),
                ),
              if (event.eventDateTime != null) const SizedBox(height: 16),
              
              // Description
              if (event.description.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Description',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      event.description,
                      style: const TextStyle(fontSize: 15),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              
              // Adresse
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on, size: 20, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        event.address,
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: Text(context.tr('close'), style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _mapController.move(LatLng(event.latitude, event.longitude), 16.0);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: Text(context.tr('view_on_map'), style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _zoomIn() {
    if (_currentZoom < _maxZoom) {
      setState(() {
        _currentZoom += 1;
      });
      _mapController.move(_mapController.camera.center, _currentZoom);
    }
  }

  void _zoomOut() {
    if (_currentZoom > _minZoom) {
      setState(() {
        _currentZoom -= 1;
      });
      _mapController.move(_mapController.camera.center, _currentZoom);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Carte OpenStreetMap
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _initialPosition,
                initialZoom: _currentZoom,
                minZoom: _minZoom,
                maxZoom: _maxZoom,
                onTap: (tapPosition, point) {
                  setState(() {
                    _showSuggestions = false;
                  });
                },
                onMapReady: () {
                  if (_currentPosition != null) {
                    _centerOnUserLocation();
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.goodly.app',
                ),
                // Couche de cercles de floutage pour les stories (protection vie privée)
                if (_showStoriesOnMap && _storyBlurCircles.isNotEmpty)
                  CircleLayer(
                    circles: _storyBlurCircles,
                  ),
                MarkerLayer(
                  markers: _markers,
                ),
              ],
            ),
          ),

          // Contrôles de zoom
          Positioned(
            top: 110,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(
                  heroTag: null,
                  onPressed: _zoomIn,
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.add, color: Colors.blue),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    'Zoom: ${_currentZoom.toStringAsFixed(1)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: null,
                  onPressed: _zoomOut,
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.remove, color: Colors.blue),
                ),
              ],
            ),
          ),

          // Bouton VERT "Événements" uniquement
          Positioned(
            top: 50,
            left: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: _showEventsOnMap ? Colors.green[700] : const Color(0xFF2E7D32),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isEventsLoading ? null : _toggleEventsOnMap,
                      borderRadius: BorderRadius.circular(32),
                      child: _isEventsLoading
                          ? const SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: Colors.white,
                              ),
                            )
                          : Stack(
                              alignment: Alignment.center,
                              children: [
                                const Icon(Icons.event, color: Colors.white, size: 32),
                                if (_showEventsOnMap)
                                  Positioned(
                                    top: 6,
                                    right: 6,
                                    child: Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _showEventsOnMap ? Colors.green[700] : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    _showEventsOnMap ? 'Cacher' : 'Événements',
                    style: TextStyle(
                      color: _showEventsOnMap ? Colors.white : Colors.grey[800],
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bouton VERT "Boutiques"
          Positioned(
            top: 120,
            left: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: _showShopsOnMap ? Colors.orange[700] : const Color(0xFFFF9800),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isShopsLoading ? null : _toggleShopsOnMap,
                      borderRadius: BorderRadius.circular(32),
                      child: _isShopsLoading
                          ? const SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: Colors.white,
                              ),
                            )
                          : Stack(
                              alignment: Alignment.center,
                              children: [
                                const Icon(Icons.store, color: Colors.white, size: 32),
                                if (_showShopsOnMap)
                                  Positioned(
                                    top: 6,
                                    right: 6,
                                    child: Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _showShopsOnMap ? Colors.orange[700] : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    _showShopsOnMap ? 'Cacher' : 'Boutiques',
                    style: TextStyle(
                      color: _showShopsOnMap ? Colors.white : Colors.grey[800],
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bouton VERT "Stories" (afficher/masquer les stories sur la carte)
          Positioned(
            top: 190,
            left: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: _showStoriesOnMap ? const Color(0xFF006400) : Colors.grey[400],
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isStoriesLoading ? null : _toggleStoriesOnMap,
                      borderRadius: BorderRadius.circular(32),
                      child: _isStoriesLoading
                          ? const SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: Colors.white,
                              ),
                            )
                          : Stack(
                              alignment: Alignment.center,
                              children: [
                                const Icon(Icons.camera_alt, color: Colors.white, size: 28),
                                if (_showStoriesOnMap)
                                  Positioned(
                                    top: 6,
                                    right: 6,
                                    child: Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _showStoriesOnMap ? const Color(0xFF006400) : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    _showStoriesOnMap ? 'Cacher' : 'Stories',
                    style: TextStyle(
                      color: _showStoriesOnMap ? Colors.white : Colors.grey[800],
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bouton FLOTTANT "Créer une Story"
          Positioned(
            bottom: 100,
            right: 16,
            child: FloatingActionButton.extended(
              heroTag: null,
              onPressed: _openCreateStoryModal,
              backgroundColor: const Color(0xFF006400),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_a_photo),
              label: Text(context.tr('story')),
              extendedPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),

          // Barre de recherche en haut
          Positioned(
            top: 50,
            left: 96,
            right: 16,
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
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Rechercher un lieu...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isSearching)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: _clearSearch,
                        ),
                      const SizedBox(width: 8),
                    ],
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (value) {
                  _searchPlaces(value);
                },
                onSubmitted: (value) {
                  if (_searchSuggestions.isNotEmpty) {
                    _selectPlace(_searchSuggestions.first);
                  }
                },
              ),
            ),
          ),

          // Bouton de localisation
          Positioned(
            top: 180,
            right: 16,
            child: FloatingActionButton.small(
              heroTag: null,
              onPressed: _isUserLocationLoading ? null : _getCurrentLocation,
              backgroundColor: Colors.white,
              child: _isUserLocationLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const Icon(
                          Icons.location_pin,
                          color: Colors.red,
                          size: 28,
                        ),
                      ],
                    ),
            ),
          ),

          // Message d'erreur avec bouton réessayer
          if (_hasError)
            Positioned(
              top: 130,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage.isNotEmpty 
                          ? _errorMessage 
                          : 'Impossible de charger les événements',
                        style: TextStyle(color: Colors.red[700], fontSize: 13),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _dataLoaded = false;
                        });
                        _loadEvents();
                      },
                      child: Text(context.tr('retry')),
                    ),
                  ],
                ),
              ),
            ),

          // Liste des suggestions de recherche
          if (_showSuggestions && _searchSuggestions.isNotEmpty)
            Positioned(
              top: 110,
              left: 16,
              right: 16,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 300),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _searchSuggestions.length,
                    itemBuilder: (context, index) {
                      final place = _searchSuggestions[index];
                      return ListTile(
                        leading: const Icon(Icons.location_on, color: Colors.grey),
                        title: Text(
                          place['name'] ?? place['display_name']?.split(',').first ?? 'Lieu',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          place['display_name'] ?? '',
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () {
                          _selectPlace(place);
                        },
                      );
                    },
                  ),
                ),
              ),
            ),

          // Adresse actuelle en bas
          if (_currentAddress != null)
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
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
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _currentAddress!,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
