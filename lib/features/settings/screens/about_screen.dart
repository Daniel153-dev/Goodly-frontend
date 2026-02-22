import 'package:flutter/material.dart';
import '../../../core/l10n/app_localizations.dart';

/// Page À propos de GOODLY
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const Color _vertFonce = Color(0xFF2E7D32);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('about_title')),
        backgroundColor: _vertFonce,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Logo et nom de l'app
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _vertFonce.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 80,
                color: _vertFonce,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              context.tr('app_name'),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: _vertFonce,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('version_number'),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),

            // Qu'est-ce que GOODLY ?
            _buildSection(
              context,
              context.tr('about_what_is_goodly'),
              Icons.public,
              [
                _buildInfoCard(
                  context,
                  context.tr('about_goodly_combines'),
                  [
                    _buildBulletPoint(context, Icons.stars, context.tr('about_reputation')),
                    _buildBulletPoint(context, Icons.leaderboard, context.tr('about_public_ranking')),
                    _buildBulletPoint(context, Icons.location_on, context.tr('about_geolocated_events')),
                    _buildBulletPoint(context, Icons.verified_user, context.tr('about_visibility_badge')),
                  ],
                ),
                const SizedBox(height: 12),
                _buildHighlightBox(
                  context,
                  context.tr('about_no_followers_impact'),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Ce que l'utilisateur gagne sur GOODLY
            _buildSection(
              context,
              context.tr('about_why_different'),
              Icons.compare_arrows,
              [
                _buildFeatureBlock(
                  context,
                  context.tr('about_zero_likes'),
                  context.tr('about_on_goodly'),
                  [
                    _buildCrossItem(context, context.tr('about_no_useless_likes')),
                    _buildCrossItem(context, context.tr('about_no_followers')),
                    _buildCrossItem(context, context.tr('about_no_blocking_algo')),
                  ],
                ),
                const SizedBox(height: 16),
                _buildFeatureBlock(
                  context,
                  context.tr('about_instead'),
                  '',
                  [
                    _buildCheckItem(context, Icons.score, context.tr('about_reputation_score')),
                    _buildCheckItem(context, Icons.emoji_events, context.tr('about_top_300_public')),
                    _buildCheckItem(context, Icons.visibility, context.tr('about_visibility_new_users')),
                    _buildCheckItem(context, Icons.balance, context.tr('about_everyone_equal')),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Le TOP 300
            _buildSection(
              context,
              context.tr('about_top_300_title'),
              Icons.emoji_events,
              [
                _buildInfoCard(
                  context,
                  context.tr('about_top_300_visible'),
                  [],
                ),
                const SizedBox(height: 12),
                _buildHighlightBox(
                  context,
                  context.tr('about_top_300_means'),
                ),
                const SizedBox(height: 8),
                _buildBulletPoint(context, Icons.group, context.tr('about_social_recognition')),
                _buildBulletPoint(context, Icons.badge, context.tr('about_public_status')),
                _buildBulletPoint(context, Icons.lock_open, context.tr('about_exclusive_features')),
                _buildBulletPoint(context, Icons.chat, context.tr('about_reserved_chat')),
                const SizedBox(height: 12),
                _buildHighlightBox(
                  context,
                  context.tr('about_not_popularity_merit'),
                  isItalic: true,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Le Badge Bleu GOODLY
            _buildSection(
              context,
              context.tr('about_blue_badge_title'),
              Icons.verified,
              [
                _buildInfoCard(
                  context,
                  context.tr('about_credibility_visibility'),
                  [
                    _buildBulletPoint(context, Icons.security, context.tr('about_immediate_credibility')),
                    _buildBulletPoint(context, Icons.favorite, context.tr('about_users_trust')),
                    _buildBulletPoint(context, Icons.visibility, context.tr('about_priority_visibility')),
                    _buildBulletPoint(context, Icons.business_center, context.tr('about_professional_image')),
                  ],
                ),
                const SizedBox(height: 16),
                _buildHighlightBox(
                  context,
                  context.tr('about_badge_earned_or_validated'),
                ),
                const SizedBox(height: 12),
                _buildHighlightBox(
                  context,
                  context.tr('about_badge_transforms_profile'),
                  isBold: true,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Promotion des posts
            _buildSection(
              context,
              context.tr('about_post_promotion_title'),
              Icons.campaign,
              [
                _buildInfoCard(
                  context,
                  context.tr('about_you_decide_visibility'),
                  [
                    _buildBulletPoint(context, Icons.speed, context.tr('about_boost_duration')),
                    _buildBulletPoint(context, Icons.touch_app, context.tr('about_extended_reach')),
                    _buildBulletPoint(context, Icons.people, context.tr('about_more_users_access')),
                  ],
                ),
                const SizedBox(height: 12),
                _buildHighlightBox(
                  context,
                  context.tr('about_ideal_for_creators'),
                ),
                const SizedBox(height: 12),
                _buildHighlightBox(
                  context,
                  context.tr('about_visibility_controllable'),
                  isBold: true,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Stories et événements géolocalisés
            _buildSection(
              context,
              context.tr('about_geolocated_stories_title'),
              Icons.map,
              [
                _buildInfoCard(
                  context,
                  context.tr('about_stories_events_feature'),
                  [
                    _buildBulletPoint(context, Icons.photo_camera, context.tr('about_create_stories')),
                    _buildBulletPoint(context, Icons.event, context.tr('about_publish_events')),
                    _buildBulletPoint(context, Icons.store, context.tr('about_link_shop')),
                    _buildBulletPoint(context, Icons.location_on, context.tr('about_geolocate_content')),
                  ],
                ),
                const SizedBox(height: 16),
                _buildHighlightBox(
                  context,
                  context.tr('about_stories_no_followers'),
                ),
                const SizedBox(height: 12),
                _buildInfoCard(
                  context,
                  context.tr('about_advantages_geolocated'),
                  [
                    _buildBulletPoint(context, Icons.visibility, context.tr('about_visible_all_users')),
                    _buildBulletPoint(context, Icons.people_outline, context.tr('about_no_follower_system')),
                    _buildBulletPoint(context, Icons.location_searching, context.tr('about_local_targeting')),
                    _buildBulletPoint(context, Icons.trending_up, context.tr('about_increase_visibility')),
                    _buildBulletPoint(context, Icons.storefront, context.tr('about_promote_shop_events')),
                  ],
                ),
                const SizedBox(height: 12),
                _buildHighlightBox(
                  context,
                  context.tr('about_shop_story_benefit'),
                  isBold: true,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Une réputation qui compte vraiment
            _buildSection(
              context,
              context.tr('about_reputation_counts'),
              Icons.person,
              [
                _buildInfoCard(
                  context,
                  context.tr('about_each_user_has'),
                  [
                    _buildBulletPoint(context, Icons.score, context.tr('about_public_score')),
                    _buildBulletPoint(context, Icons.tag, context.tr('about_visible_rank')),
                    _buildBulletPoint(context, Icons.image, context.tr('about_social_image')),
                  ],
                ),
                const SizedBox(height: 12),
                _buildHighlightBox(
                  context,
                  context.tr('about_this_reputation'),
                ),
                const SizedBox(height: 8),
                _buildBulletPoint(context, Icons.history, context.tr('about_built_over_time')),
                _buildBulletPoint(context, Icons.people_outline, context.tr('about_not_followers_dependent')),
                _buildBulletPoint(context, Icons.monetization_on, context.tr('about_cannot_be_bought')),
                const SizedBox(height: 12),
                _buildHighlightBox(
                  context,
                  context.tr('about_goodly_gives_identity'),
                  isBold: true,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Publicité locale intelligente
            _buildSection(
              context,
              context.tr('about_local_ads_title'),
              Icons.location_searching,
              [
                _buildInfoCard(
                  context,
                  context.tr('about_users_can'),
                  [
                    _buildBulletPoint(context, Icons.event, context.tr('about_promote_event_locally')),
                    _buildBulletPoint(context, Icons.near_me, context.tr('about_reach_nearby_people')),
                    _buildBulletPoint(context, Icons.gps_fixed, context.tr('about_launch_targeted_campaigns')),
                  ],
                ),
                const SizedBox(height: 12),
                _buildHighlightBox(
                  context,
                  context.tr('about_relevant_ads'),
                  isBold: true,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Pourquoi GOODLY est différent
            _buildSection(
              context,
              context.tr('about_why_goodly_different'),
              Icons.lightbulb,
              [
                _buildComparisonTable(context),
              ],
            ),

            const SizedBox(height: 32),

            // Copyright
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _vertFonce.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                context.tr('about_copyright'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, IconData icon, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: const Color(0xFF2E7D32),
              size: 24,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildInfoCard(BuildContext context, String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (children.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...children,
          ],
        ],
      ),
    );
  }

  Widget _buildHighlightBox(BuildContext context, String text, {bool isBold = false, bool isItalic = false}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2E7D32).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF2E7D32).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
          fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
          color: Colors.grey[800],
        ),
      ),
    );
  }

  Widget _buildBulletPoint(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: const Color(0xFF2E7D32),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckItem(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: const Color(0xFF2E7D32),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCrossItem(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(
            Icons.close,
            size: 18,
            color: Colors.red,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureBlock(BuildContext context, String title, String subtitle, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (subtitle.isNotEmpty)
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
              ),
            ),
          if (children.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...children,
          ],
        ],
      ),
    );
  }

  Widget _buildComparisonTable(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // En-têtes
          Row(
            children: [
              Expanded(
                child: Text(
                  context.tr('about_classic_networks'),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  context.tr('app_name'),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          _buildComparisonRow(context, context.tr('about_compare_likes'), context.tr('about_compare_reputation')),
          _buildComparisonRow(context, context.tr('about_compare_opaque_algo'), context.tr('about_compare_clear_ranking')),
          _buildComparisonRow(context, context.tr('about_compare_blocked_visibility'), context.tr('about_compare_boostable_visibility')),
          _buildComparisonRow(context, context.tr('about_compare_artificial_popularity'), context.tr('about_compare_real_credibility')),
          _buildComparisonRow(context, context.tr('about_compare_virtual_network'), context.tr('about_compare_real_connections')),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(BuildContext context, String classic, String goodly) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              classic,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              goodly,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
