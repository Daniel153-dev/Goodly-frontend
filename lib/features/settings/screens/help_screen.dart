import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/l10n/app_localizations.dart';

/// Page d'aide avec contact email
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  Future<void> _sendEmail(BuildContext context) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'danielrollin237@gmail.com',
      query: 'subject=${context.tr('help_email_subject')}&body=${context.tr('help_email_body')}',
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const Color _vertFonce = Color(0xFF2E7D32);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('help_and_support')),
        backgroundColor: _vertFonce,
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
                Icons.help_outline,
                size: 64,
                color: _vertFonce,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                context.tr('goodly_help_center'),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                context.tr('here_to_help'),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Questions fréquentes
            _buildSection(
              context.tr('faq'),
              Icons.question_answer,
              [
                _buildFAQItem(
                  context.tr('faq_create_account_q'),
                  context.tr('faq_create_account_a'),
                ),
                _buildFAQItem(
                  context.tr('faq_publish_photo_q'),
                  context.tr('faq_publish_photo_a'),
                ),
                _buildFAQItem(
                  context.tr('faq_delete_account_q'),
                  context.tr('faq_delete_account_a'),
                ),
                _buildFAQItem(
                  context.tr('faq_promote_posts_q'),
                  context.tr('faq_promote_posts_a'),
                ),
                _buildFAQItem(
                  context.tr('faq_blue_badge_q'),
                  context.tr('faq_blue_badge_a'),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Nous contacter
            _buildSection(
              context.tr('contact_us'),
              Icons.email_outlined,
              [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _vertFonce.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.email,
                        size: 48,
                        color: _vertFonce,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        context.tr('question_need_help'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.tr('team_available'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () => _sendEmail(context),
                        icon: const Icon(Icons.email),
                        label: Text(context.tr('send_email')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _vertFonce,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SelectableText(
                        'danielrollin237@gmail.com',
                        style: const TextStyle(
                          fontSize: 14,
                          color: _vertFonce,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Horaires
            _buildSection(
              context.tr('opening_hours'),
              Icons.access_time,
              [
                _buildInfoRow(context.tr('monday_saturday'), '8h - 20h'),
                _buildInfoRow(context.tr('sunday'), context.tr('closed')),
              ],
            ),

            const SizedBox(height: 32),

            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _vertFonce.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    color: _vertFonce,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('tip'),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          context.tr('check_faq_tip'),
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
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
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.help,
                size: 20,
                color: Color(0xFF2E7D32),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  question,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: Text(
              answer,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
