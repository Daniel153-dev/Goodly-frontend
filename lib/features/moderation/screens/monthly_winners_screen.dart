import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_constants.dart';
import '../../../core/utils/photo_url_helper.dart';
import '../../profile/screens/user_profile_screen.dart';

/// Modèle pour les gagnants mensuels
class MonthlyWinner {
  final int rang;
  final String idUtilisateur;
  final int points;
  final String? photoProfil;

  MonthlyWinner({
    required this.rang,
    required this.idUtilisateur,
    required this.points,
    this.photoProfil,
  });

  factory MonthlyWinner.fromJson(Map<String, dynamic> json) {
    return MonthlyWinner(
      rang: json['rang'],
      idUtilisateur: json['id_utilisateur'],
      points: json['points'],
      photoProfil: json['photo_profil'],
    );
  }
}

/// Modèle pour les gagnants d'un mois spécifique
class MonthlyWinnersData {
  final int annee;
  final int mois;
  final List<MonthlyWinner> gagnants;

  MonthlyWinnersData({
    required this.annee,
    required this.mois,
    required this.gagnants,
  });
}

/// Écran des gagnants mensuels (TOP 5 de chaque mois)
class MonthlyWinnersScreen extends StatefulWidget {
  const MonthlyWinnersScreen({super.key});

  @override
  State<MonthlyWinnersScreen> createState() => _MonthlyWinnersScreenState();
}

class _MonthlyWinnersScreenState extends State<MonthlyWinnersScreen> {
  List<Map<String, dynamic>> _allWinners = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Liste des mois avec noms
  final List<Map<String, dynamic>> _months = [
    {'numero': 1, 'nom': 'Janvier'},
    {'numero': 2, 'nom': 'Février'},
    {'numero': 3, 'nom': 'Mars'},
    {'numero': 4, 'nom': 'Avril'},
    {'numero': 5, 'nom': 'Mai'},
    {'numero': 6, 'nom': 'Juin'},
    {'numero': 7, 'nom': 'Juillet'},
    {'numero': 8, 'nom': 'Août'},
    {'numero': 9, 'nom': 'Septembre'},
    {'numero': 10, 'nom': 'Octobre'},
    {'numero': 11, 'nom': 'Novembre'},
    {'numero': 12, 'nom': 'Décembre'},
  ];

  @override
  void initState() {
    super.initState();
    _chargerGagnants();
  }

  Future<void> _chargerGagnants() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiClient = ApiClient();
      final response = await apiClient.get(ApiConstants.monthlyWinners);

      print('DEBUG MonthlyWinners: Réponse brute = ${response.data}');

      if (mounted) {
        setState(() {
          // Parser correctement la réponse
          dynamic data = response.data;
          List<dynamic> winnersList = [];
          
          if (data is List) {
            winnersList = data;
          } else if (data is Map<String, dynamic>) {
            if (data['winners'] != null && data['winners'] is List) {
              winnersList = List<dynamic>.from(data['winners']);
            } else if (data['data'] != null && data['data'] is List) {
              winnersList = List<dynamic>.from(data['data']);
            } else if (data['result'] != null && data['result'] is List) {
              winnersList = List<dynamic>.from(data['result']);
            }
          }
          
          _allWinners = winnersList
              .where((item) => item is Map<String, dynamic>)
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
          
          print('DEBUG MonthlyWinners: _allWinners = $_allWinners');
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      print('DEBUG MonthlyWinners: Erreur = $e');
      print('DEBUG MonthlyWinners: Stack = $stackTrace');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<List<MonthlyWinner>> _chargerGagnantsMois(int annee, int mois) async {
    final apiClient = ApiClient();
    final response = await apiClient.get(
      ApiConstants.monthlyWinnersByMonth(annee, mois),
    );

    // Parser correctement la réponse
    dynamic data = response.data;
    if (data is List) {
      return data.map((json) => MonthlyWinner.fromJson(json as Map<String, dynamic>)).toList();
    } else if (data is Map<String, dynamic> && data['gagnants'] is List) {
      return (data['gagnants'] as List)
          .map((json) => MonthlyWinner.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Color _getRankColor(int rang) {
    switch (rang) {
      case 1:
        return const Color(0xFFFFD700); // Or
      case 2:
        return const Color(0xFFC0C0C0); // Argent
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return const Color(0xFF2E7D32); // Vert
    }
  }

  IconData _getRankIcon(int rang) {
    if (rang <= 3) {
      return Icons.emoji_events;
    }
    return Icons.stars;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          '🏆 Gagnants Mensuels',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Erreur: $_errorMessage',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _chargerGagnants,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : _allWinners.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.emoji_events_outlined,
                            size: 80,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun gagnant enregistré',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Les gagnants apparaîtront ici après la fin de chaque mois',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _allWinners.length,
                      itemBuilder: (context, index) {
                        final monthData = _allWinners[index];
                        final monthName = monthData['mois_nom'];
                        final Map<String, dynamic> winnersByYear = monthData['gagnants'];

                        return _buildMonthCard(
                          monthName: monthName,
                          winnersByYear: winnersByYear,
                        );
                      },
                    ),
    );
  }

  Widget _buildMonthCard({
    required String monthName,
    required Map<String, dynamic> winnersByYear,
  }) {
    final sortedYears = winnersByYear.keys.toList()..sort((a, b) => int.parse(b).compareTo(int.parse(a)));

    // Construire la liste des enfants
    List<Widget> children = [];
    for (final year in sortedYears) {
      final winners = winnersByYear[year];
      if (winners is! List) continue;
      
      children.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            year,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
              fontSize: 14,
            ),
          ),
        ),
      );
      
      for (final winner in winners) {
        if (winner is Map<String, dynamic>) {
          children.add(_buildWinnerItem(
            rang: winner['rang'] ?? 0,
            idUtilisateur: winner['id_utilisateur'] ?? '',
            points: winner['points'] ?? 0,
            photoProfil: winner['photo_profil'],
          ));
        }
      }
      
      children.add(const Divider(height: 1));
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.calendar_month,
                color: Color(0xFF2E7D32),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              monthName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        subtitle: Text(
          '${sortedYears.length} année${sortedYears.length > 1 ? 's' : ''}',
          style: TextStyle(color: Colors.grey[600]),
        ),
        children: children,
      ),
    );
  }

  Widget _buildWinnerItem({
    required int rang,
    required String idUtilisateur,
    required int points,
    required String? photoProfil,
  }) {
    final rankColor = _getRankColor(rang);
    final rankIcon = _getRankIcon(rang);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserProfileScreen(
              userId: idUtilisateur,
              userName: null,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Rang
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: rankColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: rankIcon != Icons.emoji_events
                    ? Text(
                        '$rang',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: rankColor,
                          fontSize: 16,
                        ),
                      )
                    : Icon(
                        rankIcon,
                        color: rankColor,
                        size: 20,
                      ),
              ),
            ),
            const SizedBox(width: 12),
            // Photo de profil
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFF2E7D32).withOpacity(0.1),
              backgroundImage: photoProfil != null
                  ? CachedNetworkImageProvider(_getFullPhotoUrl(photoProfil))
                  : null,
              child: photoProfil == null
                  ? const Icon(Icons.person, color: Color(0xFF2E7D32), size: 24)
                  : null,
            ),
            const SizedBox(width: 12),
            // Points
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$points pts',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                  fontSize: 14,
                ),
              ),
            ),
            const Spacer(),
            // Badge du rang
            if (rang <= 3)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: rankColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: rankColor.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(rankIcon, color: rankColor, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      rang == 1 ? '1er' : '${rang}ème',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: rankColor,
                        fontSize: 12,
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

  String _getFullPhotoUrl(String? photoPath) {
    return PhotoUrlHelper.getFullPhotoUrl(photoPath);
  }
}
