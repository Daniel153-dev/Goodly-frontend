import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_constants.dart';

/// Écran de gestion des demandes de badge bleu (admin)
class BadgeBleuRequestsScreen extends StatefulWidget {
  const BadgeBleuRequestsScreen({super.key});

  @override
  State<BadgeBleuRequestsScreen> createState() => _BadgeBleuRequestsScreenState();
}

class _BadgeBleuRequestsScreenState extends State<BadgeBleuRequestsScreen> {
  final ApiClient _apiClient = ApiClient();
  List<Map<String, dynamic>> _demandes = [];
  bool _isLoading = true;
  String? _filterStatut;

  final List<Map<String, dynamic>> _filtres = [
    {'label': 'Toutes', 'value': null},
    {'label': 'En attente', 'value': 'en_attente'},
    {'label': 'Approuvées', 'value': 'approuve'},
    {'label': 'Refusées', 'value': 'refuse'},
  ];

  @override
  void initState() {
    super.initState();
    _loadDemandes();
  }

  Future<void> _loadDemandes() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final response = await _apiClient.get(
        ApiConstants.listeDemandesBadgeBleu,
        queryParameters: _filterStatut != null ? {'statut': _filterStatut} : null,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Délai d\'attente dépassé. Vérifiez votre connexion.');
        },
      );

      if (mounted) {
        setState(() {
          _demandes = List<Map<String, dynamic>>.from(response.data ?? []);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          // Ne pas laisser vide, afficher un message
        });
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

  /// Construit l'URL complète d'une image (gère S3 et chemins relatifs)
  String _getFullImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return '';
    // Si c'est déjà une URL complète (S3 ou autre), la retourner telle quelle
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return imageUrl;
    }
    // Sinon, ajouter le base URL
    return ApiConstants.baseUrl + imageUrl;
  }

  Future<void> _viewImage(BuildContext context, String imageUrl) async {
    // Construire l'URL complète de l'image
    final fullImageUrl = _getFullImageUrl(imageUrl);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Center(
                child: Image.network(
                  fullImageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        color: Colors.white,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error, color: Colors.white, size: 64),
                          SizedBox(height: 16),
                          Text(
                            'Erreur de chargement',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              top: 16,
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

  Future<void> _traiterDemande(
    Map<String, dynamic> demande,
    String decision,
  ) async {
    String? raisonRefus;

    if (decision == 'refuse') {
      // Demander la raison du refus
      raisonRefus = await showDialog<String>(
        context: context,
        builder: (context) {
          final controller = TextEditingController();
          return AlertDialog(
            title: const Text('Raison du refus'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Expliquez pourquoi cette demande est refusée',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, controller.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Confirmer refus'),
              ),
            ],
          );
        },
      );

      if (raisonRefus == null || raisonRefus.isEmpty) {
        return; // Annulé
      }
    }

    try {
      await _apiClient.post(
        ApiConstants.traiterDemandeBadgeBleu(demande['id_demande']),
        data: {
          'decision': decision,
          if (raisonRefus != null) 'raison_refus': raisonRefus,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              decision == 'approuve'
                  ? 'Demande approuvée avec succès'
                  : 'Demande refusée',
            ),
            backgroundColor: decision == 'approuve' ? Colors.green : Colors.red,
          ),
        );
        _loadDemandes(); // Recharger la liste
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Demandes de badge bleu'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Filtres
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              children: [
                const Text(
                  'Filtrer par :',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _filtres.map((filtre) {
                        final isSelected = _filterStatut == filtre['value'];
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(filtre['label']),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _filterStatut = filtre['value'];
                              });
                              _loadDemandes();
                            },
                            selectedColor: Colors.blue,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.black,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Liste des demandes
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _demandes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Aucune demande trouvée',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadDemandes,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _demandes.length,
                          itemBuilder: (context, index) {
                            return _buildDemandeCard(_demandes[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemandeCard(Map<String, dynamic> demande) {
    final statut = demande['statut'];
    Color statutColor = Colors.orange;
    IconData statutIcon = Icons.pending;

    if (statut == 'approuve') {
      statutColor = Colors.green;
      statutIcon = Icons.check_circle;
    } else if (statut == 'refuse') {
      statutColor = Colors.red;
      statutIcon = Icons.cancel;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec info utilisateur
            Row(
              children: [
                // Photo de profil
                CircleAvatar(
                  radius: 24,
                  backgroundImage: demande['photo_profil'] != null
                      ? NetworkImage(_getFullImageUrl(demande['photo_profil']))
                      : null,
                  child: demande['photo_profil'] == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        demande['nom_utilisateur'] ?? 'Utilisateur',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        demande['email'] ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                // Badge de statut
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statutColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: statutColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statutIcon, size: 16, color: statutColor),
                      const SizedBox(width: 4),
                      Text(
                        statut == 'en_attente'
                            ? 'En attente'
                            : statut == 'approuve'
                                ? 'Approuvé'
                                : 'Refusé',
                        style: TextStyle(
                          color: statutColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            // Photos de vérification
            const Text(
              'Documents de vérification',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildPhotoThumbnail(
                    label: 'Carte nationale',
                    imageUrl: demande['photo_carte_nationale'],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPhotoThumbnail(
                    label: 'Photo avec carte',
                    imageUrl: demande['photo_avec_carte'],
                  ),
                ),
              ],
            ),

            // Date de demande
            const SizedBox(height: 16),
            Text(
              'Demande du ${_formatDate(demande['date_demande'])}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),

            // Raison du refus si refusé
            if (statut == 'refuse' && demande['raison_refus'] != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Raison du refus :',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      demande['raison_refus'],
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],

            // Actions (seulement si en attente)
            if (statut == 'en_attente') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _traiterDemande(demande, 'refuse'),
                      icon: const Icon(Icons.cancel),
                      label: const Text('Refuser'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _traiterDemande(demande, 'approuve'),
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Approuver'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],

          ],
        ),
      ),
    );
  }

  Widget _buildPhotoThumbnail({
    required String label,
    required String? imageUrl,
  }) {
    return GestureDetector(
      onTap: imageUrl != null ? () => _viewImage(context, imageUrl) : null,
      child: Column(
        children: [
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      children: [
                        Image.network(
                          _getFullImageUrl(imageUrl),
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          cacheWidth: 300, // Limiter la résolution du cache
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                                strokeWidth: 2,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.error_outline, color: Colors.red, size: 24),
                                  SizedBox(height: 4),
                                  Text(
                                    'Erreur',
                                    style: TextStyle(fontSize: 10, color: Colors.red),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                            ),
                            child: const Icon(
                              Icons.zoom_in,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : const Center(
                    child: Icon(Icons.image_not_supported, color: Colors.grey),
                  ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Date inconnue';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }

  @override
  void dispose() {
    _apiClient.dispose();
    super.dispose();
  }
}

