import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'platform_video_player.dart';

/// Lecteur vidéo avec autoplay basé sur la visibilité
class AutoplayVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final double visibilityThreshold;
  final double? maxHeight;

  const AutoplayVideoPlayer({
    super.key,
    required this.videoUrl,
    this.visibilityThreshold = 1.0, // 100% visible par défaut
    this.maxHeight,
  });

  @override
  State<AutoplayVideoPlayer> createState() => _AutoplayVideoPlayerState();
}

class _AutoplayVideoPlayerState extends State<AutoplayVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _showControls = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );

      await _controller!.initialize();

      // Ne pas démarrer automatiquement ici, on attend la visibilité
      _controller!.setLooping(true);

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    if (_controller == null || !_isInitialized) return;

    // Si visible à threshold% ou plus
    if (info.visibleFraction >= widget.visibilityThreshold) {
      if (!_controller!.value.isPlaying) {
        _controller!.play();
      }
    } else {
      // Mettre en pause si moins visible
      if (_controller!.value.isPlaying) {
        _controller!.pause();
      }
    }
  }

  void _togglePlayPause() {
    if (_controller == null) return;

    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
      } else {
        _controller!.play();
      }
    });
  }

  void _toggleMute() {
    if (_controller == null) return;

    setState(() {
      _controller!.setVolume(_controller!.value.volume > 0 ? 0 : 1);
    });
  }

  Future<void> _downloadVideo() async {
    if (kIsWeb) {
      // Sur web, ouvrir le lien de téléchargement dans un nouvel onglet
      final Uri videoUri = Uri.parse(widget.videoUrl);
      if (await canLaunchUrl(videoUri)) {
        await launchUrl(videoUri, mode: LaunchMode.externalApplication);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Téléchargement démarré dans votre navigateur'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } else {
      // Sur mobile, télécharger le fichier
      try {
        // Demander la permission de stockage (seulement pour Android < 13)
        if (Platform.isAndroid) {
          final status = await Permission.storage.request();
          // Android 13+ ne nécessite pas la permission pour télécharger dans Downloads
          if (!status.isGranted && !status.isPermanentlyDenied && !status.isLimited) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Permission de stockage refusée'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }
        }

        // Afficher le snackbar de début de téléchargement
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Téléchargement en cours...'),
              duration: Duration(seconds: 2),
            ),
          );
        }

        // Obtenir le répertoire de téléchargement
        final Directory? directory = Platform.isAndroid
            ? Directory('/storage/emulated/0/Download')
            : await getApplicationDocumentsDirectory();

        if (directory == null) {
          throw Exception('Impossible d\'accéder au répertoire de téléchargement');
        }

        // Générer un nom de fichier unique
        final String fileName = 'goodly_video_${DateTime.now().millisecondsSinceEpoch}.mp4';
        final String savePath = '${directory.path}/$fileName';

        // Télécharger le fichier
        final Dio dio = Dio();
        await dio.download(
          widget.videoUrl,
          savePath,
          onReceiveProgress: (received, total) {
            if (total != -1) {
              final progress = (received / total * 100).toStringAsFixed(0);
              print('Téléchargement: $progress%');
            }
          },
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Vidéo téléchargée: $fileName'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors du téléchargement: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _openFullscreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlatformVideoPlayer(videoUrl: widget.videoUrl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key('video-${widget.videoUrl}'),
      onVisibilityChanged: _onVisibilityChanged,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black,
        child: _hasError
            ? _buildErrorWidget()
            : !_isInitialized
                ? _buildLoadingWidget()
                : _buildVideoPlayer(),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Fond noir avec icône vidéo
        Container(
          color: Colors.black87,
          child: const Icon(
            Icons.play_circle_outline,
            size: 64,
            color: Colors.white54,
          ),
        ),
        // Indicateur de chargement
        const CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ],
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      color: Colors.black87,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 48,
          ),
          SizedBox(height: 8),
          Text(
            'Erreur de chargement vidéo',
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return GestureDetector(
      onTap: _openFullscreen, // Ouvrir en plein écran au tap
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Vidéo
          VideoPlayer(_controller!),

          // Bouton play centré uniquement si la vidéo n'est pas en lecture
          if (!_controller!.value.isPlaying)
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  size: 48,
                  color: Colors.white,
                ),
              ),
            ),

          // Indicateur vidéo en haut à gauche
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.videocam, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'Vidéo',
                    style: TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),

          // Bouton de téléchargement en haut à droite (seulement si vidéo ≤ 30 secondes)
          if (_controller!.value.duration.inSeconds <= 30)
            Positioned(
              top: 8,
              right: 8,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _downloadVideo,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.download,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),

          // Bouton plein écran en bas à droite
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.fullscreen,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
