import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../auth/providers/auth_provider.dart';
import '../../publications/providers/publications_provider.dart';
import '../../../shared/models/publication.dart';
import '../../../shared/models/utilisateur.dart';
import '../../../shared/widgets/mosaic_publications_grid.dart';
import '../../../shared/widgets/platform_video_player.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../chat/screens/chat_screen.dart';
import '../../chat/services/chat_service.dart';

/// Ecran de profil d'un utilisateur (autre que l'utilisateur connecte)
/// Design simple et fonctionnel comme profile_screen.dart
class UserProfileScreen extends StatefulWidget {
  final String userId;
  final String? userName;

  const UserProfileScreen({
    super.key,
    required this.userId,
    this.userName,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Utilisateur? _utilisateur;
  List<Publication>? _userPublications;
  bool _isLoading = true;
  String? _errorMessage;
  final ChatService _chatService = ChatService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Vérifier que le userId n'est pas vide
      if (widget.userId.isEmpty) {
        print('UserProfileScreen - userId est vide!');
        if (!mounted) return;
        setState(() {
          _errorMessage = context.tr('invalid_user_id');
          _isLoading = false;
        });
        return;
      }

      print('UserProfileScreen - Chargement du profil pour userId: ${widget.userId}');
      
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final publicationsProvider =
          Provider.of<PublicationsProvider>(context, listen: false);

      // Charger le profil de l'utilisateur
      _utilisateur = await authProvider.obtenirProfilUtilisateur(widget.userId);
      
      print('UserProfileScreen - Utilisateur chargé: ${_utilisateur?.nomUtilisateur ?? "null"}');

      // Charger les publications de l'utilisateur
      await publicationsProvider.chargerPublicationsUtilisateur(widget.userId);

      _userPublications = publicationsProvider.publicationsUtilisateur;

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('UserProfileScreen - Erreur: $e');
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorWidget()
              : CustomScrollView(
                  slivers: [
                    // AppBar avec le profil
                    _buildSliverAppBar(theme),
                    
                    // Contenu du profil
                    _buildProfileHeader(theme),
                    
                    // Onglets
                    _buildTabBar(),
                    
                    // Contenu des onglets
                    _buildTabBarView(),
                  ],
                ),
    );
  }

  Widget _buildSliverAppBar(ThemeData theme) {
    return SliverAppBar(
      expandedHeight: 320,
      floating: false,
      pinned: true,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
      title: Text(
        _utilisateur?.nomUtilisateur ?? widget.userName ?? context.tr('profile'),
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () => _showOptionsMenu(),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withOpacity(0.8),
                theme.colorScheme.secondary.withOpacity(0.6),
              ],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 30),
                
                // Photo de profil avec badge
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.3),
                      ),
                      child: CircleAvatar(
                        radius: 55,
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          radius: 50,
                          backgroundImage: _utilisateur?.photoProfilUrl != null
                              ? CachedNetworkImageProvider(
                                  _utilisateur!.photoProfilUrl!)
                              : null,
                          child: _utilisateur?.photoProfilUrl == null
                              ? Icon(Icons.person, size: 45, color: Colors.grey[400])
                              : null,
                        ),
                      ),
                    ),
                    if (_utilisateur?.badgeBleu == true)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Image.asset(
                          'assets/images/badge_bleu.png',
                          width: 26,
                          height: 26,
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Nom utilisateur
                Text(
                  _utilisateur?.nomUtilisateur ?? widget.userName ?? context.tr('user'),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Badge Admin
                if (_utilisateur?.isAdmin == true)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.shield, color: Colors.white, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          context.tr('admin_badge'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(ThemeData theme) {
    // Vérifier si c'est le profil de l'utilisateur courant
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isOwnProfile = authProvider.utilisateur?.idUtilisateur == widget.userId;

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Statistiques
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatColumn(
                  '${_userPublications?.length ?? 0}',
                  context.tr('publications'),
                  Icons.grid_on,
                  Colors.purple,
                ),
                Container(width: 1, height: 50, color: Colors.grey[200]),
                _buildStatColumn(
                  '${_utilisateur?.pointsSaisonActuelle ?? 0}',
                  context.tr('monthly_points'),
                  Icons.emoji_events,
                  Colors.amber,
                ),
                Container(width: 1, height: 50, color: Colors.grey[200]),
                _buildStatColumn(
                  '${_utilisateur?.totalPoints ?? 0}',
                  context.tr('total'),
                  Icons.stars,
                  Colors.green,
                ),
              ],
            ),
            
            // Bouton Écrire (uniquement si ce n'est pas son propre profil)
            if (!isOwnProfile) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _startChatWithUser,
                  icon: const Icon(Icons.edit, color: Colors.white),
                  label: Text(
                    context.tr('write'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
            
            // Biographie
            if (_utilisateur?.biographie != null &&
                _utilisateur!.biographie!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Divider(color: Colors.grey[200]),
              const SizedBox(height: 12),
              Text(
                _utilisateur!.biographie!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 26),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _TabBarDelegate(
        TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.black,
          indicatorWeight: 2,
          tabs: const [
            Tab(icon: Icon(Icons.grid_on, size: 24)),
            Tab(icon: Icon(Icons.photo_library_outlined, size: 24)),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBarView() {
    return SliverFillRemaining(
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildPublicationsTab(),
          _buildGalleryTab(),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            context.tr('unable_load_profile'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? context.tr('unknown_error'),
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadUserProfile,
            icon: const Icon(Icons.refresh),
            label: Text(context.tr('retry')),
          ),
        ],
      ),
    );
  }

  Widget _buildPublicationsTab() {
    if (_userPublications == null || _userPublications!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              context.tr('no_publications'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('user_no_publications'),
              style: TextStyle(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return MosaicPublicationsGrid(
      publications: _userPublications!,
      onTap: (pub) {
        if (pub.typeContenu == 'video' && pub.videosUrls.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PlatformVideoPlayer(
                videoUrl: pub.videosUrlsFull.first,
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildGalleryTab() {
    final photoUrls = [
      _utilisateur?.photoGalerie1Url,
      _utilisateur?.photoGalerie2Url,
      _utilisateur?.photoGalerie3Url,
    ];

    if (_utilisateur == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: 3,
      itemBuilder: (context, index) {
        final photoUrl = photoUrls[index];
        return GestureDetector(
          onTap: photoUrl != null ? () => _showFullScreenImage(photoUrl) : null,
          child: _buildGalleryPhotoItem(photoUrl),
        );
      },
    );
  }

  void _showFullScreenImage(String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  errorWidget: (context, url, error) => const Icon(
                    Icons.error,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildProfileUrl() {
    return 'https://goodly.abrdns.com/profile/${widget.userId}';
  }

  void _copyProfileLink() {
    final profileUrl = _buildProfileUrl();
    Clipboard.setData(ClipboardData(text: profileUrl)).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lien du profil copie !')),
      );
    });
  }

  void _shareProfile() {
    final profileUrl = _buildProfileUrl();
    Share.share('Découvrez mon profil Goodly : $profileUrl');
  }

  Future<void> _startChatWithUser() async {
    // Utiliser widget.userId comme ID de destination
    final targetUserId = _utilisateur?.idUtilisateur ?? widget.userId;
    
    if (targetUserId == null) {
      print('Erreur: ID utilisateur non disponible');
      return;
    }

    print('Démarrage du chat avec l\'utilisateur: $targetUserId');
    
    // Naviguer directement vers l'écran de chat avec un ID de conversation temporaire
    // L'ID sera créé côté serveur lors de l'envoi du premier message
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            conversationId: 'temp_${targetUserId}',
            recipientId: targetUserId,
            recipientName: _utilisateur?.nomUtilisateur ?? 'Utilisateur',
            isNewConversation: true,
          ),
        ),
      ).then((_) {
        print('Navigation vers chatScreen terminée');
      });
    }
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Partager le profil'),
              onTap: () {
                Navigator.pop(context);
                _shareProfile();
              },
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Copier le lien du profil'),
              onTap: () {
                Navigator.pop(context);
                _copyProfileLink();
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag_outlined, color: Colors.red),
              title: const Text('Signaler', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGalleryPhotoItem(String? photoUrl) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
        image: photoUrl != null
            ? DecorationImage(
                image: CachedNetworkImageProvider(photoUrl),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: photoUrl == null
          ? Icon(
              Icons.image_outlined,
              color: Colors.grey[400],
              size: 40,
            )
          : null,
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) => false;
}
