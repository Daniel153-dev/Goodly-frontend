import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../models/publication.dart';
import 'autoplay_video_player.dart';
import 'publication_detail_screen.dart';
import '../../features/profile/screens/user_profile_screen.dart';
import '../../core/api/api_constants.dart';

// Couleurs utilises dans analytics_screen.dart
const Color _kVertFonce = Color(0xFF2E7D32); // Vert sombre comme dans analytics
const Color _kRougeLike = Color(0xFFE57373); // Rouge clair pour le like actif

/// Carte de publication pour afficher une action
class PublicationCard extends StatefulWidget {
  final Publication publication;
  final VoidCallback? onTap;
  final Function(String)? onInspiration;
  final Function(String)? onDelete;
  final Function(String, String?)? onAdminDelete; // Callback pour suppression admin avec raison optionnelle
  final Function(String)? onVue; // Callback pour enregistrer une vue (30 sec)
  final Function(String)? onCaptivant; // Callback pour enregistrer un captivant (1 min à 100%)
  final bool isInspired;
  final String? currentUserId;
  final bool isAdmin; // Indique si l'utilisateur actuel est un admin

  const PublicationCard({
    super.key,
    required this.publication,
    this.onTap,
    this.onInspiration,
    this.onDelete,
    this.onAdminDelete,
    this.onVue,
    this.onCaptivant,
    this.isInspired = false,
    this.currentUserId,
    this.isAdmin = false,
  });

  @override
  State<PublicationCard> createState() => _PublicationCardState();
}

class _PublicationCardState extends State<PublicationCard> {
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();

  // Tracking de visibilité pour vues et captivants
  Timer? _vueTimer;
  Timer? _captivantTimer;
  bool _vueEnregistree = false;
  bool _captivantEnregistre = false;
  bool _isFullyVisible = false;
  DateTime? _fullVisibilityStart;

  @override
  void initState() {
    super.initState();
    // Initialiser avec les valeurs de la publication
    _vueEnregistree = widget.publication.aVu;
    _captivantEnregistre = widget.publication.aCaptive;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _vueTimer?.cancel();
    _captivantTimer?.cancel();
    super.dispose();
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    final visibleFraction = info.visibleFraction;

    // Si l'utilisateur n'est pas connecté, ne pas tracker
    if (widget.currentUserId == null) return;

    // Tracking pour les vues (30 secondes de visibilité partielle)
    if (visibleFraction > 0.5 && !_vueEnregistree) {
      // Démarrer le timer si pas déjà démarré
      if (_vueTimer == null || !_vueTimer!.isActive) {
        _vueTimer = Timer(const Duration(seconds: 30), () {
          if (mounted && !_vueEnregistree && widget.onVue != null) {
            widget.onVue!(widget.publication.idPublication);
            setState(() {
              _vueEnregistree = true;
            });
          }
        });
      }
    } else if (visibleFraction <= 0.5) {
      // Annuler le timer si le post n'est plus assez visible
      _vueTimer?.cancel();
    }

    // Tracking pour les captivants (1 minute à 100% visible)
    if (visibleFraction >= 0.95 && !_captivantEnregistre) {
      if (!_isFullyVisible) {
        _isFullyVisible = true;
        _fullVisibilityStart = DateTime.now();

        // Démarrer le timer de 1 minute
        _captivantTimer?.cancel();
        _captivantTimer = Timer(const Duration(minutes: 1), () {
          if (mounted && !_captivantEnregistre && _isFullyVisible && widget.onCaptivant != null) {
            widget.onCaptivant!(widget.publication.idPublication);
            setState(() {
              _captivantEnregistre = true;
            });
          }
        });
      }
    } else if (visibleFraction < 0.95) {
      // Le post n'est plus à 100%, annuler le timer
      _isFullyVisible = false;
      _fullVisibilityStart = null;
      _captivantTimer?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return VisibilityDetector(
      key: Key('publication_${widget.publication.idPublication}'),
      onVisibilityChanged: _onVisibilityChanged,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: kIsWeb ? 600 : double.infinity, // Largeur max 600px sur web
          ),
          child: Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
          child: InkWell(
        onTap: widget.onTap ?? () {
          // Ouvrir la publication en plein écran
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PublicationDetailScreen(
                publication: widget.publication,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec photo de profil et nom
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  InkWell(
                    onTap: () {
                      // Naviguer vers le profil de l'utilisateur
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserProfileScreen(
                            userId: widget.publication.idUtilisateur,
                            userName: widget.publication.nomUtilisateur,
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundImage: widget.publication.photoProfilUrl != null
                              ? CachedNetworkImageProvider(widget.publication.photoProfilUrl!)
                              : null,
                          child: widget.publication.photoProfilUrl == null
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  widget.publication.nomUtilisateur ?? 'Utilisateur',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                // Debug: afficher le statut du badge
                                Builder(
                                  builder: (context) {
                                    print('[DEBUG BADGE] ${widget.publication.nomUtilisateur}: badgeBleu = ${widget.publication.badgeBleu}');
                                    return const SizedBox.shrink();
                                  },
                                ),
                                if (widget.publication.badgeBleu == true) ...[
                                  const SizedBox(width: 4),
                                  Image.asset(
                                    'assets/images/badge_bleu.png',
                                    width: 18,
                                    height: 18,
                                    errorBuilder: (context, error, stackTrace) {
                                      print('[ERROR] Impossible de charger badge_bleu.png: $error');
                                      return const Icon(
                                        Icons.verified,
                                        color: Colors.blue,
                                        size: 18,
                                      );
                                    },
                                  ),
                                ],
                              ],
                            ),
                            Text(
                              _formatDate(widget.publication.dateCreation),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Menu suppression (pour l'auteur ou l'admin)
                  if ((widget.onDelete != null &&
                      widget.currentUserId != null &&
                      widget.currentUserId == widget.publication.idUtilisateur) ||
                      (widget.isAdmin && widget.onAdminDelete != null))
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 20),
                      onSelected: (value) {
                        if (value == 'delete') {
                          _showDeleteConfirmation(context);
                        } else if (value == 'admin_delete') {
                          _showAdminDeleteConfirmation(context);
                        }
                      },
                      itemBuilder: (context) => [
                        // Option de suppression pour l'auteur
                        if (widget.onDelete != null &&
                            widget.currentUserId != null &&
                            widget.currentUserId == widget.publication.idUtilisateur)
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                SizedBox(width: 8),
                                Text('Supprimer', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        // Option de suppression admin
                        if (widget.isAdmin && widget.onAdminDelete != null)
                          const PopupMenuItem(
                            value: 'admin_delete',
                            child: Row(
                              children: [
                                Icon(Icons.admin_panel_settings, color: Colors.orange, size: 20),
                                SizedBox(width: 8),
                                Text('Supprimer (Admin)', style: TextStyle(color: Colors.orange)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  const SizedBox(width: 8),
                  // Badge de catégorie
                  if (widget.publication.categorie != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
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
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Images (carrousel ou photo unique) - Format Instagram
            if (widget.publication.imagesUrlsFull.isNotEmpty)
              GestureDetector(
                // Absorber les gestes horizontaux pour permettre le scroll du carrousel
                onHorizontalDragStart: (_) {},
                onHorizontalDragUpdate: (_) {},
                onHorizontalDragEnd: (_) {},
                child: SizedBox(
                  height: 350, // Hauteur fixe réduite
                  width: double.infinity, // Pleine largeur
                  child: Stack(
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
                        return CachedNetworkImage(
                          imageUrl: widget.publication.imagesUrlsFull[index],
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[300],
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.error, size: 50),
                          ),
                        );
                      },
                    ),
                    // Bouton navigation gauche
                    if (widget.publication.imagesUrlsFull.length > 1 && _currentImageIndex > 0)
                      Positioned(
                        left: 8,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.chevron_left, color: Colors.white),
                              onPressed: () {
                                _pageController.previousPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    // Bouton navigation droite
                    if (widget.publication.imagesUrlsFull.length > 1 && _currentImageIndex < widget.publication.imagesUrlsFull.length - 1)
                      Positioned(
                        right: 8,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.chevron_right, color: Colors.white),
                              onPressed: () {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    // Indicateur de carrousel
                    if (widget.publication.imagesUrlsFull.length > 1)
                      Positioned(
                        bottom: 8,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_currentImageIndex + 1}/${widget.publication.imagesUrlsFull.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Vidéos - Autoplay quand visible à 100%
            if (widget.publication.typeContenu == 'video' &&
                widget.publication.videosUrls.isNotEmpty)
              SizedBox(
                height: 350,
                width: double.infinity,
                child: AutoplayVideoPlayer(
                  videoUrl: _getVideoUrl(widget.publication.videosUrls[0]),
                  visibilityThreshold: 1.0,
                ),
              ),

            // Titre et description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.publication.titre,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.publication.description,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Géolocalisation automatique (quartier, ville, pays)
                  if (widget.publication.locationDisplay.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            widget.publication.locationDisplay,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Statistiques: Aspirants, Vues, Captivants (icones style analytics)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // Bouton Aspirer (coeur rouge quand actif)
                  _buildStatButtonWithIcon(
                    icon: Icons.favorite,
                    label: 'Aspirer',
                    count: widget.publication.nombreInspirations,
                    activeColor: _kRougeLike,
                    inactiveColor: _kVertFonce,
                    isActive: widget.isInspired,
                    onTap: widget.onInspiration != null
                        ? () => widget.onInspiration!(widget.publication.idPublication)
                        : null,
                  ),
                  const SizedBox(width: 8),
                  // Compteur de vues (toujours vert foncé)
                  _buildStatButtonWithIcon(
                    icon: Icons.visibility,
                    label: 'Vues',
                    count: widget.publication.nombreVues,
                    activeColor: _kVertFonce,
                    inactiveColor: _kVertFonce,
                    isActive: false, // Toujours inactive color
                    onTap: null,
                  ),
                  const SizedBox(width: 8),
                  // Compteur de captivants (toujours vert foncé)
                  _buildStatButtonWithIcon(
                    icon: Icons.star,
                    label: 'Captivant',
                    count: widget.publication.nombreCaptivants,
                    activeColor: _kVertFonce,
                    inactiveColor: _kVertFonce,
                    isActive: false, // Toujours inactive color
                    onTap: null,
                  ),
                ],
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

  String _getVideoUrl(String videoUrl) {
    if (videoUrl.startsWith('http://') || videoUrl.startsWith('https://')) {
      return videoUrl;
    }

    // Utiliser l'URL de base de l'API (fonctionne en dev et prod)
    final baseUrl = ApiConstants.baseUrl;
    final normalizedUrl = videoUrl.replaceAll('\\', '/');
    final path = normalizedUrl.startsWith('/') ? normalizedUrl : '/$normalizedUrl';

    return '$baseUrl$path';
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la publication'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette publication ? Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onDelete!(widget.publication.idPublication);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _showAdminDeleteConfirmation(BuildContext context) {
    final raisonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings, color: Colors.orange, size: 28),
            SizedBox(width: 8),
            Text('Suppression Admin'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Publication de: ${widget.publication.nomUtilisateur ?? "Utilisateur"}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '"${widget.publication.titre}"',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Cette action est irréversible. L\'auteur sera notifié de la suppression.',
              style: TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: raisonController,
              decoration: const InputDecoration(
                labelText: 'Raison de la suppression (optionnel)',
                hintText: 'Ex: Contenu inapproprié',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              final raison = raisonController.text.isEmpty
                  ? null
                  : raisonController.text;
              widget.onAdminDelete!(widget.publication.idPublication, raison);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatButtonWithIcon({
    required IconData icon,
    required String label,
    required int count,
    required Color activeColor,
    required Color inactiveColor,
    required bool isActive,
    VoidCallback? onTap,
  }) {
    final color = isActive ? activeColor : inactiveColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: 22,
            ),
            const SizedBox(width: 6),
            Text(
              '$count',
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Methode icon originale ( Gardee pour compatibilite si necessaire )
  Widget _buildStatButton({
    required IconData icon,
    required String label,
    required int count,
    required Color color,
    required bool isActive,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? color.withOpacity(0.3) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 5),
            Text(
              '$count',
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: isActive ? color : Colors.grey[700],
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'Il y a ${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'Il y a ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'À l\'instant';
    }
  }
}
