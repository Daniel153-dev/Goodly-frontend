import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../providers/publications_provider.dart';
import '../../../shared/widgets/publication_card.dart';
import 'create_publication_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../auth/providers/auth_provider.dart';
import '../../moderation/providers/moderation_provider.dart';
import '../../chat/screens/chat_list_screen.dart';
import '../../chat/services/chat_service.dart';
import '../../chat/models/conversation.dart';
import '../../../core/l10n/app_localizations.dart';

/// Écran du fil d'actualité (flux de publications)
class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();
  int _unreadCount = 0;
  int _pendingInvitationsCount = 0;
  bool _isLoadingNotifications = true;
  Timer? _chatNotificationTimer;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // S'inscrire comme observer du cycle de vie de l'app
    WidgetsBinding.instance.addObserver(this);
    // Charger le flux au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PublicationsProvider>(context, listen: false)
          .chargerFlux(refresh: true);
      _loadChatNotifications();
      
      // Démarrer le polling pour mettre à jour le badge chat toutes les 3 secondes
      _chatNotificationTimer = Timer.periodic(const Duration(seconds: 3), (_) {
        if (mounted) {
          _loadChatNotifications();
        }
      });
    });
  }

  Future<void> _loadChatNotifications() async {
    // Vérifier si le widget est toujours monté
    if (!mounted) return;
    
    try {
      final conversations = await _chatService.getConversations();
      final userId = _getCurrentUserId();
      
      int unread = 0;
      int pending = 0;
      
      print('[FEED] Chargement notifications: ${conversations.length} conversations, userId=$userId');
      
      for (final conv in conversations) {
        // Compter les messages non lus
        if (conv.unreadCount > 0) {
          print('[FEED] Conv ${conv.id}: unreadCount=${conv.unreadCount}');
          unread += conv.unreadCount;
        }
        
        // Compter les invitations reçues (statut = pending ET je ne suis pas l'expéditeur)
        if (conv.statut == 'pending') {
          final senderIdStr = conv.lastMessageSenderId?.toString().trim() ?? '';
          final userIdStr = userId?.toString().trim() ?? '';
          final isReceivedInvitation = senderIdStr.isNotEmpty && userIdStr.isNotEmpty && senderIdStr != userIdStr;
          
          if (isReceivedInvitation) {
            print('[FEED] Invitation reçue de=${senderIdStr}, me=$userIdStr');
            pending++;
          }
        }
      }
      
      if (mounted) {
        setState(() {
          _unreadCount = unread;
          _pendingInvitationsCount = pending;
          _isLoadingNotifications = false;
          print('[FEED] Badge update: unread=$unread, pending=$pending');
        });
      }
    } catch (e) {
      print('Erreur chargement notifications chat: $e');
      if (mounted) {
        setState(() => _isLoadingNotifications = false);
      }
    }
  }

  String _getCurrentUserId() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return authProvider.utilisateur?.idUtilisateur ?? '';
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _chatNotificationTimer?.cancel();
    // Se désinscrire de l'observer
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Detect when app comes back to foreground
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Recharger le flux quand l'app revient au premier plan
      if (mounted) {
        Provider.of<PublicationsProvider>(context, listen: false)
            .chargerFlux(refresh: true);
        _loadChatNotifications();
      }
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      // Charger plus de publications quand on approche de la fin
      final provider = Provider.of<PublicationsProvider>(context, listen: false);
      if (!provider.isLoading && !provider.isLoadingMore && provider.hasMoreData) {
        provider.chargerFlux();
      }
    }
  }

  Future<void> _handleInspiration(String publicationId) async {
    final provider = Provider.of<PublicationsProvider>(context, listen: false);

    // Trouver la publication pour connaître son état actuel
    final publication = provider.publications.firstWhere((p) => p.idPublication == publicationId);

    // Sauvegarder l'état ORIGINAL avant toute modification
    bool etatOriginal = publication.aInspire;
    bool nouvelleInspiration = !etatOriginal;

    // Mettre à jour l'état local du bouton (juste le flag, pas le compteur)
    provider.updateInspiredStateLocally(publicationId, nouvelleInspiration);

    bool success;
    if (etatOriginal) {
      // Retirer l'inspiration (car l'état original était déjà inspiré)
      success = await provider.retirerInspiration(publicationId);
    } else {
      // Ajouter l'inspiration (car l'état original n'était pas inspiré)
      success = await provider.ajouterInspiration(publicationId);
    }

    if (!success && mounted) {
      // Revenir en arrière en cas d'erreur (utiliser l'état original)
      provider.updateInspiredStateLocally(publicationId, etatOriginal);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? context.tr('inspiration_update_error')),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      provider.clearError();
    } else if (success && mounted) {
      // Recharger le flux pour mettre à jour les compteurs depuis l'API
      provider.chargerFlux(refresh: true);
    }
  }

  Future<void> _handleDelete(String publicationId) async {
    final provider = Provider.of<PublicationsProvider>(context, listen: false);

    final success = await provider.supprimerPublication(publicationId);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('publication_deleted_success')),
          backgroundColor: Colors.green,
        ),
      );
      // Recharger le flux
      provider.chargerFlux(refresh: true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? context.tr('delete_error')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleAdminDelete(String publicationId, String? raison) async {
    final moderationProvider = Provider.of<ModerationProvider>(context, listen: false);
    final publicationsProvider = Provider.of<PublicationsProvider>(context, listen: false);

    final success = await moderationProvider.supprimerPublication(publicationId, raison: raison);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('publication_deleted_admin')),
          backgroundColor: Colors.orange,
        ),
      );
      // Recharger le flux
      publicationsProvider.chargerFlux(refresh: true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(moderationProvider.errorMessage ?? context.tr('delete_error')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleVue(String publicationId) async {
    final provider = Provider.of<PublicationsProvider>(context, listen: false);
    await provider.enregistrerVue(publicationId);
    // Recharger pour mettre à jour les compteurs
    if (mounted) {
      provider.chargerFlux(refresh: true);
    }
  }

  Future<void> _handleCaptivant(String publicationId) async {
    final provider = Provider.of<PublicationsProvider>(context, listen: false);
    await provider.enregistrerCaptivant(publicationId);
    // Recharger pour mettre à jour les compteurs
    if (mounted) {
      provider.chargerFlux(refresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final publicationsProvider = Provider.of<PublicationsProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.utilisateur?.idUtilisateur;
    final isAdmin = authProvider.utilisateur?.role == 'administrateur';

    return Scaffold(
      appBar: AppBar(
        title: const Text('GOODLY'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          // Filtre par catégorie
          PopupMenuButton<String?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (categorie) {
              publicationsProvider.filtrerParCategorie(categorie);
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: null,
                child: Text(context.tr('all_categories')),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'environnement',
                child: Row(
                  children: [
                    const Text('🌱 ', style: TextStyle(fontSize: 18)),
                    Text(context.tr('category_environment')),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'social',
                child: Row(
                  children: [
                    const Text('🤝 ', style: TextStyle(fontSize: 18)),
                    Text(context.tr('category_social')),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'aide_animaliere',
                child: Row(
                  children: [
                    const Text('🐾 ', style: TextStyle(fontSize: 18)),
                    Text(context.tr('category_animal')),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'education',
                child: Row(
                  children: [
                    const Text('📚 ', style: TextStyle(fontSize: 18)),
                    Text(context.tr('category_education')),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'sante',
                child: Row(
                  children: [
                    const Text('💊 ', style: TextStyle(fontSize: 18)),
                    Text(context.tr('category_health')),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'autre',
                child: Row(
                  children: [
                    const Text('❤️ ', style: TextStyle(fontSize: 18)),
                    Text(context.tr('category_other')),
                  ],
                ),
              ),
            ],
          ),
          // Icône messages (chat) avec badge de notification
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.message),
                tooltip: context.tr('messages'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChatListScreen(),
                    ),
                  ).then((_) => _loadChatNotifications()); // Recharger après retour
                },
              ),
              // Badge rouge s'il y a des notifications
              if (_unreadCount > 0 || _pendingInvitationsCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      '${_unreadCount + _pendingInvitationsCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          // Icône paramètres
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: context.tr('settings'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => publicationsProvider.chargerFlux(refresh: true),
        child: publicationsProvider.isLoading &&
                publicationsProvider.publications.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : publicationsProvider.errorMessage != null && 
              publicationsProvider.errorMessage!.contains('402')
            ? _buildError402State()
            : publicationsProvider.publications.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
                controller: _scrollController,
                itemCount: publicationsProvider.publications.length +
                    (publicationsProvider.isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= publicationsProvider.publications.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final publication = publicationsProvider.publications[index];

                  return PublicationCard(
                    publication: publication,
                    isInspired: publication.aInspire,
                    onInspiration: _handleInspiration,
                    onDelete: _handleDelete,
                    onAdminDelete: isAdmin ? _handleAdminDelete : null,
                    onVue: _handleVue,
                    onCaptivant: _handleCaptivant,
                    currentUserId: currentUserId,
                    isAdmin: isAdmin,
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const CreatePublicationScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: Text(context.tr('publish')),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 100,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              context.tr('no_publications'),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('be_first_share'),
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const CreatePublicationScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: Text(context.tr('create_publication')),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError402State() {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 100,
              color: Colors.orange[400],
            ),
            const SizedBox(height: 24),
            Text(
              context.tr('data_load_error'),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('error_402_message'),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Provider.of<PublicationsProvider>(context, listen: false)
                    .chargerFlux(refresh: true);
              },
              icon: const Icon(Icons.refresh),
              label: Text(context.tr('retry')),
            ),
          ],
        ),
      ),
    );
  }
}
