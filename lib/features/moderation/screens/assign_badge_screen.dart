import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/moderation_provider.dart';
import '../../../shared/models/utilisateur.dart';

/// Écran d'attribution de points aux utilisateurs
class AssignBadgeScreen extends StatefulWidget {
  const AssignBadgeScreen({super.key});

  @override
  State<AssignBadgeScreen> createState() => _AssignBadgeScreenState();
}

class _AssignBadgeScreenState extends State<AssignBadgeScreen> {
  final TextEditingController _searchController = TextEditingController();

  Utilisateur? _selectedUser;
  double _points = 10.0; // Valeur par défaut à 10 points

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query.length >= 2) {
      context.read<ModerationProvider>().rechercherUtilisateurs(query);
    } else {
      context.read<ModerationProvider>().effacerRecherche();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attribuer des points'),
        backgroundColor: Colors.amber,
      ),
      body: Consumer<ModerationProvider>(
        builder: (context, provider, _) {

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Recherche d'utilisateur
                const Text(
                  '1. Rechercher un utilisateur',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Nom ou email de l\'utilisateur',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged();
                              setState(() {
                                _selectedUser = null;
                              });
                            },
                          )
                        : null,
                  ),
                  onChanged: (_) => _onSearchChanged(),
                ),
                const SizedBox(height: 12),

                // Résultats de recherche
                if (provider.utilisateursRecherche.isNotEmpty && _selectedUser == null)
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: provider.utilisateursRecherche.length,
                      itemBuilder: (context, index) {
                        final user = provider.utilisateursRecherche[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: user.photoProfilUrl != null
                                ? NetworkImage(user.photoProfilUrl!)
                                : null,
                            child: user.photoProfilUrl == null
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          title: Text(user.nomUtilisateur),
                          subtitle: Text(user.email),
                          trailing: Text(
                            '${user.totalPoints} pts',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                            ),
                          ),
                          onTap: () {
                            setState(() {
                              _selectedUser = user;
                              _searchController.text = user.nomUtilisateur;
                            });
                            provider.effacerRecherche();
                          },
                        );
                      },
                    ),
                  ),

                // Utilisateur sélectionné
                if (_selectedUser != null) ...{
                  const SizedBox(height: 12),
                  Card(
                    color: Colors.green[50],
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: _selectedUser!.photoProfilUrl != null
                            ? NetworkImage(_selectedUser!.photoProfilUrl!)
                            : null,
                        child: _selectedUser!.photoProfilUrl == null
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      title: Text(_selectedUser!.nomUtilisateur),
                      subtitle: Text(_selectedUser!.email),
                      trailing: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            _selectedUser = null;
                            _searchController.clear();
                          });
                        },
                      ),
                    ),
                  ),
                },

                const SizedBox(height: 32),

                // Sélection du nombre de points
                const Text(
                  '2. Nombre de points à attribuer',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  color: Colors.amber[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Points :',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${_points.round()} pts',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Slider(
                          value: _points,
                          min: 1,
                          max: 100,
                          divisions: 99,
                          label: '${_points.round()} points',
                          activeColor: Colors.amber,
                          onChanged: (value) {
                            setState(() {
                              _points = value;
                            });
                          },
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '1 pt',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '100 pts',
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
                ),

                const SizedBox(height: 24),

                // Bouton d'attribution
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _selectedUser != null
                        ? _attribuerPoints
                        : null,
                    icon: provider.isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.stars),
                    label: const Text('Attribuer les points'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _attribuerPoints() async {
    if (_selectedUser == null) return;

    final provider = context.read<ModerationProvider>();
    final points = _points.round();
    final success = await provider.attribuerPoints(
      userId: _selectedUser!.idUtilisateur,
      points: points,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$points points attribués à ${_selectedUser!.nomUtilisateur}',
          ),
          backgroundColor: Colors.green,
        ),
      );

      // Réinitialiser le formulaire
      setState(() {
        _selectedUser = null;
        _searchController.clear();
        _points = 10.0;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? 'Erreur lors de l\'attribution des points',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
