import 'package:flutter/material.dart';
import '../../../core/l10n/app_localizations.dart';

/// Page de politique de confidentialité conforme au RGPD
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('privacy_policy')),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Center(
              child: Icon(
                Icons.privacy_tip,
                size: 64,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),

            Center(
              child: Text(
                context.tr('privacy_policy_title'),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),

            Center(
              child: Text(
                context.tr('last_update_date'),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // 1. Introduction
            _buildSection(
              context,
              context.tr('privacy_section_1_title'),
              context.tr('privacy_section_1_content'),
            ),

            // 2. Responsable du traitement
            _buildSection(
              context,
              context.tr('privacy_section_2_title'),
              context.tr('privacy_section_2_content'),
            ),

            // 3. Données collectées
            _buildSection(
              context,
              context.tr('privacy_section_3_title'),
              context.tr('privacy_section_3_content'),
            ),

            // 4. Base légale et finalités
            _buildSection(
              context,
              context.tr('privacy_section_4_title'),
              context.tr('privacy_section_4_content'),
            ),

            // 5. Utilisation des données
            _buildSection(
              context,
              context.tr('privacy_section_5_title'),
              context.tr('privacy_section_5_content'),
            ),

            // 6. Partage des données
            _buildSection(
              context,
              context.tr('privacy_section_6_title'),
              context.tr('privacy_section_6_content'),
            ),

            // 7. Durée de conservation
            _buildSection(
              context,
              context.tr('privacy_section_7_title'),
              context.tr('privacy_section_7_content'),
            ),

            // 8. Vos droits RGPD
            _buildSection(
              context,
              context.tr('privacy_section_8_title'),
              context.tr('privacy_section_8_content'),
            ),

            // 9. Sécurité
            _buildSection(
              context,
              context.tr('privacy_section_9_title'),
              context.tr('privacy_section_9_content'),
            ),

            // 10. Cookies
            _buildSection(
              context,
              context.tr('privacy_section_10_title'),
              context.tr('privacy_section_10_content'),
            ),

            // 11. Transferts internationaux
            _buildSection(
              context,
              context.tr('privacy_section_11_title'),
              context.tr('privacy_section_11_content'),
            ),

            // 12. Protection des mineurs
            _buildSection(
              context,
              context.tr('privacy_section_12_title'),
              context.tr('privacy_section_12_content'),
            ),

            // 13. Modifications
            _buildSection(
              context,
              context.tr('privacy_section_13_title'),
              context.tr('privacy_section_13_content'),
            ),

            // 14. Contact et réclamations
            _buildSection(
              context,
              context.tr('privacy_section_14_title'),
              context.tr('privacy_section_14_content'),
            ),

            // 15. Consentement
            _buildSection(
              context,
              context.tr('privacy_section_15_title'),
              context.tr('privacy_section_15_content'),
            ),

            const SizedBox(height: 32),

            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.shield_outlined,
                    color: Colors.blue,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.tr('your_data_protected'),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.tr('privacy_commitment'),
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[800],
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
