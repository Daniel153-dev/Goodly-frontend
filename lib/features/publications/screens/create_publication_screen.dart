import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:typed_data';
import 'dart:io';
import '../providers/publications_provider.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../core/l10n/app_localizations.dart';

/// Écran de création de publication
class CreatePublicationScreen extends StatefulWidget {
  const CreatePublicationScreen({super.key});

  @override
  State<CreatePublicationScreen> createState() => _CreatePublicationScreenState();
}

class _CreatePublicationScreenState extends State<CreatePublicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  final List<XFile> _selectedImages = [];
  final List<XFile> _selectedVideos = [];
  XFile? _selectedThumbnail; // Miniature pour vidéo
  String? _selectedCategorie;
  String _typeContenu = 'photo_unique'; // photo_unique, carrousel ou video

  final ImagePicker _picker = ImagePicker();
  
  // Localisation automatique
  double? _latitude;
  double? _longitude;
  bool _isLocationLoading = false;
  String? _locationStatus;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  /// Récupère la position GPS actuelle de l'utilisateur
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLocationLoading = true;
      _locationStatus = null;
    });

    try {
      // Vérifier si les services de localisation sont activés
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationStatus = context.tr('location_services_disabled');
          _isLocationLoading = false;
        });
        return;
      }

      // Vérifier les permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationStatus = context.tr('location_permission_denied');
            _isLocationLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationStatus = context.tr('location_permission_denied_forever');
          _isLocationLoading = false;
        });
        return;
      }

      // Récupérer la position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _isLocationLoading = false;
        _locationStatus = context.tr('location_retrieved');
      });

      debugPrint('📍 Position: Lat=$_latitude, Lon=$_longitude');
    } catch (e) {
      debugPrint('❌ Erreur localisation: $e');
      setState(() {
        _isLocationLoading = false;
        _locationStatus = 'Erreur: ${e.toString()}';
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      // Afficher un indicateur de chargement
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('selecting_image')),
          duration: const Duration(seconds: 3),
        ),
      );

      if (_typeContenu == 'photo_unique') {
        // Une seule photo
        final image = await _picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 85, // Compresser légèrement pour éviter les gros fichiers
        );
        if (image != null) {
          if (!mounted) return;
          
          // Vérifier la taille du fichier
          final file = File(image.path);
          if (kIsWeb) {
            // Sur web, la taille peut être différente
            print('📸 Image sélectionnée: ${image.name}');
          } else {
            final sizeInMb = file.lengthSync() / (1024 * 1024);
            if (sizeInMb > 10) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(context.trParams('image_too_large', {'size': sizeInMb.toStringAsFixed(1)})),
                  backgroundColor: Colors.orange,
                ),
              );
              return;
            }
          }
          
          setState(() {
            _selectedImages.clear();
            _selectedImages.add(image);
          });
          
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('image_selected')),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 1),
            ),
          );
        }
      } else {
        // Plusieurs photos (carrousel)
        final images = await _picker.pickMultiImage(
          imageQuality: 80,
        );
        if (images.isNotEmpty) {
          if (!mounted) return;
          
          setState(() {
            _selectedImages.clear();
            _selectedImages.addAll(images.take(10)); // Max 10 images
          });
          
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.trParams('images_selected', {'count': _selectedImages.length.toString()})),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la sélection: ${e.toString().substring(0, 100)}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _pickVideo() async {
    try {
      final video = await _picker.pickVideo(source: ImageSource.gallery);
      if (video != null) {
        // Afficher un indicateur de chargement pendant la vérification
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('checking_video_duration')),
            duration: const Duration(seconds: 2),
          ),
        );

        // Vérifier la durée de la vidéo
        final isValid = await _checkVideoDuration(video);

        if (!mounted) return;

        if (isValid) {
          setState(() {
            _selectedVideos.clear();
            _selectedVideos.add(video);
            _selectedThumbnail = null; // Réinitialiser la miniature
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('video_selected')),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('video_too_long')),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la sélection de vidéo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Vérifie que la durée de la vidéo ne dépasse pas 30 secondes
  Future<bool> _checkVideoDuration(XFile videoFile) async {
    VideoPlayerController? controller;
    try {
      // Créer un contrôleur pour la vidéo
      if (kIsWeb) {
        // Sur web, utiliser networkUrl avec le blob URL
        controller = VideoPlayerController.networkUrl(Uri.parse(videoFile.path));
      } else {
        // Sur mobile, utiliser le chemin du fichier
        final file = File(videoFile.path);
        controller = VideoPlayerController.file(file);
      }

      // Initialiser le contrôleur
      await controller.initialize();

      // Obtenir la durée
      final duration = controller.value.duration;
      final durationInSeconds = duration.inSeconds;

      print('Durée de la vidéo: $durationInSeconds secondes');

      // Retourner true si <= 30 secondes, false sinon
      return durationInSeconds <= 30;
    } catch (e) {
      print('Erreur lors de la vérification de la durée: $e');
      // En cas d'erreur, on accepte la vidéo par défaut
      return true;
    } finally {
      // Toujours libérer le contrôleur
      controller?.dispose();
    }
  }

  Future<void> _pickThumbnail() async {
    try {
      final image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _selectedThumbnail = image;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la sélection de miniature: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handlePublish() async {
    if (!_formKey.currentState!.validate()) return;

    // Vérifier qu'il y a au moins une image ou une vidéo
    if (_selectedImages.isEmpty && _selectedVideos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('select_media_first')),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Vérifier que la miniature est sélectionnée pour les vidéos
    if (_typeContenu == 'video' && _selectedThumbnail == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('select_video_thumbnail')),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final publicationsProvider = Provider.of<PublicationsProvider>(context, listen: false);

    List<String>? imageUrls;
    List<String>? videoUrls;
    String? thumbnailUrl;

    // Afficher un dialogue de progression
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(context.tr('sending_publication')),
              const SizedBox(height: 8),
              Text(
                kIsWeb 
                  ? context.tr('upload_time_web')
                  : context.tr('upload_time_mobile'),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );

    try {
      // Upload des images si présentes
      if (_selectedImages.isNotEmpty) {
        try {
          imageUrls = await publicationsProvider.uploadImages(_selectedImages);
        } catch (e) {
          // Gestion spéciale pour web responsif
          if (kIsWeb && e.toString().contains('timeout')) {
            if (!mounted) return;
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  context.tr('mobile_connection_error')
                ),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 6),
              ),
            );
            return;
          }
          rethrow;
        }
        
        if (imageUrls == null || imageUrls.isEmpty) {
          if (!mounted) return;
          Navigator.of(context).pop(); // Fermer le dialogue
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(publicationsProvider.errorMessage ?? context.tr('image_upload_error')),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
          return;
        }
      }

      // Upload des vidéos si présentes
      if (_selectedVideos.isNotEmpty) {
        try {
          videoUrls = await publicationsProvider.uploadVideos(_selectedVideos);
        } catch (e) {
          if (kIsWeb && e.toString().contains('timeout')) {
            if (!mounted) return;
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.tr('video_too_large_mobile')),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 6),
              ),
            );
            return;
          }
          rethrow;
        }
        
        if (videoUrls == null || videoUrls.isEmpty) {
          if (!mounted) return;
          Navigator.of(context).pop(); // Fermer le dialogue
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(publicationsProvider.errorMessage ?? context.tr('video_upload_error')),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
          return;
        }
      }

      // Upload de la miniature vidéo si présente
      if (_selectedThumbnail != null) {
        final thumbnailUrls = await publicationsProvider.uploadImages([_selectedThumbnail!]);
        if (thumbnailUrls != null && thumbnailUrls.isNotEmpty) {
          thumbnailUrl = thumbnailUrls.first;
        }
      }

      // Créer la publication avec la localisation automatique
      final success = await publicationsProvider.creerPublication(
        titre: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        typeContenu: _typeContenu,
        imagesUrls: imageUrls ?? [],
        videosUrls: videoUrls ?? [],
        videoThumbnail: thumbnailUrl,
        categorie: _selectedCategorie,
        geolocalisation: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
      );

      if (!mounted) return;
      
      // Fermer le dialogue de progression
      Navigator.of(context).pop();

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('publication_created_pending')),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        // Attendre un peu avant de fermer l'écran
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(publicationsProvider.errorMessage ?? context.tr('error_creating_publication')),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Fermer le dialogue en cas d'erreur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.trParams('unexpected_error', {'error': e.toString()})),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final publicationsProvider = Provider.of<PublicationsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle action'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Type de contenu
              Text(
                context.tr('content_type'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: Text(context.tr('single_photo')),
                          value: 'photo_unique',
                          groupValue: _typeContenu,
                          onChanged: (value) {
                            setState(() {
                              _typeContenu = value!;
                              _selectedImages.clear();
                              _selectedVideos.clear();
                              _selectedThumbnail = null;
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: Text(context.tr('carousel')),
                          value: 'carrousel',
                          groupValue: _typeContenu,
                          onChanged: (value) {
                            setState(() {
                              _typeContenu = value!;
                              _selectedImages.clear();
                              _selectedVideos.clear();
                              _selectedThumbnail = null;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  RadioListTile<String>(
                    title: Text(context.tr('video')),
                    value: 'video',
                    groupValue: _typeContenu,
                    onChanged: (value) {
                      setState(() {
                        _typeContenu = value!;
                        _selectedImages.clear();
                        _selectedVideos.clear();
                        _selectedThumbnail = null;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Indicateur de localisation automatique
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _latitude != null 
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _latitude != null 
                        ? Colors.green.withOpacity(0.3)
                        : Colors.orange.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _latitude != null ? Icons.location_on : Icons.location_searching,
                      color: _latitude != null ? Colors.green : Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _isLocationLoading
                          ? Text(
                              context.tr('retrieving_location'),
                              style: TextStyle(fontSize: 13),
                            )
                          : _latitude != null
                              ? Text(
                                  context.trParams('location_enabled_coords', {'lat': _latitude!.toStringAsFixed(4), 'lon': _longitude!.toStringAsFixed(4)}),
                                  style: const TextStyle(fontSize: 13, color: Colors.green),
                                )
                              : Text(
                                  _locationStatus ?? context.tr('location_unavailable'),
                                  style: const TextStyle(fontSize: 13, color: Colors.orange),
                                ),
                    ),
                    if (!_isLocationLoading && _latitude == null)
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 20),
                        onPressed: _getCurrentLocation,
                        tooltip: context.tr('retry'),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Sélection d'images ou vidéos
              if (_typeContenu != 'video')
                OutlinedButton.icon(
                  onPressed: _pickImages,
                  icon: const Icon(Icons.add_photo_alternate),
                  label: Text(_selectedImages.isEmpty
                      ? context.tr('select_images')
                      : context.trParams('images_selected_count', {'count': _selectedImages.length.toString()})),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                )
              else
                OutlinedButton.icon(
                  onPressed: _pickVideo,
                  icon: const Icon(Icons.videocam),
                  label: Text(_selectedVideos.isEmpty
                      ? context.tr('select_video')
                      : context.tr('video_selected')),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),

              // Aperçu des images
              if (_selectedImages.isNotEmpty) ...[
                const SizedBox(height: 16),
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedImages.length,
                    itemBuilder: (context, index) {
                      final file = _selectedImages[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: FutureBuilder<Uint8List>(
                                future: file.readAsBytes(),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData) {
                                    return Image.memory(
                                      snapshot.data!,
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.cover,
                                    );
                                  }
                                  return Container(
                                    width: 120,
                                    height: 120,
                                    color: Colors.grey[300],
                                    child: const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                },
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedImages.removeAt(index);
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],

              // Aperçu des vidéos
              if (_selectedVideos.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.video_library, size: 40, color: Colors.blue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('video_selected_label'),
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              _selectedVideos[0].name,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            _selectedVideos.clear();
                            _selectedThumbnail = null;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Bouton et aperçu de la miniature
                OutlinedButton.icon(
                  onPressed: _pickThumbnail,
                  icon: const Icon(Icons.image),
                  label: Text(_selectedThumbnail == null
                      ? context.tr('select_thumbnail_required')
                      : context.tr('thumbnail_selected')),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
                if (_selectedThumbnail != null) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: FutureBuilder<Uint8List>(
                      future: _selectedThumbnail!.readAsBytes(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return Stack(
                            children: [
                              Image.memory(
                                snapshot.data!,
                                width: double.infinity,
                                height: 200,
                                fit: BoxFit.cover,
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedThumbnail = null;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }
                        return Container(
                          width: double.infinity,
                          height: 200,
                          color: Colors.grey[300],
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 24),

              // Titre
              TextFormField(
                controller: _titleController,
                textInputAction: TextInputAction.next,
                maxLength: 200,
                decoration: InputDecoration(
                  labelText: context.tr('action_title_label'),
                  hintText: context.tr('action_title_hint'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return context.tr('enter_title');
                  }
                  if (value.trim().length < 5) {
                    return context.tr('min_5_chars');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                textInputAction: TextInputAction.newline,
                maxLines: 5,
                maxLength: 2000,
                decoration: InputDecoration(
                  labelText: context.tr('description_label'),
                  hintText: context.tr('description_hint'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return context.tr('enter_description');
                  }
                  if (value.trim().length < 10) {
                    return context.tr('min_10_chars');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Catégorie
              DropdownButtonFormField<String>(
                value: _selectedCategorie,
                decoration: InputDecoration(
                  labelText: context.tr('category'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'environnement',
                    child: Row(
                      children: [
                        const Text('🌱 ', style: TextStyle(fontSize: 18)),
                        Text(context.tr('category_environment')),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'social',
                    child: Row(
                      children: [
                        const Text('🤝 ', style: TextStyle(fontSize: 18)),
                        Text(context.tr('category_social')),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'aide_animaliere',
                    child: Row(
                      children: [
                        const Text('🐾 ', style: TextStyle(fontSize: 18)),
                        Text(context.tr('category_animal')),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'education',
                    child: Row(
                      children: [
                        const Text('📚 ', style: TextStyle(fontSize: 18)),
                        Text(context.tr('category_education')),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'sante',
                    child: Row(
                      children: [
                        const Text('💊 ', style: TextStyle(fontSize: 18)),
                        Text(context.tr('category_health')),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'autre',
                    child: Row(
                      children: [
                        const Text('❤️ ', style: TextStyle(fontSize: 18)),
                        Text(context.tr('category_other')),
                      ],
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedCategorie = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Localisation
              TextFormField(
                controller: _locationController,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: context.tr('location_optional'),
                  hintText: context.tr('location_hint'),
                  prefixIcon: const Icon(Icons.location_on),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Bouton de publication
              CustomButton(
                text: context.tr('publish'),
                onPressed: _handlePublish,
                isLoading: publicationsProvider.isLoading,
                icon: Icons.send,
              ),

              const SizedBox(height: 16),

              // Information
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        context.tr('publication_validation_info'),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
