import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_constants.dart';

/// Écran de gestion des badges bleus par l'admin
/// Permet de rechercher des utilisateurs et d'attribuer/retirer le badge bleu
class ManageBlueBadgesScreen extends StatefulWidget {
  const ManageBlueBadgesScreen({super.key});

  @override
  State<ManageBlueBadgesScreen> createState() => _ManageBlueBadgesScreenState();
}

class _ManageBlueBadgesScreenState extends State<ManageBlueBadgesScreen> {
  final ApiClient _apiClient = ApiClient();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _allUsersWithBadges = [];
  bool _isLoading = false;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadUsersWithBlueBadge();
  }

  String _getErrorMessage(dynamic error) {
    final message = error.toString().replaceAll('Exception: ', '');
    if (message.contains('402')) {
      return 'Les données n\'ont pas pu être chargées (402 Payment Required)';
    }
    return 'Erreur: $message';
  }

  Future<void> _loadUsersWithBlueBadge() async {
    setState(() => _isLoading = true);

    try {
      // Charger toutes les demandes de badge bleu pour voir qui a le badge
      final response = await _apiClient.get(
        ApiConstants.listeDemandesBadgeBleu,
      );

      if (mounted) {
        setState(() {
          _allUsersWithBadges = List<Map<String, dynamic>>.from(response.data ?? [])
              .where((demande) => demande['badge_achete'] == true)
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getErrorMessage(e)),
            backgroundColor: e.toString().contains('402') ? Colors.orange : Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _users = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final response = await _apiClient.get(
        ApiConstants.rechercherUtilisateurs,
        queryParameters: {'q': query, 'limit': 50},
      );

      if (mounted) {
        setState(() {
          _users = List<Map<String, dynamic>>.from(response.data ?? []);
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearching = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getErrorMessage(e)),
            backgroundColor: e.toString().contains('402') ? Colors.orange : Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _attribuerBadge(Map<String, dynamic> user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Attribuer le badge bleu'),
        content: Text(
          'Voulez-vous attribuer le badge bleu à ${user['nom_utilisateur']} ?\n\n'
          'Cette action donnera accès au badge bleu sans paiement.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      await _apiClient.post(
        ApiConstants.attribuerBadgeBleuAdmin(user['id_utilisateur']),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Badge bleu attribué avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        _searchController.clear();
        _users = [];
        _loadUsersWithBlueBadge();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getErrorMessage(e)),
            backgroundColor: e.toString().contains('402') ? Colors.orange : Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _retirerBadge(Map<String, dynamic> user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retirer le badge bleu'),
        content: Text(
          'Voulez-vous retirer le badge bleu à ${user['nom_utilisateur']} ?\n\n'
          'Cette action peut être utilisée si le badge a été attribué par erreur.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      await _apiClient.post(
        ApiConstants.retirerBadgeBleuAdmin(user['id_utilisateur']),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Badge bleu retiré avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        _searchController.clear();
        _users = [];
        _loadUsersWithBlueBadge();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getErrorMessage(e)),
            backgroundColor: e.toString().contains('402') ? Colors.orange : Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gérer les badges bleus'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _searchUsers,
              decoration: InputDecoration(
                labelText: 'Rechercher un utilisateur',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
            ),
          ),

          // Résultats de recherche
          if (_users.isNotEmpty) ...[
            Expanded(
              child: ListView.builder(
                itemCount: _users.length,
                itemBuilder: (context, index) {
                  final user = _users[index];
                  final hasBadge = _allUsersWithBadges
                      .any((u) => u['id_utilisateur'] == user['id_utilisateur']);

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.shade100,
                        child: Text(
                          (user['nom_utilisateur'] ?? 'U')[0].toUpperCase(),
                          style: const TextStyle(color: Colors.blue),
                        ),
                      ),
                      title: Text(user['nom_utilisateur'] ?? 'Inconnu'),
                      subtitle: Text(user['email'] ?? ''),
                      trailing: ElevatedButton.icon(
                        onPressed: _isLoading
                            ? null
                            : () => hasBadge
                                ? _retirerBadge(user)
                                : _attribuerBadge(user),
                        icon: Icon(hasBadge ? Icons.remove : Icons.add),
                        label: Text(hasBadge ? 'Retirer' : 'Attribuer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: hasBadge ? Colors.red : Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],

          // Message si pas de résultats
          if (_searchController.text.isNotEmpty && _users.isEmpty && !_isSearching)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Text('Aucun utilisateur trouvé'),
            ),

          // Loading
          if (_isLoading && _users.isEmpty)
            const Center(child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            )),
        ],
      ),
    );
  }
}
