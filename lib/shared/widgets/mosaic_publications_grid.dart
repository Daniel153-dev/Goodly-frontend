import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/publication.dart';

/// Grille en mosaïque originale pour afficher les publications
/// Design unique qui n'existe pas dans les autres réseaux sociaux
class MosaicPublicationsGrid extends StatelessWidget {
  final List<Publication> publications;
  final Function(Publication)? onTap;

  const MosaicPublicationsGrid({
    super.key,
    required this.publications,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (publications.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.75,
          ),
          itemCount: publications.length,
          itemBuilder: (context, index) {
            final pub = publications[index];
            // Alternance de tailles pour créer un effet mosaïque
            final isBig = index % 5 == 0;

            return _MosaicCard(
              publication: pub,
              isBig: isBig,
              onTap: onTap != null ? () => onTap!(pub) : null,
            );
          },
        );
      },
    );
  }
}

class _MosaicCard extends StatefulWidget {
  final Publication publication;
  final bool isBig;
  final VoidCallback? onTap;

  const _MosaicCard({
    required this.publication,
    required this.isBig,
    this.onTap,
  });

  @override
  State<_MosaicCard> createState() => _MosaicCardState();
}

class _MosaicCardState extends State<_MosaicCard> with SingleTickerProviderStateMixin {
  bool _isHovered = false;

  Color _getCategoryColor() {
    switch (widget.publication.categorie) {
      case 'environnement':
        return Colors.green;
      case 'social':
        return Colors.blue;
      case 'aide_animaliere':
        return Colors.orange;
      case 'education':
        return Colors.purple;
      case 'sante':
        return Colors.red;
      default:
        return Colors.pink;
    }
  }

  String? _getImageUrl() {
    // Pour les vidéos, utiliser la miniature si disponible
    if (widget.publication.typeContenu == 'video') {
      return widget.publication.videoThumbnailUrl;
    }

    if (widget.publication.imagesUrlsFull.isNotEmpty) {
      return widget.publication.imagesUrlsFull.first;
    }
    return null;
  }

  bool get _isVideo => widget.publication.typeContenu == 'video';

  @override
  Widget build(BuildContext context) {
    final categoryColor = _getCategoryColor();
    final imageUrl = _getImageUrl();

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.identity()
          ..scale(_isHovered ? 1.05 : 1.0),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _isHovered
                      ? categoryColor.withOpacity(0.3)
                      : Colors.black.withOpacity(0.1),
                  blurRadius: _isHovered ? 20 : 8,
                  offset: Offset(0, _isHovered ? 8 : 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Image de fond OU placeholder vidéo
                  if (imageUrl != null)
                    CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.error, size: 40),
                      ),
                    )
                  else if (_isVideo)
                    // Placeholder élégant pour les vidéos
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            categoryColor.withOpacity(0.7),
                            categoryColor.withOpacity(0.4),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.play_arrow_rounded,
                            size: 50,
                            color: categoryColor,
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      color: categoryColor.withOpacity(0.3),
                    ),

                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),

                  // Badge catégorie en haut
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: categoryColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.publication.categorieIcon,
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.publication.categorieLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Badge vidéo si c'est une vidéo
                  if (widget.publication.typeContenu == 'video')
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),

                  // Titre en bas
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.publication.titre,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  color: Colors.black,
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Vues
                              const Icon(
                                Icons.visibility,
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.publication.nombreVues}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black,
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Aspirants (inspirations)
                              const Icon(
                                Icons.favorite,
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.publication.nombreInspirations}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black,
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Captivants
                              const Icon(
                                Icons.star,
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.publication.nombreCaptivants}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black,
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bordure accent
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _isHovered
                              ? categoryColor.withOpacity(0.8)
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
