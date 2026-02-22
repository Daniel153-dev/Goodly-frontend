import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_constants.dart';
import '../../../core/utils/photo_url_helper.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../profile/screens/user_profile_screen.dart';
import 'monthly_winners_screen.dart';
import 'local_leaderboard_screen.dart';

/// Écran du classement (leaderboard) des utilisateurs par points
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<Map<String, dynamic>> _leaderboard = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _chargerLeaderboard();
  }

  Future<void> _chargerLeaderboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiClient = ApiClient();
      final response = await apiClient.get(ApiConstants.leaderboard);
      
      print('DEBUG Leaderboard: Réponse brute = ${response.data}');

      setState(() {
        final data = response.data;
        List<dynamic> usersList = [];
        
        if (data is List) {
          usersList = data;
        } else if (data is Map) {
          if (data.containsKey('users')) {
            usersList = (data['users'] as List?) ?? [];
          } else if (data.containsKey('data')) {
            usersList = (data['data'] as List?) ?? [];
          } else if (data.containsKey('leaderboard')) {
            usersList = (data['leaderboard'] as List?) ?? [];
          }
        }
        
        print('DEBUG Leaderboard: usersList = $usersList');
        
        _leaderboard = usersList.map((user) {
          if (user is Map) {
            return Map<String, dynamic>.from(user);
          }
          return user;
        }).cast<Map<String, dynamic>>().toList();
        
        _leaderboard.sort((a, b) {
          final pointsA = (a['total_points'] as num?)?.toInt() ?? 0;
          final pointsB = (b['total_points'] as num?)?.toInt() ?? 0;
          return pointsB.compareTo(pointsA);
        });
        
        if (_leaderboard.length > 300) {
          _leaderboard = _leaderboard.sublist(0, 300);
        }
        
        print('DEBUG Leaderboard: ${_leaderboard.length} utilisateurs chargés');
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      print('DEBUG Leaderboard: Erreur = $e');
      print('DEBUG Leaderboard: Stack = $stackTrace');
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('🏆 ${context.tr('leaderboard_title')}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.public),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const LocalLeaderboardScreen()));
            },
            tooltip: context.tr('zone_leaderboard'),
          ),
          IconButton(
            icon: const Icon(Icons.emoji_events),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const MonthlyWinnersScreen()));
            },
            tooltip: context.tr('monthly_winners'),
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _chargerLeaderboard, tooltip: context.tr('refresh')),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [theme.colorScheme.primary.withOpacity(0.1), Colors.white],
            stops: const [0.0, 0.3],
          ),
        ),
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
            : _errorMessage != null
                ? Center(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(context.trParams('error_message', {'error': _errorMessage!}), style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _chargerLeaderboard,
                        style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary, foregroundColor: Colors.white),
                        child: Text(context.tr('retry')),
                      ),
                    ]),
                  )
                : _leaderboard.isEmpty
                    ? Center(child: Text(context.tr('no_users_leaderboard')))
                    : RefreshIndicator(
                        onRefresh: _chargerLeaderboard,
                        color: theme.colorScheme.primary,
                        child: ListView.builder(
                          itemCount: _leaderboard.length,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemBuilder: (context, index) {
                            final user = _leaderboard[index];
                            final rang = user['rang'] as int;
                            final points = user['total_points'] as int;

                            Color? rankColor;
                            IconData? rankIcon;
                            if (rang == 1) {
                              rankColor = const Color(0xFFFFD700);
                              rankIcon = Icons.workspace_premium;
                            } else if (rang == 2) {
                              rankColor = const Color(0xFFC0C0C0);
                              rankIcon = Icons.workspace_premium;
                            } else if (rang == 3) {
                              rankColor = const Color(0xFFCD7F32);
                              rankIcon = Icons.workspace_premium;
                            }

                            final String photoUrl = user['photo_profil'] != null && user['photo_profil'].toString().isNotEmpty
                                ? PhotoUrlHelper.getFullPhotoUrl(user['photo_profil'])
                                : '';

                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: rang <= 3 ? (rankColor?.withOpacity(0.3) ?? Colors.grey.withOpacity(0.2)) : Colors.grey.withOpacity(0.1),
                                    blurRadius: rang <= 3 ? 8 : 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                                border: rang <= 3 ? Border.all(color: rankColor ?? Colors.transparent, width: 2) : null,
                              ),
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => UserProfileScreen(userId: user['id_utilisateur'], userName: user['nom_utilisateur']),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: rang <= 3 ? rankColor?.withOpacity(0.2) : theme.colorScheme.primary.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: rankIcon != null ? Icon(rankIcon, color: rankColor, size: 24) : Text('$rang', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Photo de profil avec gestion d'erreur
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.grey[200],
                                      ),
                                      child: ClipOval(
                                        child: photoUrl.isNotEmpty
                                            ? CachedNetworkImage(
                                                imageUrl: photoUrl,
                                                fit: BoxFit.cover,
                                                placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                                errorWidget: (context, url, error) {
                                                  print('DEBUG Leaderboard: Erreur chargement photo $photoUrl: $error');
                                                  return const Icon(Icons.person, color: Colors.grey);
                                                },
                                              )
                                            : const Icon(Icons.person, color: Colors.grey),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                                        Flexible(
                                          child: Text(
                                            user['nom_utilisateur'] ?? context.tr('user'),
                                            style: TextStyle(fontWeight: rang <= 3 ? FontWeight.bold : FontWeight.w600, fontSize: 16, color: Colors.black87),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (user['badge_bleu'] == true) ...[
                                          const SizedBox(width: 4),
                                          Image.asset('assets/images/badge_bleu.png', width: 16, height: 16, errorBuilder: (context, error, stackTrace) {
                                            return const Icon(Icons.verified, color: Colors.blue, size: 16);
                                          }),
                                        ],
                                      ]),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(colors: [theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(0.8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [BoxShadow(color: theme.colorScheme.primary.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))],
                                      ),
                                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                                        Text('$points', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                                        Text(context.tr('pts'), style: const TextStyle(color: Colors.white70, fontSize: 10)),
                                      ]),
                                    ),
                                  ]),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
      ),
    );
  }
}
