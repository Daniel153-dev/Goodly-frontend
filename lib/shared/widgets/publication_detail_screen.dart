import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/publication.dart';
import 'autoplay_video_player.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../core/api/api_constants.dart';

/// Écran de détail d'une publication en plein écran
class PublicationDetailScreen extends StatefulWidget {
  final Publication publication;

  const PublicationDetailScreen({
    super.key,
    required this.publication,
  });

  @override
  State<PublicationDetailScreen> createState() => _PublicationDetailScreenState();
}

class _PublicationDetailScreenState extends State<PublicationDetailScreen> {
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(widget.publication.nomUtilisateur ?? 'Publication'),
      ),
      body: Column(
        children: [
          // Images ou vidéo en plein écran
          Expanded(
            child: Center(
              child: widget.publication.typeContenu == 'video' &&
                      widget.publication.videosUrls.isNotEmpty
                  ? AutoplayVideoPlayer(
                      videoUrl: _getVideoUrl(widget.publication.videosUrls[0]),
                      visibilityThreshold: 1.0,
                    )
                  : widget.publication.imagesUrlsFull.isNotEmpty
                      ? Stack(
                          children: [
                            PageView.builder(
                              controller: _pageController,
                              itemCount: widget.publication.imagesUrlsFull.length,
                              onPageChanged: (index) {
                                setState(() {
                                  _currentImageIndex = index;
                                });
                              },
                              itemBuilder: (context, index) {
                                return InteractiveViewer(
                                  minScale: 0.5,
                                  maxScale: 4.0,
                                  child: Center(
                                    child: CachedNetworkImage(
                                      imageUrl: widget.publication.imagesUrlsFull[index],
                                      fit: BoxFit.contain,
                                      placeholder: (context, url) => const Center(
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                        ),
                                      ),
                                      errorWidget: (context, url, error) => const Center(
                                        child: Icon(
                                          Icons.error,
                                          size: 50,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            // Indicateur de carrousel
                            if (widget.publication.imagesUrlsFull.length > 1)
                              Positioned(
                                bottom: 16,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black87,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      '${_currentImageIndex + 1}/${widget.publication.imagesUrlsFull.length}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        )
                      : const Center(
                          child: Icon(
                            Icons.image_not_supported,
                            size: 64,
                            color: Colors.white54,
                          ),
                        ),
            ),
          ),

          // Informations de la publication
          Container(
            color: Colors.black,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titre
                Text(
                  widget.publication.titre,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Description
                Text(
                  widget.publication.description,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),

                // Géolocalisation automatique (quartier, ville, pays)
                if (widget.publication.locationDisplay.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.publication.locationDisplay,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                // Catégorie et nombre d'inspirations
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (widget.publication.categorie != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.publication.categorieIcon,
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.publication.categorieLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    const Icon(
                      Icons.favorite,
                      color: Colors.red,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.publication.nombreInspirations} Inspirant${widget.publication.nombreInspirations > 1 ? 's' : ''}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
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

  String _getVideoUrl(String videoUrl) {
    if (videoUrl.startsWith('http://') || videoUrl.startsWith('https://')) {
      return videoUrl;
    }

    // Utiliser ApiConstants.baseUrl au lieu d'une URL codée en dur
    final normalizedUrl = videoUrl.replaceAll('\\', '/');
    final path = normalizedUrl.startsWith('/') ? normalizedUrl : '/$normalizedUrl';

    return '${ApiConstants.baseUrl}$path';
  }
}
