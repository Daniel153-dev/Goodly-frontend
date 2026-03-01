import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../donation/providers/donation_provider.dart';

/// Écran du portefeuille électronique (admin)
class DonationWalletScreen extends StatefulWidget {
  const DonationWalletScreen({super.key});

  @override
  State<DonationWalletScreen> createState() => _DonationWalletScreenState();
}

class _DonationWalletScreenState extends State<DonationWalletScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chargerDonnees();
    });
  }

  Future<void> _chargerDonnees() async {
    final provider = context.read<DonationProvider>();
    await Future.wait([
      provider.chargerStatistiques(),
      provider.chargerTousLesDons(limit: 50),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Portefeuille des dons'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _chargerDonnees,
        child: Consumer<DonationProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading && provider.statistiques == null) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.errorMessage != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      provider.errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _chargerDonnees,
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              );
            }

            final stats = provider.statistiques;
            final dons = provider.tousLesDons;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // En-tête
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.favorite,
                        color: Colors.red,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Portefeuille des dons',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Suivi des contributions',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Statistiques
                if (stats != null) ...[
                  _buildStatistiquesCard(stats),
                  const SizedBox(height: 24),
                  _buildTopDonateursCard(stats),
                  const SizedBox(height: 24),
                ],

                // Liste des dons
                const Text(
                  'Historique des dons',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                if (dons.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text(
                        'Aucun don pour le moment',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  ...dons.map((don) => _buildDonCard(don)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatistiquesCard(stats) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.red.shade400,
              Colors.red.shade600,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Row(
              children: [
                Icon(Icons.analytics, color: Colors.white, size: 28),
                SizedBox(width: 12),
                Text(
                  'Statistiques globales',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total reçu',
                    '\$${stats.montantTotalUsd}',
                    Icons.attach_money,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withOpacity(0.3),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Nombre de dons',
                    '${stats.totalDons}',
                    Icons.favorite,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Don moyen',
                    '\$${stats.montantMoyenUsd.toStringAsFixed(2)}',
                    Icons.trending_up,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withOpacity(0.3),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Points distribués',
                    '${stats.pointsTotalDistribues}',
                    Icons.stars,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.9),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTopDonateursCard(stats) {
    if (stats.topDonateurs.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.emoji_events, color: Colors.amber, size: 28),
                SizedBox(width: 12),
                Text(
                  'Top 5 des donateurs',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...stats.topDonateurs.asMap().entries.map((entry) {
              final index = entry.key;
              final donateur = entry.value;
              return _buildTopDonateurItem(
                index + 1,
                donateur.nomUtilisateur,
                donateur.photoProfilUrl,
                donateur.totalDonne,
                donateur.nombreDons,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTopDonateurItem(
    int rang,
    String nom,
    String? photoUrl,
    int totalDonne,
    int nombreDons,
  ) {
    Color getRankColor(int rank) {
      switch (rank) {
        case 1:
          return Colors.amber;
        case 2:
          return Colors.grey;
        case 3:
          return Colors.brown;
        default:
          return Colors.blue;
      }
    }

    IconData getRankIcon(int rank) {
      switch (rank) {
        case 1:
          return Icons.emoji_events;
        case 2:
          return Icons.military_tech;
        case 3:
          return Icons.workspace_premium;
        default:
          return Icons.star;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: getRankColor(rang).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Icon(
                getRankIcon(rang),
                color: getRankColor(rang),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 20,
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
            child: photoUrl == null ? Text(nom[0].toUpperCase()) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nom,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '$nombreDons don${nombreDons > 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '\$$totalDonne',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonCard(Map<String, dynamic> don) {
    final dateConfirmation = don['date_confirmation'] != null
        ? DateTime.parse(don['date_confirmation'])
        : null;

    final formattedDate = dateConfirmation != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(dateConfirmation)
        : 'N/A';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 24,
          backgroundImage: don['photo_profil'] != null
              ? NetworkImage(don['photo_profil'])
              : null,
          child: don['photo_profil'] == null
              ? Text(don['nom_utilisateur'][0].toUpperCase())
              : null,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                don['nom_utilisateur'],
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '\$${don['montant_usd']}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              don['email'],
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.stars, size: 14, color: Colors.amber),
                const SizedBox(width: 4),
                Text(
                  '${don['points_attribues']} points',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(width: 12),
                Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  formattedDate,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(
          Icons.check_circle,
          color: Colors.green,
        ),
      ),
    );
  }
}
