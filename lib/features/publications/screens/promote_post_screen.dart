import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../shared/models/publication.dart';
import '../../../shared/widgets/autoplay_video_player.dart';
import '../../../features/profile/screens/user_profile_screen.dart';
import '../providers/promotion_provider.dart';
import '../../../core/api/api_constants.dart';
import '../../../core/l10n/app_localizations.dart';

/// Ecran de selection et promotion de posts - Design identique a feed_screen
class PromotePostScreen extends StatefulWidget {
  const PromotePostScreen({super.key});

  @override
  State<PromotePostScreen> createState() => _PromotePostScreenState();
}

class _PromotePostScreenState extends State<PromotePostScreen> {
  // Couleurs identiques a publication_card.dart
  static const Color _kVertFonce = Color(0xFF2E7D32);
  static const Color _kRougeLike = Color(0xFFE57373);
  static const Color _kPrimaryColor = Color(0xFF2E7D32);

  // Controller pour le carrousel d'images
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _getVideoUrl(String videoUrl) {
    if (videoUrl.startsWith('http://') || videoUrl.startsWith('https://')) {
      return videoUrl;
    }
    return '${ApiConstants.baseUrl}$videoUrl';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PromotionProvider>().chargerPublicationsEligibles();
    });
  }

  Future<void> _promouvoirPost(Publication publication) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _kPrimaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.rocket_launch,
                      color: _kPrimaryColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      context.tr('promote_this_publication'),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                publication.titre,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _kPrimaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _kPrimaryColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: _kVertFonce, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            context.tr('promote_benefit_1'),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _kVertFonce,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: _kVertFonce, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            context.tr('promote_benefit_2'),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _kVertFonce,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: _kVertFonce, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            context.tr('promote_benefit_3'),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _kVertFonce,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: _kVertFonce, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            context.tr('promote_benefit_4'),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _kVertFonce,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_kPrimaryColor, _kPrimaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: _kPrimaryColor.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      context.tr('price'),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '100 USD',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.lock,
                          size: 12,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          context.tr('secure_payment_stripe'),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey.shade400),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        context.tr('cancel'),
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kPrimaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        context.tr('pay_and_promote'),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true) return;

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: _kPrimaryColor),
                const SizedBox(height: 16),
                Text(
                  context.tr('processing'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    try {
      final provider = context.read<PromotionProvider>();
      if (kDebugMode) {
        print('[PROMOTION] Appel API creer-session-paiement...');
      }
      final session = await provider.creerSessionPaiement(publication.idPublication);

      if (mounted) Navigator.pop(context);

      if (session == null || session['success'] != true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: ${provider.errorMessage ?? "Impossible de creer la session"}'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (kDebugMode) {
        print('[PROMOTION] Session creee avec succes');
      }

      if (kIsWeb) {
        final checkoutUrl = session['checkout_url'] ?? session['url'];
        if (checkoutUrl == null) {
          throw Exception('URL de paiement non disponible');
        }

        final uri = Uri.parse(checkoutUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  context.tr('payment_opened_new_tab'),
                ),
                backgroundColor: _kPrimaryColor,
                duration: Duration(seconds: 5),
              ),
            );
          }
        } else {
          throw Exception('Impossible d ouvrir le lien de paiement');
        }
        return;
      } else {
        final clientSecret = session['client_secret'];
        final paymentIntentId = session['payment_intent_id'];
        final customerId = session['customer_id'];
        final ephemeralKey = session['ephemeral_key'];

        if (clientSecret == null ||
            paymentIntentId == null ||
            customerId == null ||
            ephemeralKey == null) {
          throw Exception('Donnees de paiement manquantes');
        }

        await stripe.Stripe.instance.initPaymentSheet(
          paymentSheetParameters: stripe.SetupPaymentSheetParameters(
            paymentIntentClientSecret: clientSecret,
            merchantDisplayName: 'GOODLY',
            customerId: customerId,
            customerEphemeralKeySecret: ephemeralKey,
            style: ThemeMode.light,
            appearance: stripe.PaymentSheetAppearance(
              colors: stripe.PaymentSheetAppearanceColors(
                primary: _kPrimaryColor,
              ),
            ),
          ),
        );

        await stripe.Stripe.instance.presentPaymentSheet();
        await _confirmerPaiementMobile(paymentIntentId, publication.idPublication);
      }
    } on stripe.StripeException catch (e) {
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst || route.settings.name == '/promote-post');

        if (e.error.code == stripe.FailureCode.Canceled) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('payment_cancelled')),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
          final errorMsg = e.error.localizedMessage ?? e.error.message ?? context.tr('unknown_error');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.trParams('payment_error', {'error': errorMsg})),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 6),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst || route.settings.name == '/promote-post');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    }
  }

  Future<void> _confirmerPaiementMobile(String paymentIntentId, String publicationId) async {
    final provider = context.read<PromotionProvider>();

    try {
      final success = await provider.confirmerPaiementMobile(paymentIntentId, publicationId);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('post_promoted_7_days')),
              backgroundColor: _kVertFonce,
              duration: Duration(seconds: 4),
            ),
          );
          provider.chargerPublicationsEligibles();
        } else {
          throw Exception(provider.errorMessage ?? 'Le paiement n a pas ete confirme');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(context.tr('promote')),
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: _kPrimaryColor,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<PromotionProvider>().chargerPublicationsEligibles();
            },
          ),
        ],
      ),
      body: Consumer<PromotionProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: _kPrimaryColor),
                  const SizedBox(height: 16),
                  Text(
                    context.tr('loading'),
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          if (provider.errorMessage != null) {
            return _buildErrorView(provider.errorMessage!, context);
          }

          if (provider.publicationsEligibles.isEmpty) {
            return _buildEmptyView();
          }

          return RefreshIndicator(
            onRefresh: () async {
              provider.chargerPublicationsEligibles();
            },
            color: _kPrimaryColor,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: provider.publicationsEligibles.length,
              itemBuilder: (context, index) {
                final publication = provider.publicationsEligibles[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildPostCard(publication),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildPostCard(Publication publication) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: kIsWeb ? 600 : double.infinity,
        ),
        child: Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
          child: InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tete avec photo de profil et nom
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UserProfileScreen(
                                userId: publication.idUtilisateur,
                                userName: publication.nomUtilisateur,
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
                              backgroundImage: publication.photoProfilUrl != null
                                  ? CachedNetworkImageProvider(publication.photoProfilUrl!)
                                  : null,
                              child: publication.photoProfilUrl == null
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
                                      publication.nomUtilisateur ?? 'Utilisateur',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    if (publication.badgeBleu == true) ...[
                                      const SizedBox(width: 4),
                                      Image.asset(
                                        'assets/images/badge_bleu.png',
                                        width: 18,
                                        height: 18,
                                        errorBuilder: (context, error, stackTrace) {
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
                                  _formatDate(publication.dateCreation),
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
                      // Badge de categorie
                      if (publication.categorie != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _kPrimaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                publication.categorieIcon,
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                publication.categorieLabel,
                                style: TextStyle(
                                  color: _kPrimaryColor,
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

                // Images - Carrousel style Instagram
                if (publication.imagesUrlsFull.isNotEmpty)
                  GestureDetector(
                    onHorizontalDragStart: (_) {},
                    onHorizontalDragUpdate: (_) {},
                    onHorizontalDragEnd: (_) {},
                    child: SizedBox(
                      height: 350,
                      width: double.infinity,
                      child: Stack(
                        children: [
                          PageView.builder(
                            controller: _pageController,
                            itemCount: publication.imagesUrlsFull.length,
                            onPageChanged: (index) {
                              setState(() {
                                _currentImageIndex = index;
                              });
                            },
                            itemBuilder: (context, index) {
                              return CachedNetworkImage(
                                imageUrl: publication.imagesUrlsFull[index],
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
                          if (publication.imagesUrlsFull.length > 1 && _currentImageIndex > 0)
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
                          if (publication.imagesUrlsFull.length > 1 && _currentImageIndex < publication.imagesUrlsFull.length - 1)
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
                          if (publication.imagesUrlsFull.length > 1)
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
                                    '${_currentImageIndex + 1}/${publication.imagesUrlsFull.length}',
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

                // Videos - Autoplay
                if (publication.typeContenu == 'video' && publication.videosUrls.isNotEmpty)
                  SizedBox(
                    height: 350,
                    width: double.infinity,
                    child: AutoplayVideoPlayer(
                      videoUrl: _getVideoUrl(publication.videosUrls[0]),
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
                        publication.titre,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        publication.description,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Stats: Aspirants, Vues, Captivants (meme style que feed)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      _buildStatButtonWithIcon(
                        icon: Icons.visibility,
                        label: 'Vues',
                        count: publication.nombreVues,
                        color: _kVertFonce,
                      ),
                      const SizedBox(width: 8),
                      _buildStatButtonWithIcon(
                        icon: Icons.favorite,
                        label: 'Aspirer',
                        count: publication.nombreInspirations,
                        color: _kVertFonce,
                      ),
                      const SizedBox(width: 8),
                      _buildStatButtonWithIcon(
                        icon: Icons.star,
                        label: 'Captivant',
                        count: publication.nombreCaptivants,
                        color: _kVertFonce,
                      ),
                      const Spacer(),
                      // Bouton PROMOUVOIR integre
                      ElevatedButton.icon(
                        onPressed: () => _promouvoirPost(publication),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kPrimaryColor,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.rocket_launch, size: 18, color: Colors.white),
                        label: const Text(
                          'PROMOUVOIR',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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
      ),
    );
  }

  Widget _buildStatButtonWithIcon({
    required IconData icon,
    required String label,
    required int count,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 4),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        const SizedBox(width: 2),
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

  Widget _buildErrorView(String errorMessage, BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _kPrimaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.cloud_off_outlined,
                size: 64,
                color: _kPrimaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              context.tr('server_connection'),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              errorMessage,
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    context.read<PromotionProvider>().chargerPublicationsEligibles();
                  },
                  icon: const Icon(Icons.refresh),
                  label: Text(context.tr('retry')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  ),
                ),
                const SizedBox(width: 16),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    context.tr('back'),
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _kPrimaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.campaign,
                size: 80,
                color: _kPrimaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              context.tr('no_publication_to_promote'),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              context.tr('no_publication_to_promote_desc'),
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.add),
              label: Text(context.tr('create_publication')),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
