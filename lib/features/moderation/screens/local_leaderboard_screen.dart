import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_constants.dart';
import '../../../core/utils/photo_url_helper.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../profile/screens/user_profile_screen.dart';

/// Écran du classement local par zone géographique (Pays, Ville, Quartier)
class LocalLeaderboardScreen extends StatefulWidget {
  const LocalLeaderboardScreen({super.key});

  @override
  State<LocalLeaderboardScreen> createState() => _LocalLeaderboardScreenState();
}

class _LocalLeaderboardScreenState extends State<LocalLeaderboardScreen> {
  List<Map<String, dynamic>> _paysList = [];
  List<Map<String, dynamic>> _villesList = [];
  List<Map<String, dynamic>> _quartiersList = [];
  List<Map<String, dynamic>> _leaderboard = [];
  
  Map<String, dynamic>? _selectedPays;
  Map<String, dynamic>? _selectedVille;
  Map<String, dynamic>? _selectedQuartier;
  
  bool _isLoading = true;
  bool _isLoadingLeaderboard = false;
  String? _errorMessage;
  
  int _currentLevel = 0; // 0: Pays, 1: Villes, 2: Quartiers, 3: Leaderboard

  @override
  void initState() {
    super.initState();
    _chargerPays();
  }

  Future<void> _chargerPays() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentLevel = 0;
      _selectedPays = null;
      _selectedVille = null;
      _selectedQuartier = null;
    });

    try {
      final apiClient = ApiClient();
      final response = await apiClient.get('${ApiConstants.publicationsService}${ApiConstants.leaderboardPays}');
      
      setState(() {
        _paysList = List<Map<String, dynamic>>.from(response.data['pays'] ?? []);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _chargerVilles(String paysId) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiClient = ApiClient();
      final response = await apiClient.get('${ApiConstants.publicationsService}${ApiConstants.leaderboardVilles(paysId)}');
      
      setState(() {
        _villesList = List<Map<String, dynamic>>.from(response.data['villes'] ?? []);
        _currentLevel = 1;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _chargerQuartiers(String villeId) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiClient = ApiClient();
      final response = await apiClient.get('${ApiConstants.publicationsService}${ApiConstants.leaderboardQuartiers(villeId)}');
      
      setState(() {
        _quartiersList = List<Map<String, dynamic>>.from(response.data['quartiers'] ?? []);
        _currentLevel = 2;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _chargerLeaderboard(String type, String id) async {
    setState(() {
      _isLoadingLeaderboard = true;
      _errorMessage = null;
    });

    try {
      final apiClient = ApiClient();
      String endpoint;
      if (type == 'pays') {
        endpoint = '${ApiConstants.publicationsService}${ApiConstants.leaderboardTop300Pays(id)}';
      } else if (type == 'ville') {
        endpoint = '${ApiConstants.publicationsService}${ApiConstants.leaderboardTop300Ville(id)}';
      } else {
        endpoint = '${ApiConstants.publicationsService}${ApiConstants.leaderboardTop300Quartier(id)}';
      }
      
      final response = await apiClient.get(endpoint);
      
      setState(() {
        _leaderboard = List<Map<String, dynamic>>.from(response.data['leaderboard'] ?? []);
        _currentLevel = 3;
        _isLoadingLeaderboard = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoadingLeaderboard = false;
      });
    }
  }

  void _goBack() {
    if (_currentLevel == 3) {
      setState(() {
        _currentLevel = 2;
        _leaderboard = [];
      });
    } else if (_currentLevel == 2) {
      setState(() {
        _currentLevel = 1;
        _quartiersList = [];
        _selectedQuartier = null;
      });
    } else if (_currentLevel == 1) {
      setState(() {
        _currentLevel = 0;
        _villesList = [];
        _selectedVille = null;
        _selectedPays = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _getAppBarTitle(context),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: _currentLevel > 0
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: _goBack)
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _currentLevel == 0 ? _chargerPays : () => _refreshCurrentLevel(),
            tooltip: context.tr('refresh'),
          ),
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
                ? _buildErrorWidget(context, theme)
                : _buildContent(context, theme),
      ),
    );
  }

  String _getAppBarTitle(BuildContext context) {
    switch (_currentLevel) {
      case 0:
        return '🌍 ${context.tr('top_300_by_country')}';
      case 1:
        return '🏙️ ${_selectedPays?['nom'] ?? context.tr('cities')}';
      case 2:
        return '🏘️ ${_selectedVille?['nom'] ?? context.tr('neighborhoods')}';
      case 3:
        return '🏆 ${_selectedQuartier?['nom'] ?? _selectedVille?['nom'] ?? _selectedPays?['nom'] ?? context.tr('leaderboard')}';
      default:
        return '🌍 ${context.tr('local_leaderboard')}';
    }
  }

  void _refreshCurrentLevel() {
    if (_currentLevel == 0) {
      _chargerPays();
    } else if (_currentLevel == 1 && _selectedPays != null) {
      _chargerVilles(_selectedPays!['id_pays']);
    } else if (_currentLevel == 2 && _selectedVille != null) {
      _chargerQuartiers(_selectedVille!['id_ville']);
    }
  }

  Widget _buildErrorWidget(BuildContext context, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            context.trParams('error_message', {'error': _errorMessage!}),
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _goBack,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: Text(context.tr('back')),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, ThemeData theme) {
    switch (_currentLevel) {
      case 0:
        return _buildPaysList(context, theme);
      case 1:
        return _buildVillesList(context, theme);
      case 2:
        return _buildQuartiersList(context, theme);
      case 3:
        return _buildLeaderboard(context, theme);
      default:
        return _buildPaysList(context, theme);
    }
  }

  Widget _buildPaysList(BuildContext context, ThemeData theme) {
    if (_paysList.isEmpty) {
      return Center(
        child: Text(
          context.tr('no_active_countries'),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      itemCount: _paysList.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        final pays = _paysList[index];
        return _buildListItem(
          context: context,
          theme: theme,
          title: pays['nom'] ?? context.tr('country'),
          subtitle: context.trParams('users_count', {'count': (pays['nombre_utilisateurs'] ?? 0).toString()}),
          icon: Icons.flag,
          onTap: () {
            setState(() {
              _selectedPays = pays;
            });
            _chargerVilles(pays['id_pays']);
          },
        );
      },
    );
  }

  Widget _buildVillesList(BuildContext context, ThemeData theme) {
    if (_villesList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(context.tr('no_active_cities')),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _chargerLeaderboard('pays', _selectedPays!['id_pays']),
              icon: const Icon(Icons.emoji_events),
              label: Text(context.tr('view_top_300_country')),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Bouton pour voir le classement national
        Padding(
          padding: const EdgeInsets.all(12),
          child: ElevatedButton.icon(
            onPressed: () => _chargerLeaderboard('pays', _selectedPays!['id_pays']),
            icon: const Icon(Icons.emoji_events),
            label: Text(context.trParams('view_top_300_name', {'name': _selectedPays?['nom'] ?? context.tr('national')})),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _villesList.length,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemBuilder: (context, index) {
              final ville = _villesList[index];
              return _buildListItem(
                context: context,
                theme: theme,
                title: ville['nom'] ?? context.tr('city'),
                subtitle: context.trParams('users_count', {'count': (ville['nombre_utilisateurs'] ?? 0).toString()}),
                icon: Icons.location_city,
                onTap: () {
                  setState(() {
                    _selectedVille = ville;
                  });
                  _chargerQuartiers(ville['id_ville']);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuartiersList(BuildContext context, ThemeData theme) {
    if (_quartiersList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(context.tr('no_active_neighborhoods')),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _chargerLeaderboard('ville', _selectedVille!['id_ville']),
              icon: const Icon(Icons.emoji_events),
              label: Text(context.tr('view_top_300_city')),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Bouton pour voir le classement de la ville
        Padding(
          padding: const EdgeInsets.all(12),
          child: ElevatedButton.icon(
            onPressed: () => _chargerLeaderboard('ville', _selectedVille!['id_ville']),
            icon: const Icon(Icons.emoji_events),
            label: Text(context.trParams('view_top_300_name', {'name': _selectedVille?['nom'] ?? context.tr('city')})),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _quartiersList.length,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemBuilder: (context, index) {
              final quartier = _quartiersList[index];
              return _buildListItem(
                context: context,
                theme: theme,
                title: quartier['nom'] ?? context.tr('neighborhood'),
                subtitle: context.trParams('users_count', {'count': (quartier['nombre_utilisateurs'] ?? 0).toString()}),
                icon: Icons.home_work,
                onTap: () {
                  setState(() {
                    _selectedQuartier = quartier;
                  });
                  _chargerLeaderboard('quartier', quartier['id_quartier']);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildListItem({
    required BuildContext context,
    required ThemeData theme,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: theme.colorScheme.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeaderboard(BuildContext context, ThemeData theme) {
    if (_isLoadingLeaderboard) {
      return Center(child: CircularProgressIndicator(color: theme.colorScheme.primary));
    }

    if (_leaderboard.isEmpty) {
      return Center(
        child: Text(context.tr('no_users_leaderboard')),
      );
    }

    return ListView.builder(
      itemCount: _leaderboard.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        final user = _leaderboard[index];
        final rang = user['rang'] as int;
        final points = (user['total_points'] ?? user['points']) as int;

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
                color: rang <= 3
                    ? (rankColor?.withOpacity(0.3) ?? Colors.grey.withOpacity(0.2))
                    : Colors.grey.withOpacity(0.1),
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
                  builder: (context) => UserProfileScreen(
                    userId: user['id_utilisateur'],
                    userName: user['nom_utilisateur'],
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: rang <= 3
                          ? rankColor?.withOpacity(0.2)
                          : theme.colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: rankIcon != null
                          ? Icon(rankIcon, color: rankColor, size: 24)
                          : Text(
                              '$rang',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
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
                              placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              errorWidget: (context, url, error) => const Icon(Icons.person, color: Colors.grey),
                            )
                          : const Icon(Icons.person, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            user['nom_utilisateur'] ?? context.tr('user'),
                            style: TextStyle(
                              fontWeight: rang <= 3 ? FontWeight.bold : FontWeight.w600,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (user['badge_bleu'] == true) ...[
                          const SizedBox(width: 4),
                          Image.asset(
                            'assets/images/badge_bleu.png',
                            width: 16,
                            height: 16,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.verified, color: Colors.blue, size: 16);
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(0.8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$points',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        Text(context.tr('pts'), style: const TextStyle(color: Colors.white70, fontSize: 10)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
