import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../auth/providers/auth_provider.dart';
import '../../publications/providers/publications_provider.dart';
import '../../../shared/widgets/mosaic_publications_grid.dart';
import '../../../shared/widgets/platform_video_player.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../auth/screens/login_screen.dart';
import '../../moderation/screens/admin_dashboard_screen.dart';
import '../../settings/screens/settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PublicationsProvider>(context, listen: false)
          .chargerMesPublications();
      _showInactivityWarning();
    });
  }

  Future<void> _showInactivityWarning() async {
    final prefs = await SharedPreferences.getInstance();
    final lastShown = prefs.getString('last_inactivity_warning');
    final today = DateTime.now().toIso8601String().split('T')[0];

    if (lastShown == today) return;

    await prefs.setString('last_inactivity_warning', today);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.info_outline, color: Colors.orange, size: 48),
        title: Text(
          context.tr('inactivity_policy'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('inactivity_warning_message'),
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.tr('keep_account_active'),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.orange),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(context.tr('i_understand'))),
        ],
      ),
    );
  }

  Future<void> _uploadPhotoProfil() async {
    try {
      final image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('uploading')), backgroundColor: Colors.blue),
        );
      }
      
      final success = await authProvider.uploadPhotoProfil(image);

      if (!mounted) return;

      if (success) {
        // Attendre que le cache soit bien actualisé
        await Future.delayed(const Duration(seconds: 1));
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('profile_photo_updated')), backgroundColor: Colors.green),
        );
        
        // Forcer la actualisation de l'UI
        if (mounted) {
          setState(() {});
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authProvider.errorMessage ?? context.tr('upload_error')), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _uploadPhotoGalerie(int position) async {
    try {
      final image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.uploadPhotoGalerie(image, position);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.trParams('photo_updated', {'position': position.toString()})), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authProvider.errorMessage ?? context.tr('upload_error')), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('logout_confirm_title')),
        content: Text(context.tr('logout_confirm_message')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.tr('cancel'))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(context.tr('logout'))),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.deconnexion();

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Color _parseCouleur(String? couleur) {
    if (couleur == null) return Colors.grey;
    try {
      return Color(int.parse(couleur.replaceFirst('#', '0x'))).withOpacity(1);
    } catch (e) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final publicationsProvider = Provider.of<PublicationsProvider>(context);
    final utilisateur = authProvider.utilisateur;

    if (utilisateur == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: RefreshIndicator(
        onRefresh: () async {
          await authProvider.loadUserProfile();
          await publicationsProvider.chargerMesPublications();
        },
        child: SingleChildScrollView(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER AVEC GRADIENT
              Container(
                width: double.infinity,
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
                child: Column(
                  children: [
                    const SizedBox(height: 50),
                    
                    // Photo de profil avec badge
                    Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.2),
                          ),
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.white,
                            child: CircleAvatar(
                              radius: 55,
                              backgroundImage: utilisateur.photoProfilUrl != null
                                  ? CachedNetworkImageProvider(utilisateur.photoProfilUrl!)
                                  : null,
                              child: utilisateur.photoProfilUrl == null
                                  ? Icon(Icons.person, size: 50, color: Colors.grey[400])
                                  : null,
                            ),
                          ),
                        ),
                        if (utilisateur.badgeBleu)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Image.asset(
                              'assets/images/badge_bleu.png',
                              width: 28,
                              height: 28,
                            ),
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Nom utilisateur
                    Text(
                      utilisateur.nomUtilisateur,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    
                    const SizedBox(height: 6),
                    
                    // Email
                    Text(
                      utilisateur.email,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    
                    // Badge Admin
                    if (utilisateur.isAdmin) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: Row(
                           mainAxisSize: MainAxisSize.min,
                           children: [
                             const Icon(Icons.shield, color: Colors.white, size: 16),
                             const SizedBox(width: 6),
                             Text(
                               context.tr('administrator'),
                               style: const TextStyle(
                                 color: Colors.white,
                                 fontSize: 11,
                                 fontWeight: FontWeight.bold,
                                 letterSpacing: 1,
                               ),
                             ),
                           ],
                         ),
                      ),
                    ],
                    
                    const SizedBox(height: 24),
                  ],
                ),
              ),
              
              // CONTENU PRINCIPAL
              Transform.translate(
                offset: const Offset(0, -20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // STATISTIQUES
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatColumn(
                              '${publicationsProvider.mesPublications.length}',
                              context.tr('publications'),
                              Icons.grid_on,
                              Colors.purple,
                            ),
                            Container(width: 1, height: 40, color: Colors.grey[200]),
                            _buildStatColumn(
                              '${utilisateur.pointsSaisonActuelle ?? 0}',
                              context.tr('monthly_points'),
                              Icons.emoji_events,
                              Colors.amber,
                            ),
                            Container(width: 1, height: 40, color: Colors.grey[200]),
                            _buildStatColumn(
                              '${utilisateur.totalPoints}',
                              context.tr('total_points'),
                              Icons.stars,
                              Colors.orange,
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // BOUTONS D'ACTION
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                 onPressed: _uploadPhotoProfil,
                                 icon: const Icon(Icons.camera_alt, size: 18),
                                 label: Text(context.tr('profile_photo')),
                                 style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                                );
                              },
                              icon: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: Icon(Icons.settings_outlined, color: Colors.grey[700]),
                              ),
                            ),
                            IconButton(
                              onPressed: _handleLogout,
                              icon: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: Icon(Icons.logout_outlined, color: Colors.red[400]),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // BIOGRAPHIE
                      if (utilisateur.biographie != null && utilisateur.biographie!.isNotEmpty)
                        _buildSection(
                          title: context.tr('about_me'),
                          icon: Icons.person_outline,
                          children: [
                            Text(
                              utilisateur.biographie!,
                              style: TextStyle(fontSize: 15, color: Colors.grey[700], height: 1.5),
                            ),
                          ],
                        ),
                      
                      // SECTION ADMIN
                      if (utilisateur.isAdmin)
                        _buildSection(
                          title: context.tr('administration'),
                          icon: Icons.admin_panel_settings,
                          children: [
                            InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.orange.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.orange,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.admin_panel_settings, color: Colors.white),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                       child: Column(
                                         crossAxisAlignment: CrossAxisAlignment.start,
                                         children: [
                                           Text(context.tr('admin_panel'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                           Text(context.tr('manage_users_content'), style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                         ],
                                       ),
                                     ),
                                    Icon(Icons.arrow_forward_ios, size: 16, color: Colors.orange[400]),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      
                      // BADGES
                      if (utilisateur.badges.isNotEmpty)
                        _buildSection(
                          title: context.tr('my_badges'),
                          icon: Icons.emoji_events,
                          children: [
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: utilisateur.badges.map((ub) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: _parseCouleur(ub.badge.couleur).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: _parseCouleur(ub.badge.couleur).withOpacity(0.3)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(ub.badge.icone ?? '', style: const TextStyle(fontSize: 16)),
                                      const SizedBox(width: 6),
                                      Text(
                                        ub.badge.nom,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: _parseCouleur(ub.badge.couleur),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      
                      // GALERIE
                      _buildSection(
                        title: context.tr('my_gallery'),
                        icon: Icons.photo_library,
                        children: [
                          Row(
                            children: [
                              _buildGalleryPhoto(1, utilisateur.photoGalerie1Url),
                              const SizedBox(width: 10),
                              _buildGalleryPhoto(2, utilisateur.photoGalerie2Url),
                              const SizedBox(width: 10),
                              _buildGalleryPhoto(3, utilisateur.photoGalerie3Url),
                            ],
                          ),
                        ],
                      ),
                      
                      // PUBLICATIONS
                      _buildSection(
                        title: context.trParams('my_publications', {'count': publicationsProvider.mesPublications.length.toString()}),
                        icon: Icons.grid_on,
                        children: [
                          if (publicationsProvider.isLoading)
                            const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
                          else if (publicationsProvider.mesPublications.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  children: [
                                    Icon(Icons.photo_camera_outlined, size: 60, color: Colors.grey[400]),
                                    const SizedBox(height: 16),
                                    Text(context.tr('no_publications'), style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                                    const SizedBox(height: 8),
                                    Text(context.tr('share_first_good_deed'), style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                                  ],
                                ),
                              ),
                            )
                          else
                            MosaicPublicationsGrid(
                              publications: publicationsProvider.mesPublications,
                              onTap: (pub) {
                                if (pub.typeContenu == 'video' && pub.videosUrls.isNotEmpty) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => PlatformVideoPlayer(videoUrl: pub.videosUrlsFull.first)),
                                  );
                                }
                              },
                            ),
                        ],
                      ),
                      
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String valeur, String label, IconData icon, Color couleur) {
    return Column(
      children: [
        Icon(icon, color: couleur, size: 24),
        const SizedBox(height: 6),
        Text(
          valeur,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Widget _buildSection({required String title, required IconData icon, required List<Widget> children}) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.grey[600], size: 22),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildGalleryPhoto(int position, String? photoUrl) {
    return Expanded(
      child: InkWell(
        onTap: () => _uploadPhotoGalerie(position),
        child: AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: photoUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: photoUrl,
                      fit: BoxFit.cover,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate, color: Colors.grey[500], size: 32),
                      const SizedBox(height: 4),
                      Text(
                        'Photo $position',
                        style: TextStyle(color: Colors.grey[500], fontSize: 11),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
