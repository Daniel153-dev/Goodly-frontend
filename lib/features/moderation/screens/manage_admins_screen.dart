import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/models/utilisateur.dart';
import '../providers/moderation_provider.dart';

/// Écran de gestion des administrateurs
class ManageAdminsScreen extends StatefulWidget {
  const ManageAdminsScreen({super.key});

  @override
  State<ManageAdminsScreen> createState() => _ManageAdminsScreenState();
}

class _ManageAdminsScreenState extends State<ManageAdminsScreen> {
  List<Utilisateur> _utilisateurs = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _chargerUtilisateurs();
  }

  Future<void> _chargerUtilisateurs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final provider = context.read<ModerationProvider>();
      final utilisateurs = await provider.chargerListeUtilisateurs();

      setState(() {
        _utilisateurs = utilisateurs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _promouvoirAdmin(Utilisateur utilisateur) async {
    final confirmed = await _showConfirmDialog(
      'Promouvoir ${utilisateur.nomUtilisateur}',
      'Êtes-vous sûr de vouloir promouvoir cet utilisateur au rôle d\'administrateur ?',
    );

    if (confirmed != true) return;

    try {
      final provider = context.read<ModerationProvider>();
      await provider.promouvoirAdmin(utilisateur.idUtilisateur);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${utilisateur.nomUtilisateur} est maintenant administrateur'),
            backgroundColor: Colors.green,
          ),
        );
        _chargerUtilisateurs();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _retrograderAdmin(Utilisateur utilisateur) async {
    final confirmed = await _showConfirmDialog(
      'Rétrograder ${utilisateur.nomUtilisateur}',
      'Êtes-vous sûr de vouloir retirer les droits administrateur de cet utilisateur ?',
    );

    if (confirmed != true) return;

    try {
      final provider = context.read<ModerationProvider>();
      await provider.retrograderAdmin(utilisateur.idUtilisateur);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${utilisateur.nomUtilisateur} n\'est plus administrateur'),
            backgroundColor: Colors.orange,
          ),
        );
        _chargerUtilisateurs();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool?> _showConfirmDialog(String title, String message) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des administrateurs'),
        backgroundColor: Colors.orange,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _chargerUtilisateurs,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _chargerUtilisateurs,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // En-tête
                      const Text(
                        'Liste des utilisateurs',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Total: ${_utilisateurs.length} utilisateurs',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Section Administrateurs
                      _buildSectionTitle('Administrateurs', Icons.admin_panel_settings, Colors.red),
                      const SizedBox(height: 12),
                      ..._buildUserCards(_utilisateurs.where((u) => u.isAdmin).toList(), isAdmin: true),

                      const SizedBox(height: 24),

                      // Section Utilisateurs
                      _buildSectionTitle('Utilisateurs', Icons.people, Colors.blue),
                      const SizedBox(height: 12),
                      ..._buildUserCards(_utilisateurs.where((u) => !u.isAdmin).toList(), isAdmin: false),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildUserCards(List<Utilisateur> users, {required bool isAdmin}) {
    if (users.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            isAdmin ? 'Aucun administrateur' : 'Aucun utilisateur',
            style: TextStyle(
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ];
    }

    return users.map((user) => _buildUserCard(user)).toList();
  }

  Widget _buildUserCard(Utilisateur utilisateur) {
    final isAdmin = utilisateur.isAdmin;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Photo de profil
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.grey[300],
              backgroundImage: utilisateur.photoProfilUrl != null
                  ? NetworkImage(utilisateur.photoProfilUrl!)
                  : null,
              child: utilisateur.photoProfilUrl == null
                  ? Text(
                      utilisateur.nomUtilisateur[0].toUpperCase(),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            const SizedBox(width: 16),

            // Informations utilisateur
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        utilisateur.nomUtilisateur,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isAdmin) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Admin',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    utilisateur.email,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        '${utilisateur.totalPoints} points',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        utilisateur.statutCompte == 'actif'
                            ? Icons.check_circle
                            : Icons.cancel,
                        size: 16,
                        color: utilisateur.statutCompte == 'actif'
                            ? Colors.green
                            : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        utilisateur.statutCompte,
                        style: TextStyle(
                          fontSize: 12,
                          color: utilisateur.statutCompte == 'actif'
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Bouton d'action
            if (isAdmin)
              IconButton(
                onPressed: () => _retrograderAdmin(utilisateur),
                icon: const Icon(Icons.remove_circle, color: Colors.red),
                tooltip: 'Retirer admin',
              )
            else
              IconButton(
                onPressed: () => _promouvoirAdmin(utilisateur),
                icon: const Icon(Icons.add_circle, color: Colors.green),
                tooltip: 'Promouvoir admin',
              ),
          ],
        ),
      ),
    );
  }
}
