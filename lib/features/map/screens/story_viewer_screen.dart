import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/map_story.dart';
import '../services/map_story_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../profile/screens/user_profile_screen.dart';

/// Visionneuse de stories avec barre de progression en vert foncé
class StoryViewerScreen extends StatefulWidget {
  final List<MapStory> stories;
  final int initialIndex;
  final String currentUserId;

  const StoryViewerScreen({
    super.key,
    required this.stories,
    required this.initialIndex,
    required this.currentUserId,
  });

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _progressController;
  int _currentStoryIndex = 0;
  int _currentMediaIndex = 0;
  VideoPlayerController? _videoController;
  bool _isPaused = false;
  late List<List<Map<String, dynamic>>> _allMediasByStory;
  final Set<String> _viewedStoryIds = {}; // Tracker les stories vues dans cette session

  @override
  void initState() {
    super.initState();
    _currentStoryIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    
    // Préparer les médias pour chaque story
    _prepareMedias();
    
    // Initialiser le contrôleur d'animation avec une durée par défaut
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    );
    
    _initCurrentStory();
  }

  /// Prépare la liste des médias pour chaque story
  void _prepareMedias() {
    _allMediasByStory = widget.stories.map((story) {
      final medias = <Map<String, dynamic>>[];
      
      // Ajouter media1
      medias.add({
        'url': story.media1Url,
        'type': story.media1Type,
        'duration': story.media1Duration,
        'caption': story.media1Caption,
      });
      
      // Ajouter media2 s'il existe
      if (story.media2Url != null && story.media2Url!.isNotEmpty) {
        medias.add({
          'url': story.media2Url,
          'type': story.media2Type,
          'duration': story.media2Duration,
          'caption': story.media2Caption,
        });
      }
      
      return medias;
    }).toList();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  void _initCurrentStory() {
    _videoController?.dispose();
    _videoController = null;
    _currentMediaIndex = 0;

    final story = widget.stories[_currentStoryIndex];
    _initMedia();

    // Enregistrer la vue uniquement si elle n'a pas déjà été comptabilisée
    if (!_viewedStoryIds.contains(story.idStory)) {
      _viewedStoryIds.add(story.idStory);
      MapStoryService.viewStory(story.idStory);
    }
  }

  void _initMedia() {
    _videoController?.dispose();
    _videoController = null;

    final medias = _allMediasByStory[_currentStoryIndex];
    if (_currentMediaIndex >= medias.length) {
      _goToNextStory();
      return;
    }

    final media = medias[_currentMediaIndex];
    final mediaUrl = media['url'] as String;
    final mediaType = media['type'] as String;

    // Initialiser la vidéo si c'est une vidéo
    if (mediaType == 'video') {
      _videoController = VideoPlayerController.network(mediaUrl)
        ..initialize().then((_) {
          setState(() {});
          _startProgressAnimation(media);
          if (!_isPaused) {
            _videoController!.play();
          }
        });
    } else {
      _startProgressAnimation(media);
    }
  }

  void _startProgressAnimation(Map<String, dynamic> media) {
    final mediaType = media['type'] as String;
    final duration = mediaType == 'video' && _videoController != null
        ? _videoController!.value.duration.inMilliseconds
        : 5000; // 5 secondes pour les photos

    // Disposer l'ancien contrôleur
    _progressController.dispose();
    
    // Créer un nouveau contrôleur
    _progressController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: duration),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _goToNextMedia();
        }
      });

    _progressController.forward();
  }

  /// Avancer au média suivant, ou à la story suivante si c'était le dernier média
  void _goToNextMedia() {
    final medias = _allMediasByStory[_currentStoryIndex];
    if (_currentMediaIndex < medias.length - 1) {
      setState(() {
        _currentMediaIndex++;
      });
      _initMedia();
    } else {
      _goToNextStory();
    }
  }

  void _goToNextStory() {
    if (_currentStoryIndex < widget.stories.length - 1) {
      setState(() {
        _currentStoryIndex++;
        _currentMediaIndex = 0;
      });
      _pageController.animateToPage(
        _currentStoryIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _initCurrentStory();
    } else {
      Navigator.pop(context);
    }
  }

  void _goToPreviousStory() {
    if (_currentStoryIndex > 0) {
      setState(() {
        _currentStoryIndex--;
        _currentMediaIndex = 0;
      });
      _pageController.animateToPage(
        _currentStoryIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _initCurrentStory();
    }
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });
    if (_isPaused) {
      _progressController.stop();
      _videoController?.pause();
    } else {
      _progressController.forward();
      _videoController?.play();
    }
  }

  Widget _buildProgressBars() {
    final medias = _allMediasByStory[_currentStoryIndex];
    
    return Row(
      children: List.generate(medias.length, (index) {
        final isCompleted = index < _currentMediaIndex;
        final isCurrent = index == _currentMediaIndex;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: AnimatedBuilder(
              animation: _progressController,
              builder: (context, child) {
                final progress = isCurrent ? _progressController.value : (isCompleted ? 1.0 : 0.0);
                return Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: isCompleted || isCurrent
                        ? Colors.white.withOpacity(0.5)
                        : Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: isCurrent
                        ? FractionallySizedBox(
                            widthFactor: progress,
                            alignment: Alignment.centerLeft,
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Color(0xFF006400), // Vert foncé
                              ),
                            ),
                          )
                        : null,
                  ),
                );
              },
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStoryContent(MapStory story) {
    final medias = _allMediasByStory[_currentStoryIndex];
    if (_currentMediaIndex >= medias.length) {
      return const Center(child: CircularProgressIndicator());
    }

    final currentMedia = medias[_currentMediaIndex];
    final mediaUrl = currentMedia['url'] as String;
    final mediaType = currentMedia['type'] as String;
    final isVideo = mediaType == 'video';

    return Stack(
      children: [
        // Média principal (comme WhatsApp - preserve aspect ratio)
        if (isVideo && _videoController != null && _videoController!.value.isInitialized)
          Center(
            child: AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: VideoPlayer(_videoController!),
            ),
          )
        else if (!isVideo)
          Center(
            child: CachedNetworkImage(
              imageUrl: mediaUrl,
              fit: BoxFit.contain,
              placeholder: (context, url) => const Center(
                child: CircularProgressIndicator(),
              ),
              errorWidget: (context, url, error) {
                print('[STORY_VIEWER] Erreur chargement image: $url, Error: $error');
                return const Center(
                  child: Icon(Icons.error, color: Colors.white),
                );
              },
            ),
          )
        else
          Container(color: Colors.black),

        // Zones tactiles pour navigation entre médias (gauche/droite)
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: 50,
          child: GestureDetector(
            onTap: () {
              if (_currentMediaIndex > 0) {
                setState(() => _currentMediaIndex--);
                _initMedia();
              }
            },
            child: Container(
              color: Colors.transparent,
            ),
          ),
        ),
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          width: 50,
          child: GestureDetector(
            onTap: _goToNextMedia,
            child: Container(
              color: Colors.transparent,
            ),
          ),
        ),

        // Info utilisateur en haut
        Positioned(
          top: 60,
          left: 16,
          right: 16,
          child: GestureDetector(
            onTap: () => _goToUserProfile(story.idUtilisateur),
            child: Row(
              children: [
                // Photo de profil
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF006400), width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundImage: story.userProfilePhoto != null
                        ? CachedNetworkImageProvider(story.userProfilePhoto!)
                        : null,
                    child: story.userProfilePhoto == null
                        ? const Icon(Icons.person, size: 24)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                // Nom et temps
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            story.userName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (story.hasBlueBadge) const SizedBox(width: 6),
                          if (story.hasBlueBadge)
                            Image.asset(
                              'assets/images/badge_bleu.png',
                              width: 18,
                              height: 18,
                            ),
                        ],
                      ),
                      Text(
                        _formatTimeAgo(story.createdAt),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Afficher le nombre de vues uniquement pour le propriétaire
        if (story.isOwner)
          Positioned(
            top: 60,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.9),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF006400), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.visibility, size: 20, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    '${story.viewCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Indicateur du média courant (ex: "1/2")
        Positioned(
          bottom: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${_currentMediaIndex + 1}/${medias.length}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ),
        ),
        
        // Légende du média (comme WhatsApp)
        if (currentMedia['caption'] != null && (currentMedia['caption'] as String).isNotEmpty)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
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
              child: Text(
                currentMedia['caption'] as String,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  String _formatTimeAgo(DateTime? dateTime) {
    if (dateTime == null) return '';
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) return context.tr('just_now');
    if (difference.inMinutes < 60) return context.trParams('minutes_ago', {'count': difference.inMinutes.toString()});
    if (difference.inHours < 24) return context.trParams('hours_ago', {'count': difference.inHours.toString()});
    return DateFormat('dd MMM', 'fr').format(dateTime);
  }

  void _goToUserProfile(String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(userId: userId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _togglePause,
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity! < 0) {
            _goToNextStory();
          } else if (details.primaryVelocity! > 0) {
            _goToPreviousStory();
          }
        },
        child: Stack(
          children: [
            // Stories
            PageView.builder(
              controller: _pageController,
              itemCount: widget.stories.length,
              onPageChanged: (index) {
                setState(() {
                  _currentStoryIndex = index;
                  _currentMediaIndex = 0;
                });
                _initCurrentStory();
              },
              itemBuilder: (context, index) {
                return _buildStoryContent(widget.stories[index]);
              },
            ),

            // Barre de progression en haut
            Positioned(
              top: 50,
              left: 10,
              right: 10,
              child: _buildProgressBars(),
            ),

            // Bouton fermer
            Positioned(
              top: 40,
              right: 16,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
