import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/moderation_provider.dart';
import '../widgets/publication_review_card.dart';

/// Écran des publications en attente de validation
class PendingPublicationsScreen extends StatefulWidget {
  const PendingPublicationsScreen({super.key});

  @override
  State<PendingPublicationsScreen> createState() =>
      _PendingPublicationsScreenState();
}

class _PendingPublicationsScreenState extends State<PendingPublicationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chargerPublications();
    });
  }

  Future<void> _chargerPublications() async {
    final provider = context.read<ModerationProvider>();
    await provider.chargerPublicationsEnAttente();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Publications en attente'),
        backgroundColor: Colors.blue,
      ),
      body: RefreshIndicator(
        onRefresh: _chargerPublications,
        child: Consumer<ModerationProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.errorMessage != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      provider.errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _chargerPublications,
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              );
            }

            if (provider.publicationsEnAttente.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, size: 64, color: Colors.green[300]),
                    const SizedBox(height: 16),
                    const Text(
                      'Aucune publication en attente',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            // Grille: 4 colonnes sur web, 1 colonne sur mobile pour meilleure lisibilité
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: kIsWeb ? 4 : 1, // 4 sur web, 1 sur mobile
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: kIsWeb ? 0.65 : 0.85, // Ratio adapté selon la plateforme
              ),
              itemCount: provider.publicationsEnAttente.length,
              itemBuilder: (context, index) {
                final publication = provider.publicationsEnAttente[index];
                return PublicationReviewCard(
                  publication: publication,
                  onApprove: () => _approuverPublication(publication.idPublication),
                  onReject: () => _showRejectDialog(publication.idPublication),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _approuverPublication(String publicationId) async {
    final provider = context.read<ModerationProvider>();
    final success = await provider.approuverPublication(publicationId);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Publication approuvée avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Erreur lors de l\'approbation'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showRejectDialog(String publicationId) {
    final raisonController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rejeter la publication'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Veuillez indiquer la raison du rejet :'),
            const SizedBox(height: 16),
            TextField(
              controller: raisonController,
              decoration: const InputDecoration(
                hintText: 'Raison du rejet',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              maxLength: 500,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              final raison = raisonController.text.trim();
              if (raison.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Veuillez indiquer une raison'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              Navigator.pop(dialogContext);
              _rejeterPublication(publicationId, raison);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );
  }

  Future<void> _rejeterPublication(String publicationId, String raison) async {
    final provider = context.read<ModerationProvider>();
    final success = await provider.rejeterPublication(publicationId, raison);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Publication rejetée'),
          backgroundColor: Colors.orange,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Erreur lors du rejet'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
