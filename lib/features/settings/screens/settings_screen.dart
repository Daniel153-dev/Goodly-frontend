import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:url_launcher/url_launcher.dart';
import 'badge_bleu_request_screen.dart';
import 'help_screen.dart';
import 'about_screen.dart';
import 'privacy_policy_screen.dart';
import '../widgets/donation_modal.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_constants.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/auth/screens/login_screen.dart';
import '../../../features/profile/screens/profile_screen.dart';
import '../../../shared/models/utilisateur.dart';
import '../../publications/screens/promote_post_screen.dart';
import '../../analytics/screens/analytics_screen.dart';
import '../../map/screens/manage_locations_screen.dart';
import '../../map/screens/create_shop_screen.dart';

/// Ecran des parametres de l'application - Style WhatsApp
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ApiClient _apiClient = ApiClient();
  Map<String, dynamic>? _badgeBleuDemande;
  bool _isLoadingBadge = true;
  static const Color _kVertFonce = Color(0xFF2E7D32);

  @override
  void initState() {
    super.initState();
    _loadBadgeBleuStatus();
  }

  Future<void> _loadBadgeBleuStatus() async {
    try {
      final response = await _apiClient.get(ApiConstants.maDemandeBadgeBleu);
      if (mounted) {
        setState(() {
          _badgeBleuDemande = response.data;
          _isLoadingBadge = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _badgeBleuDemande = null;
          _isLoadingBadge = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(context.tr('settings')),
        backgroundColor: _kVertFonce,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          const SizedBox(height: 8),

          // ===== SECTION: COMPTE =====
          _buildSectionHeader(context.tr('account_section')),

          // Mes Statistiques
          _buildWhatsAppTile(
            icon: Icons.analytics,
            title: context.tr('my_statistics'),
            subtitle: context.tr('free_30_days'),
            badge: context.tr('free'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
              );
            },
          ),

          const Divider(height: 1, indent: 72),

          // Badge bleu
          if (_isLoadingBadge)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(color: _kVertFonce),
              ),
            )
          else
            ..._buildBadgeBleuSectionWhatsApp(context),

          const SizedBox(height: 24),

          // ===== SECTION: LOCALISATIONS =====
          _buildSectionHeader(context.tr('locations_section')),

          _buildWhatsAppTile(
            icon: Icons.map,
            title: context.tr('my_locations'),
            subtitle: context.tr('manage_events_positions'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ManageLocationsScreen()),
              );
            },
          ),

          const SizedBox(height: 24),

          // ===== SECTION: BOUTIQUES =====
          _buildSectionHeader(context.tr('shops_section')),

          _buildWhatsAppTile(
            icon: Icons.store,
            title: context.tr('my_shop'),
            subtitle: context.tr('create_manage_shop'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateShopScreen()),
              );
            },
          ),

          const SizedBox(height: 24),

          // ===== SECTION: VIE PRIVEE =====
          _buildSectionHeader(context.tr('privacy_section')),

          _buildWhatsAppTile(
            icon: Icons.lock,
            title: context.tr('privacy'),
            subtitle: context.tr('policy_data'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
              );
            },
          ),

          const Divider(height: 1, indent: 72),

          _buildWhatsAppTile(
            icon: Icons.favorite,
            title: context.tr('donate'),
            subtitle: context.tr('support_app'),
            onTap: () {
              _showDonationDialog(context);
            },
          ),

          const Divider(height: 1, indent: 72),

          _buildWhatsAppTile(
            icon: Icons.campaign,
            title: context.tr('promote'),
            subtitle: context.tr('boost_publications'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PromotePostScreen()),
              );
            },
          ),

          const SizedBox(height: 24),

          // ===== SECTION: AIDE =====
          _buildSectionHeader(context.tr('help_section')),

          _buildWhatsAppTile(
            icon: Icons.help_outline,
            title: context.tr('help_support'),
            subtitle: context.tr('faq_contact'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HelpScreen()),
              );
            },
          ),

          const Divider(height: 1, indent: 72),

          _buildWhatsAppTile(
            icon: Icons.info,
            title: context.tr('about'),
            subtitle: '${context.tr('version')} ${_getAppVersion()}',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AboutScreen()),
              );
            },
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: _kVertFonce,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildWhatsAppTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    String? badge,
  }) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _kVertFonce.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: _kVertFonce, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        if (badge != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _kVertFonce,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              badge,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildBadgeBleuSectionWhatsApp(BuildContext context) {
    final statut = _badgeBleuDemande?['statut'];
    final badgeAchete = _badgeBleuDemande?['badge_achete'] ?? false;

    if (_badgeBleuDemande == null) {
      return [
        _buildWhatsAppTile(
          icon: Icons.verified,
          title: context.tr('blue_badge'),
          subtitle: context.tr('certify_account'),
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BadgeBleuRequestScreen()),
            );
            if (result != null || context.mounted) {
              _loadBadgeBleuStatus();
            }
          },
        ),
      ];
    }

    if (statut == 'en_attente') {
      return [
        _buildWhatsAppTile(
          icon: Icons.pending,
          title: context.tr('blue_badge'),
          subtitle: context.tr('under_review'),
          onTap: () {},
        ),
      ];
    }

    if (statut == 'approuve' && badgeAchete) {
      return [
        _buildWhatsAppTile(
          icon: Icons.verified,
          title: context.tr('blue_badge'),
          subtitle: context.tr('certified'),
          onTap: () {},
        ),
      ];
    }

    return [];
  }

  String _getAppVersion() {
    return '1.0.0';
  }

  // ============ Methods from original file ============

  Future<void> _showDonationDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: DonationModal(),
      ),
    );
  }
}
