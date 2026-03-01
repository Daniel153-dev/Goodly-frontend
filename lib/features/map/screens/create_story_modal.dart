import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import '../services/map_story_service.dart';
import '../services/location_storage_service.dart';
import '../../../core/api/api_constants.dart';
import '../../../core/l10n/app_localizations.dart';

/// Modal pour créer une nouvelle story géolocalisée
/// La localisation est automatiquement récupérée et ne peut pas être modifiée manuellement
class CreateStoryModal extends StatefulWidget {
  final Position? currentPosition;
  final VoidCallback onStoryCreated;

  const CreateStoryModal({
    super.key,
    this.currentPosition,
    required this.onStoryCreated,
  });

  @override
  State<CreateStoryModal> createState() => _CreateStoryModalState();
}

class _CreateStoryModalState extends State<CreateStoryModal> {
  final ImagePicker _imagePicker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  // Localisation (automatique uniquement)
  LatLng _selectedPosition = const LatLng(48.8566, 2.3522);
  String? _currentAddress;
  Position? _currentPosition;
  bool _isLocating = true;

  // Médias
  XFile? _media1;
  XFile? _media2;
  String _media1Type = 'photo';
  String _media2Type = 'photo';
  VideoPlayerController? _videoController1;
  VideoPlayerController? _videoController2;
  
  // Légendes pour chaque média
  final TextEditingController _captionController1 = TextEditingController();
  final TextEditingController _captionController2 = TextEditingController();

  // État
  bool _isUploading = false;
  String _errorMessage = '';

  // Contrôleur de carte
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _currentPosition = widget.currentPosition;
    if (_currentPosition != null) {
      _selectedPosition = LatLng(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
      _loadAddress(_selectedPosition);
    }
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _videoController1?.dispose();
    _videoController2?.dispose();
    _captionController1.dispose();
    _captionController2.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLocating = true);

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _useDefaultLocation();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _useDefaultLocation();
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _currentPosition = position;
          _selectedPosition = LatLng(position.latitude, position.longitude);
          _isLocating = false;
        });
        _mapController.move(_selectedPosition, 15);
        _loadAddress(_selectedPosition);
      }
    } catch (e) {
      print('Erreur de localisation: $e');
      _useDefaultLocation();
    }
  }

  void _useDefaultLocation() {
    setState(() => _isLocating = false);
  }

  Future<void> _loadAddress(LatLng position) async {
    try {
      final address = await LocationStorageService.getAddressFromLatLng(
        position.latitude,
        position.longitude,
      );
      if (mounted) {
        setState(() {
          _currentAddress = address;
        });
      }
    } catch (e) {
      print('Erreur d\'adresse: $e');
    }
  }

  Future<void> _pickMedia(int mediaNumber) async {
    if (mediaNumber == 1 && _media1 != null) {
      _showMediaOptions(1);
      return;
    }
    if (mediaNumber == 2 && _media2 != null) {
      _showMediaOptions(2);
      return;
    }

    _showMediaOptions(mediaNumber);
  }

  void _showMediaOptions(int mediaNumber) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.tr('choose_media'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildMediaOption(
                  icon: Icons.photo_library,
                  label: context.tr('gallery'),
                  onTap: () => _pickMediaFromSource(mediaNumber, ImageSource.gallery),
                ),
                _buildMediaOption(
                  icon: Icons.camera_alt,
                  label: context.tr('photo'),
                  onTap: () => _pickMediaFromSource(mediaNumber, ImageSource.camera, isVideo: false),
                ),
                _buildMediaOption(
                  icon: Icons.videocam,
                  label: context.tr('video_10s'),
                  onTap: () => _pickMediaFromSource(mediaNumber, ImageSource.camera, isVideo: true),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.blue.withOpacity(0.1),
            child: Icon(icon, size: 30, color: Colors.blue),
          ),
          const SizedBox(height: 8),
          Text(label),
        ],
      ),
    );
  }

  Future<void> _pickMediaFromSource(
    int mediaNumber,
    ImageSource source, {
    bool isVideo = false,
  }) async {
    Navigator.pop(context);

    try {
      if (isVideo) {
        final XFile? video = await _imagePicker.pickVideo(
          source: source,
          maxDuration: const Duration(seconds: 10),
        );
        if (video != null) {
          _setMedia(mediaNumber, video, 'video');
        }
      } else {
        final XFile? image = await _imagePicker.pickImage(
          source: source,
          maxWidth: 1920,
          maxHeight: 1080,
          imageQuality: 85,
        );
        if (image != null) {
          _setMedia(mediaNumber, image, 'photo');
        }
      }
    } catch (e) {
      print('Erreur de sélection média: $e');
    }
  }

  void _setMedia(int mediaNumber, XFile file, String type) async {
    if (mediaNumber == 1) {
      _videoController1?.dispose();
      _videoController1 = null;
      setState(() {
        _media1 = file;
        _media1Type = type;
      });
      if (type == 'video' && !kIsWeb) {
        // Video preview only works on native platforms, not on web
        _videoController1 = VideoPlayerController.file(File(file.path))
          ..initialize().then((_) {
            // Vérifier la durée de la vidéo
            final duration = _videoController1!.value.duration.inSeconds;
            if (duration > 10) {
              // Rejeter la vidéo si elle dépasse 10 secondes
              _videoController1?.dispose();
              _videoController1 = null;
              setState(() {
                _media1 = null;
                _media1Type = 'photo';
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(context.tr('video_max_10_seconds')),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }
            setState(() {});
          });
      }
    } else {
      _videoController2?.dispose();
      _videoController2 = null;
      setState(() {
        _media2 = file;
        _media2Type = type;
      });
      if (type == 'video' && !kIsWeb) {
        // Video preview only works on native platforms, not on web
        _videoController2 = VideoPlayerController.file(File(file.path))
          ..initialize().then((_) {
            // Vérifier la durée de la vidéo
            final duration = _videoController2!.value.duration.inSeconds;
            if (duration > 10) {
              // Rejeter la vidéo si elle dépasse 10 secondes
              _videoController2?.dispose();
              _videoController2 = null;
              setState(() {
                _media2 = null;
                _media2Type = 'photo';
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(context.tr('video_max_10_seconds')),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }
            setState(() {});
          });
      }
    }
  }

  void _removeMedia(int mediaNumber) {
    if (mediaNumber == 1) {
      _videoController1?.dispose();
      _videoController1 = null;
      setState(() {
        _media1 = null;
        _media1Type = 'photo';
      });
    } else {
      _videoController2?.dispose();
      _videoController2 = null;
      setState(() {
        _media2 = null;
        _media2Type = 'photo';
      });
    }
  }

  Future<void> _uploadAndCreateStory() async {
    if (!_formKey.currentState!.validate()) return;
    if (_media1 == null) {
      setState(() => _errorMessage = context.tr('add_at_least_one_media'));
      return;
    }

    if (_currentPosition == null) {
      setState(() => _errorMessage = context.tr('location_unavailable'));
      return;
    }

    setState(() {
      _isUploading = true;
      _errorMessage = '';
    });

    try {
      // Uploader les médias
      final media1Url = await _uploadMedia(_media1!);
      String? media2Url;
      int? media2Duration;

      if (_media2 != null) {
        media2Url = await _uploadMedia(_media2!);
        if (_media2Type == 'video' && _videoController2 != null) {
          media2Duration = _videoController2!.value.duration.inSeconds;
        }
      }

      // Créer la story
      await MapStoryService.createStory(
        latitude: _selectedPosition.latitude,
        longitude: _selectedPosition.longitude,
        address: _currentAddress,
        media1Url: media1Url,
        media1Type: _media1Type,
        media1Duration: _media1Type == 'video' && _videoController1 != null
            ? _videoController1!.value.duration.inSeconds
            : null,
        media1Caption: _captionController1.text.isNotEmpty ? _captionController1.text : null,
        media2Url: media2Url,
        media2Type: _media2 != null ? _media2Type : null,
        media2Duration: media2Duration,
        media2Caption: _captionController2.text.isNotEmpty ? _captionController2.text : null,
      );

      if (mounted) {
        widget.onStoryCreated();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('story_created'))),
        );
      }
    } catch (e) {
      setState(() => _errorMessage = '${context.tr('error')}: ${e.toString()}');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<String> _uploadMedia(XFile media) async {
    try {
      final bytes = await media.readAsBytes();
      final filename = media.name;
      
      final uri = Uri.parse('${ApiConstants.baseUrl}/upload-story-media');
      final request = http.MultipartRequest('POST', uri);
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: filename,
        ),
      );
      
      print('[STORY_UPLOAD] Uploading: $filename to ${uri.toString()}');
      
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      
      print('[STORY_UPLOAD] Status: ${response.statusCode}');
      print('[STORY_UPLOAD] Response: $responseBody');
      
      if (response.statusCode == 200) {
        final json = jsonDecode(responseBody);
        final uploadedUrl = json['url'] as String;
        print('[STORY_UPLOAD] Fichier uploadé avec succès: $uploadedUrl');
        return uploadedUrl;
      } else {
        throw Exception('Upload failed: ${response.statusCode}');
      }
    } catch (e) {
      print('[STORY_UPLOAD ERROR] $e');
      rethrow;
    }
  }

  Widget _buildMediaPreview(int mediaNumber) {
    final media = mediaNumber == 1 ? _media1 : _media2;
    final mediaType = mediaNumber == 1 ? _media1Type : _media2Type;
    final videoController = mediaNumber == 1 ? _videoController1 : _videoController2;

    if (media == null) {
      return GestureDetector(
        onTap: () => _pickMedia(mediaNumber),
        child: Container(
          height: 150,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey, style: BorderStyle.solid),
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey.withOpacity(0.1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add_circle_outline, size: 40, color: Colors.grey),
              const SizedBox(height: 8),
              Text(context.tr('add_media')),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        Container(
          height: 150,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: mediaType == 'video' && videoController != null && videoController.value.isInitialized
              ? AspectRatio(
                  aspectRatio: videoController.value.aspectRatio,
                  child: VideoPlayer(videoController),
                )
              : kIsWeb
                  ? Image.network(
                      media.path,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stack) {
                        return Container(
                          color: Colors.grey[200],
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                mediaType == 'video' ? Icons.videocam : Icons.photo,
                                size: 40,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                media.name,
                                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        );
                      },
                    )
                  : FutureBuilder<List<int>>(
                      future: media.readAsBytes(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return Image.memory(
                            Uint8List.fromList(snapshot.data!),
                            fit: BoxFit.cover,
                            width: double.infinity,
                          );
                        } else if (snapshot.hasError) {
                          return const Icon(Icons.error);
                        }
                        return const Center(child: CircularProgressIndicator());
                      },
                    ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: () => _removeMedia(mediaNumber),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
        if (mediaType == 'video')
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.videocam, size: 14, color: Colors.white),
                  const SizedBox(width: 4),
                  if (videoController != null && videoController.value.isInitialized)
                    Text(
                      '${videoController.value.duration.inSeconds}s',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCaptionField(int mediaNumber) {
    final controller = mediaNumber == 1 ? _captionController1 : _captionController2;
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        hintText: context.tr('add_caption'),
        hintStyle: TextStyle(color: Colors.grey[400]),
        prefixIcon: Icon(Icons.text_fields, color: Colors.grey[400]),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      style: const TextStyle(fontSize: 14),
      maxLines: 2,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: Row(
                children: [
                  Text(
                    context.tr('create_story'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.blue, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            context.tr('location_automatic'),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          if (_isLocating)
                            const SizedBox(width: 8),
                          if (_isLocating)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IgnorePointer(
                          child: FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: _selectedPosition,
                              initialZoom: 15,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                                subdomains: ['a', 'b', 'c'],
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: _selectedPosition,
                                    child: const Icon(
                                      Icons.location_pin,
                                      color: Colors.red,
                                      size: 40,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_currentAddress != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on, size: 16, color: Colors.blue),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  _currentAddress!,
                                  style: const TextStyle(fontSize: 12),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),
                      Text(
                        context.tr('medias_max'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: _buildMediaPreview(1)),
                          if (_media1 != null) const SizedBox(width: 12),
                          if (_media1 != null)
                            Expanded(child: _buildMediaPreview(2)),
                        ],
                      ),
                      // Légendes pour les médias
                      if (_media1 != null) ...[
                        const SizedBox(height: 8),
                        _buildCaptionField(1),
                      ],
                      if (_media2 != null) ...[
                        const SizedBox(height: 8),
                        _buildCaptionField(2),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        context.tr('photo_video_max_10s'),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      if (_errorMessage.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Text(
                            _errorMessage,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isUploading ? null : _uploadAndCreateStory,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isUploading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  context.tr('create_story_button'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
