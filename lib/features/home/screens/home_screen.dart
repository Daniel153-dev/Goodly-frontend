import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../publications/screens/feed_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../moderation/screens/leaderboard_screen.dart';
import '../../map/screens/map_screen.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/l10n/app_localizations.dart';

/// Écran d'accueil avec navigation par onglets responsive
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 1; // Commencer par MapScreen (index 1)

  final List<Widget> _screens = const [
    FeedScreen(),
    MapScreen(),
    LeaderboardScreen(),
    ProfileScreen(),
  ];

  List<NavigationItem> _getNavItems(BuildContext context) {
    return [
      NavigationItem(
        icon: Icons.home,
        label: context.tr('home'),
      ),
      NavigationItem(
        icon: Icons.map,
        label: context.tr('map'),
      ),
      NavigationItem(
        icon: Icons.emoji_events,
        label: context.tr('leaderboard'),
      ),
      NavigationItem(
        icon: Icons.person,
        label: context.tr('profile'),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final navItems = _getNavItems(context);

    // Layout responsive: sidebar sur desktop, bottom nav sur mobile
    if (kIsWeb && Responsive.isDesktop(context)) {
      return _DesktopLayout(
        currentIndex: _currentIndex,
        navItems: navItems,
        screens: _screens,
        onItemTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        authProvider: authProvider,
      );
    }

    // Layout mobile classique
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor: Colors.grey,
        items: navItems
            .map((item) => BottomNavigationBarItem(
                  icon: Icon(item.icon),
                  label: item.label,
                ))
            .toList(),
      ),
    );
  }
}

/// Navigation item model
class NavigationItem {
  final IconData icon;
  final String label;

  const NavigationItem({
    required this.icon,
    required this.label,
  });
}

/// Layout desktop avec sidebar
class _DesktopLayout extends StatelessWidget {
  final int currentIndex;
  final List<NavigationItem> navItems;
  final List<Widget> screens;
  final Function(int) onItemTap;
  final AuthProvider authProvider;

  const _DesktopLayout({
    required this.currentIndex,
    required this.navItems,
    required this.screens,
    required this.onItemTap,
    required this.authProvider,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Row(
        children: [
          // Sidebar navigation
          Container(
            width: 280,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                right: BorderSide(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                // Header avec logo
                Container(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Icon(
                        Icons.favorite,
                        size: 40,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        context.tr('app_name'),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Navigation items
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: navItems.length,
                    itemBuilder: (context, index) {
                      final item = navItems[index];
                      final isSelected = index == currentIndex;

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: ListTile(
                            selected: isSelected,
                            selectedTileColor:
                                theme.colorScheme.primary.withOpacity(0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            leading: Icon(
                              item.icon,
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : Colors.grey,
                            ),
                            title: Text(
                              item.label,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : Colors.grey.shade700,
                              ),
                            ),
                            onTap: () => onItemTap(index),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // User info at bottom
                if (authProvider.utilisateur != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: theme.colorScheme.primary,
                          child: Text(
                            authProvider.utilisateur!.nomUtilisateur
                                .substring(0, 1)
                                .toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                authProvider.utilisateur!.nomUtilisateur,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                authProvider.utilisateur!.email,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Main content area
          Expanded(
            child: Container(
              color: Colors.grey.shade50,
              child: screens[currentIndex],
            ),
          ),
        ],
      ),
    );
  }
}
