import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/moderation_provider.dart';
import 'pending_publications_screen.dart';
import 'reports_screen.dart';
import 'assign_badge_screen.dart';
import 'badge_bleu_requests_screen.dart';
import 'manage_blue_badges_screen.dart';
import 'donation_wallet_screen.dart';
import 'manage_admins_screen.dart';

/// Tableau de bord d'administration
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chargerStatistiques();
    });
  }

  Future<void> _chargerStatistiques() async {
    final provider = context.read<ModerationProvider>();
    await provider.chargerStatistiques();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administration'),
        backgroundColor: Colors.orange,
      ),
      body: RefreshIndicator(
        onRefresh: _chargerStatistiques,
        child: Consumer<ModerationProvider>(
          builder: (context, provider, _) {
            final stats = provider.statistiques ?? {};
            final pubStats = stats['publications'] ?? {};
            final sigStats = stats['signalements'] ?? {};
            final userStats = stats['utilisateurs'] ?? {};

            final isLoadingStats = provider.isLoading && provider.statistiques == null;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // En-tête
                const Text(
                  'Tableau de bord',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                // Afficher erreur si présente
                if (provider.errorMessage != null) ...[
                  Card(
                    color: (provider.errorMessage!.contains('402') ? Colors.orange.shade50 : Colors.red.shade50),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: provider.errorMessage!.contains('402') ? Colors.orange : Colors.red),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  provider.errorMessage!.contains('402') 
                                      ? 'Les données n\'ont pas pu être chargées'
                                      : 'Erreur de chargement',
                                  style: TextStyle(
                                    color: provider.errorMessage!.contains('402') ? Colors.orange.shade900 : Colors.red.shade900,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (provider.errorMessage!.contains('402'))
                                  Text(
                                    '402 Payment Required',
                                    style: TextStyle(color: Colors.orange.shade700, fontSize: 12),
                                  ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: _chargerStatistiques,
                            child: const Text('Réessayer'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Afficher loading si en cours
                if (isLoadingStats) ...[
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 12),
                          Text('Chargement des statistiques...'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Statistiques - Publications
                _buildStatCard(
                  title: 'Publications',
                  icon: Icons.article,
                  color: Colors.blue,
                  stats: [
                    _StatItem('Total', pubStats['total'] ?? 0),
                    _StatItem('En attente', pubStats['en_attente'] ?? 0, Colors.orange),
                    _StatItem('Approuvées', pubStats['approuvees'] ?? 0, Colors.green),
                    _StatItem('Rejetées', pubStats['rejetees'] ?? 0, Colors.red),
                  ],
                ),
                const SizedBox(height: 16),

                // Statistiques - Signalements
                _buildStatCard(
                  title: 'Signalements',
                  icon: Icons.flag,
                  color: Colors.red,
                  stats: [
                    _StatItem('Total', sigStats['total'] ?? 0),
                    _StatItem('En attente', sigStats['en_attente'] ?? 0, Colors.orange),
                    _StatItem('Traités', sigStats['traites'] ?? 0, Colors.green),
                    _StatItem('Ignorés', sigStats['ignores'] ?? 0, Colors.grey),
                  ],
                ),
                const SizedBox(height: 16),

                // Statistiques - Utilisateurs
                _buildStatCard(
                  title: 'Utilisateurs',
                  icon: Icons.people,
                  color: Colors.purple,
                  stats: [
                    _StatItem('Total', userStats['total'] ?? 0),
                    _StatItem('Actifs', userStats['actifs'] ?? 0, Colors.green),
                    _StatItem('Suspendus', userStats['suspendus'] ?? 0, Colors.red),
                  ],
                ),
                const SizedBox(height: 32),

                // Actions rapides
                const Text(
                  'Actions rapides',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Bouton - Valider publications
                _buildActionButton(
                  context: context,
                  title: 'Valider les publications',
                  subtitle: '${pubStats['en_attente'] ?? 0} en attente',
                  icon: Icons.check_circle,
                  color: Colors.blue,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PendingPublicationsScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),

                // Bouton - Traiter signalements
                _buildActionButton(
                  context: context,
                  title: 'Traiter les signalements',
                  subtitle: '${sigStats['en_attente'] ?? 0} en attente',
                  icon: Icons.flag,
                  color: Colors.red,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ReportsScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),

                // Bouton - Attribuer badges
                _buildActionButton(
                  context: context,
                  title: 'Attribuer un badge',
                  subtitle: 'Récompenser un utilisateur',
                  icon: Icons.stars,
                  color: Colors.amber,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AssignBadgeScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),

                // Bouton - Demandes de badge bleu
                _buildActionButton(
                  context: context,
                  title: 'Demandes de badge bleu',
                  subtitle: 'Gérer les demandes de certification',
                  icon: Icons.verified,
                  color: Colors.blue,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BadgeBleuRequestsScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),

                // Bouton - Gérer les badges bleus
                _buildActionButton(
                  context: context,
                  title: 'Gérer les badges bleus',
                  subtitle: 'Attribuer ou retirer le badge bleu',
                  icon: Icons.admin_panel_settings,
                  color: Colors.indigo,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ManageBlueBadgesScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),

                // Bouton - Portefeuille des dons
                _buildActionButton(
                  context: context,
                  title: 'Portefeuille des dons',
                  subtitle: 'Voir l\'historique et les statistiques',
                  icon: Icons.account_balance_wallet,
                  color: Colors.red,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DonationWalletScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),

                // Bouton - Gérer les administrateurs
                _buildActionButton(
                  context: context,
                  title: 'Gérer les administrateurs',
                  subtitle: 'Ajouter ou retirer des administrateurs',
                  icon: Icons.admin_panel_settings,
                  color: Colors.deepPurple,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ManageAdminsScreen(),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<_StatItem> stats,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 12,
              children: stats.map((stat) {
                return SizedBox(
                  width: 100,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stat.value.toString(),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: stat.color,
                        ),
                      ),
                      Text(
                        stat.label,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}

class _StatItem {
  final String label;
  final int value;
  final Color? color;

  _StatItem(this.label, this.value, [this.color]);
}
