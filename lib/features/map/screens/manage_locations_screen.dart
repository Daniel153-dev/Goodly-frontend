import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:path_provider/path_provider.dart';
import '../models/event_location.dart';
import '../services/location_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../../core/api/api_constants.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../profile/screens/user_profile_screen.dart';

/// Retourne le bon ImageProvider pour une image (locale ou URL du backend)
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

class ManageLocationsScreen extends StatefulWidget {
  const ManageLocationsScreen({super.key});

  @override
  State<ManageLocationsScreen> createState() => _ManageLocationsScreenState();
}

class _ManageLocationsScreenState extends State<ManageLocationsScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  
  List<EventLocation> _events = [];
  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasError = false;
  String _errorMessage = '';
  final MapController _mapController = MapController();
  
  LatLng? _selectedPosition;
  String? _selectedAddress;
  List<dynamic> _searchResults = [];
  bool _isSearching = false;
  bool _isAddMode = false;
  DateTime? _eventDateTime;
  
  String? _currentUserId;
  bool _dataLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (_dataLoaded) return;

    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = '';
      });
    }

    try {
      final userInfo = await _getCurrentUserInfo();
      _currentUserId = userInfo['id'];
      
      // Charger tous les événements depuis le backend
      final allEvents = await LocationStorageService.getEventsLocations();
      _events = allEvents;

      if (_selectedPosition == null) {
        _selectedPosition = const LatLng(48.8566, 2.3522);
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _dataLoaded = true;
        });
      }
    } catch (e) {
      print('Erreur chargement données: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
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
        content: Text(context.tr('geolocation_required_location')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  XFile? _selectedXFile;
  File? _selectedImageFile;

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _selectedXFile = image;
          _selectedImageFile = null;
        });
      }
    } catch (e) {
      print('Erreur sélection image: $e');
    }
  }

  Widget _buildSelectedImagePreview() {
    if (_selectedXFile != null) {
      try {
        if (kIsWeb) {
          return FutureBuilder<List<int>>(
            future: _selectedXFile!.readAsBytes(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Container(
                  width: double.infinity,
                  height: 150,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: MemoryImage(Uint8List.fromList(snapshot.data!)),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => setState(() {
                        _selectedXFile = null;
                        _selectedImageFile = null;
                      }),
                    ),
                  ),
                );
              } else if (snapshot.hasError) {
                return _buildPlaceholderImage();
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          );
        } else {
          final file = File(_selectedXFile!.path);
          return Container(
            width: double.infinity,
            height: 150,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: FileImage(file),
                fit: BoxFit.cover,
              ),
            ),
            child: Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => setState(() {
                  _selectedXFile = null;
                  _selectedImageFile = null;
                }),
              ),
            ),
          );
        }
      } catch (e) {
        print('Erreur lecture image: $e');
        return _buildPlaceholderImage();
      }
    }
    return _buildImagePickerButton();
  }

  Widget _buildImagePickerButton() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: double.infinity,
        height: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[400]!),
          color: Colors.grey[100],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey[500]),
            const SizedBox(height: 8),
            Text(
              context.tr('add_photo'),
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: double.infinity,
      height: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[200],
      ),
      child: const Center(
        child: Icon(Icons.broken_image, color: Colors.grey, size: 48),
      ),
    );
  }

  Future<String?> _uploadEventImage(XFile image) async {
    try {
      // Sur web, on ne peut pas utiliser getApplicationDocumentsDirectory
      // Donc on upload directement vers le backend
      final bytes = await image.readAsBytes();
      final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.uploadEventImage}');
      final request = http.MultipartRequest('POST', uri);
      
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.headers['Accept'] = 'application/json';
      
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: 'event_${DateTime.now().millisecondsSinceEpoch}.webp',
        ),
      );

      final response = await request.send();
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseBody = await response.stream.bytesToString();
        final jsonResponse = json.decode(responseBody);
        final imageUrl = jsonResponse['url'] ?? jsonResponse['image_url'] ?? jsonResponse['file_path'];
        print('[IMAGE] Image uploadée avec succès: $imageUrl');
        return imageUrl;
      }
      
      throw Exception('Erreur upload: ${response.statusCode}');
    } catch (e) {
      print('[IMAGE] Erreur upload image: $e');
      // En cas d'erreur, retourner null
      return null;
    }
  }

  Future<void> _selectDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _eventDateTime ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_eventDateTime ?? DateTime.now()),
      );

      if (pickedTime != null) {
        setState(() {
          _eventDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _saveEvent() async {
    if (_titleController.text.isEmpty || _selectedPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('title_position_required')), backgroundColor: Colors.red),
      );
      return;
    }

    if (mounted) {
      setState(() {
        _isSaving = true;
      });
    }

    try {
      final userInfo = await _getCurrentUserInfo();
      
      String? imageUrl;
      if (_selectedXFile != null) {
        print('Uploading event image...');
        imageUrl = await _uploadEventImage(_selectedXFile!);
        print('Image upload complete. URL: $imageUrl');
      }
      
      final event = EventLocation(
        userId: userInfo['id']!,
        userName: userInfo['name']!,
        userProfilePhoto: userInfo['profilePhoto']!,
        hasBlueBadge: userInfo['hasBlueBadge'] ?? false,
        title: _titleController.text,
        description: _descriptionController.text,
        imageUrl: imageUrl,
        latitude: _selectedPosition!.latitude,
        longitude: _selectedPosition!.longitude,
        address: _selectedAddress ?? '',
        createdAt: DateTime.now(),
        eventDateTime: _eventDateTime,
      );

      print('Sending event to backend...');
      // Sauvegarder dans le backend
      await LocationStorageService.addEventLocation(event);
      print('Event successfully sent to backend.');

      // Recharger les événements depuis le backend
      final allEvents = await LocationStorageService.getEventsLocations();
      _events = allEvents;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('event_saved_success')), backgroundColor: Colors.green),
        );
        
        setState(() {
          _titleController.clear();
          _descriptionController.clear();
          _selectedXFile = null;
          _selectedImageFile = null;
          _eventDateTime = null;
          _isAddMode = false;
        });
      }
    } catch (e) {
      print('Erreur lors de l\'enregistrement de l\'événement: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.tr('event_save_error')} $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _cancelAdd() {
    setState(() {
      _isAddMode = false;
      _titleController.clear();
      _descriptionController.clear();
      _selectedXFile = null;
      _selectedImageFile = null;
      _eventDateTime = null;
    });
  }

  Future<void> _deleteEvent(String eventId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('confirm')),
        content: Text(context.tr('delete_event_confirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.tr('cancel'))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(context.tr('delete'), style: const TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await LocationStorageService.deleteEventLocation(eventId);
        // Recharger les événements
        final allEvents = await LocationStorageService.getEventsLocations();
        setState(() {
          _events = allEvents;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.split(' ').where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.elementAt(1)[0]}'.toUpperCase();
  }

  void _showMyPublishedEventsSheet() {
    final dateFormat = DateFormat('dd/MM/yyyy à HH:mm');
    
    // Filtrer les événements de l'utilisateur courant
    final myEvents = _events.where((e) => e.userId == _currentUserId).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          color: Colors.white,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(color: Color(0xFF2E7D32)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        context.trParams('my_published_events_count', {'count': myEvents.length.toString()}),
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: myEvents.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              context.tr('no_events_published'),
                              style: const TextStyle(fontSize: 16, color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              context.tr('add_event_to_see'),
                              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: myEvents.length,
                        itemBuilder: (context, index) {
                          final event = myEvents[index];
                          return _buildEventCard(event, dateFormat);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEventCard(EventLocation event, DateFormat dateFormat) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo de l'événement - GRAND FORMAT
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              image: event.imageUrl != null && event.imageUrl!.isNotEmpty
                  ? DecorationImage(image: _getEventImageProvider(event.imageUrl), fit: BoxFit.cover)
                  : null,
              color: event.imageUrl == null || event.imageUrl!.isEmpty
                  ? const Color(0xFF2E7D32)
                  : null,
            ),
            child: event.imageUrl == null || event.imageUrl!.isEmpty
                ? const Icon(Icons.event, color: Colors.white, size: 80)
                : null,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titre
                Text(
                  event.title,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                
                // Photo de profil et nom utilisateur
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
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
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey[300]!),
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
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  )
                                : null,
                          ),
                          if (event.hasBlueBadge)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(Icons.verified, color: Colors.white, size: 12),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    event.userName.isNotEmpty ? event.userName : context.tr('user'),
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.blue[700],
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (event.hasBlueBadge)
                                  Icon(Icons.verified, color: Colors.blue[700], size: 16),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              context.tr('organizer'),
                              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
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
                            context.trParams('on_date', {'date': dateFormat.format(event.eventDateTime!)}),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ],
                      ),
                  ),
                if (event.eventDateTime != null) const SizedBox(height: 12),
                
                // Description
                if (event.description.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('description'),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        event.description,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                
                // Adresse
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on, size: 18, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          event.address,
                          style: const TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                
                // Boutons d'action
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _mapController.move(LatLng(event.latitude, event.longitude), 16.0);
                        },
                        icon: const Icon(Icons.map, size: 18),
                        label: Text(context.tr('view_on_map')),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF2E7D32),
                          side: const BorderSide(color: Color(0xFF2E7D32)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: () => _deleteEvent(event.id!),
                      icon: const Icon(Icons.delete, color: Colors.red),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(context.tr('my_locations')),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          // Bouton pour voir mes événements publiés
          IconButton(
            icon: const Icon(Icons.list_alt),
            onPressed: () {
              // Rafraîchir les données avant d'afficher
              setState(() {
                _dataLoaded = false;
              });
              _loadData().then((_) {
                _showMyPublishedEventsSheet();
              });
            },
            tooltip: context.tr('my_published_events'),
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildMap(),
          Positioned(top: 16, left: 16, right: 16, child: _buildSearchBar()),
          if (_selectedPosition != null && !_isAddMode)
            Positioned(top: 80, left: 16, right: 16, child: _buildPositionIndicator()),
          
          // Message d'erreur
          if (_hasError)
            Positioned(
              top: 80,
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
                          : context.tr('connection_error'),
                        style: TextStyle(color: Colors.red[700], fontSize: 13),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _dataLoaded = false;
                        });
                        _loadData();
                      },
                      child: Text(context.tr('retry')),
                    ),
                  ],
                ),
              ),
            ),
          
          Positioned(
            bottom: 200,
            right: 16,
            child: FloatingActionButton.small(
              heroTag: null,
              onPressed: _centerOnUserLocation,
              backgroundColor: Colors.white,
              child: const Icon(Icons.my_location, color: Colors.blue),
            ),
          ),
          if (!_isAddMode)
            Positioned(
              bottom: 130,
              left: 16,
              right: 16,
              child: ElevatedButton.icon(
                onPressed: () => setState(() => _isAddMode = true),
                icon: const Icon(Icons.add_location_alt),
                label: Text(context.tr('add_event')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          if (_searchResults.isNotEmpty)
            Positioned(top: 80, left: 16, right: 16, child: _buildSearchResults()),
          if (_isAddMode)
            Positioned(bottom: 0, left: 0, right: 0, child: _buildAddEventForm()),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _selectedPosition ?? const LatLng(48.8566, 2.3522),
        initialZoom: 13.0,
        onTap: (tapPosition, point) {
          if (!_isAddMode) {
            setState(() {
              _selectedPosition = point;
              _selectedAddress = '${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}';
            });
          }
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.goodly.app',
        ),
        MarkerLayer(
          markers: [
            // Marqueur de position sélectionnée (UNIQUEMENT pour ajouter un événement)
            if (_selectedPosition != null && _isAddMode)
              Marker(
                point: _selectedPosition!,
                child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
              ),
            // NOTE: Les événements ne sont PLUS affichés sur cette carte
            // Ils sont seulement visibles dans "Mes événements publiés"
          ],
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Rechercher un lieu...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _isSearching
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchResults = []);
                  },
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: (value) => _searchPlace(value),
      ),
    );
  }

  Widget _buildSearchResults() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 300),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: _searchResults.length,
          itemBuilder: (context, index) {
            final result = _searchResults[index];
            return ListTile(
              leading: const Icon(Icons.location_on, color: Colors.red),
              title: Text(
                result['name'] ?? result['display_name']?.split(',').take(3).join(',') ?? 'Lieu',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                result['display_name'] ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              onTap: () => _selectSearchResult(result),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPositionIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _selectedAddress ?? context.tr('selected_position'),
              style: const TextStyle(fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => setState(() => _isAddMode = true),
            icon: const Icon(Icons.add),
            label: Text(context.tr('add')),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddEventForm() {
    final dateFormat = DateFormat('dd/MM/yyyy à HH:mm');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.tr('new_event'),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: _cancelAdd),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedAddress ?? '',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: context.tr('event_title_required'),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.title),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: context.tr('description'),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.description),
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _selectDateTime,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[400]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Color(0xFF2E7D32)),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.tr('event_date_time'),
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              Text(
                                _eventDateTime != null
                                    ? dateFormat.format(_eventDateTime!)
                                    : context.tr('select_date_time'),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _eventDateTime != null ? Colors.black : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                ),
              ),
              const SizedBox(height: 12),
              _buildSelectedImagePreview(),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveEvent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(context.tr('save'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
