/// Écran de liste des conversations de chat
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/conversation.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';
import '../../../features/profile/screens/user_profile_screen.dart';
import '../../../core/api/api_constants.dart';
import '../../../core/l10n/app_localizations.dart';

/// Extrait le user ID du JWT token
Future<String?> _getUserIdFromToken() async {
  final secureStorage = const FlutterSecureStorage();
  final prefs = await SharedPreferences.getInstance();
  
  // Essayer FlutterSecureStorage d'abord
  String? token = await secureStorage.read(key: 'access_token');
  
  // Fallback sur SharedPreferences
  if (token == null) {
    token = prefs.getString('access_token') ?? prefs.getString('auth_token') ?? prefs.getString('token');
  }
  
  if (token == null || token.isEmpty) return null;
  
  try {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    
    final payload = utf8.decode(base64Url.decode(parts[1]));
    final Map<String, dynamic> json = jsonDecode(payload);
    return json['sub']?.toString();
  } catch (e) {
    print('Erreur parsing JWT: $e');
    return null;
  }
}

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  final ChatService _chatService = ChatService();
  List<Conversation> _conversations = [];
  List<Conversation> _pendingInvitationsReceived = [];
  List<Conversation> _pendingInvitationsSent = [];
  bool _isLoading = true;
  String? _currentUserId;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance!.addObserver(this);
    _initializeChat();
  }

  @override
  void dispose() {
    _tabController.dispose();
    WidgetsBinding.instance!.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && !_isLoading) {
      print('[CHAT LIST] App resumed, refreshing conversations');
      _loadConversations();
    }
  }

  Future<void> _initializeChat() async {
    await _getCurrentUserId();
    await _loadConversations();
  }

  Future<void> _getCurrentUserId() async {
    print('[CHAT LIST] === Début de _getCurrentUserId ===');
    
    // Essayer le JWT d'abord
    final userIdFromToken = await _getUserIdFromToken();
    print('[CHAT LIST] userIdFromToken: $userIdFromToken');
    if (userIdFromToken != null) {
      setState(() {
        _currentUserId = userIdFromToken;
        print('[CHAT LIST] ✓ _currentUserId récupéré du JWT: $_currentUserId');
      });
      return;
    }
    
    // Fallback sur SharedPreferences - Essayer TOUS les clés possibles
    final prefs = await SharedPreferences.getInstance();
    print('[CHAT LIST] Keys in SharedPreferences: ${prefs.getKeys()}');
    
    // Essayer toutes les clés possibles
    String? userId;
    for (final key in ['current_session', 'user_session', 'user_id', 'userId', 'current_user_id']) {
      final value = prefs.getString(key);
      print('[CHAT LIST] Checking key "$key": $value');
      if (value != null && value.isNotEmpty) {
        // Vérifier si c'est un JSON
        if (value.startsWith('{')) {
          try {
            final session = json.decode(value);
            // Essayer plusieurs clés possibles pour l'ID
            userId = session['id_utilisateur']?.toString() 
                  ?? session['user_id']?.toString() 
                  ?? session['id']?.toString();
            print('[CHAT LIST] ✓ Parsed user_id from JSON in "$key": $userId');
          } catch (e) {
            print('[CHAT LIST] ✗ Erreur parsing JSON in "$key": $e');
          }
        } else {
          userId = value;
          print('[CHAT LIST] ✓ Found user_id in key "$key": $userId');
        }
        if (userId != null) break;
      }
    }
    
    if (userId != null && userId.isNotEmpty) {
      setState(() {
        _currentUserId = userId;
        print('[CHAT LIST] ✓ _currentUserId défini: $_currentUserId');
      });
    } else {
      print('[CHAT LIST] ✗ Impossible de trouver un user_id valide!');
    }
  }

  Future<void> _loadConversations() async {
    setState(() => _isLoading = true);
    final conversations = await _chatService.getConversations();
    if (mounted) {
      setState(() {
        print('[CHAT LIST] Nombre de conversations: ${conversations.length}');
        
        _conversations = conversations.where((c) => c.statut == 'accepted').toList();
        print('[CHAT LIST] Conversations acceptées: ${_conversations.length}');
        
        _pendingInvitationsReceived = conversations.where((c) {
          final isPending = c.statut == 'pending';
          final senderIsNotMe = _currentUserId != null && c.lastMessageSenderId != _currentUserId;
          print('[CHAT LIST] Invitation reçue? statut=${c.statut}, sender=${c.lastMessageSenderId}, me=$_currentUserId, isPending=$isPending, senderIsNotMe=$senderIsNotMe');
          return isPending && senderIsNotMe;
        }).toList();
        
        _pendingInvitationsSent = conversations.where((c) {
          final isPending = c.statut == 'pending';
          final senderIsMe = _currentUserId != null && c.lastMessageSenderId == _currentUserId;
          print('[CHAT LIST] Invitation envoyée? statut=${c.statut}, sender=${c.lastMessageSenderId}, me=$_currentUserId, isPending=$isPending, senderIsMe=$senderIsMe');
          return isPending && senderIsMe;
        }).toList();
        
        print('[CHAT LIST] Invitations reçues: ${_pendingInvitationsReceived.length}');
        print('[CHAT LIST] Invitations envoyées: ${_pendingInvitationsSent.length}');
        
        _isLoading = false;
      });
    }
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDay = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDay == today) {
      return DateFormat('HH:mm').format(dateTime);
    } else if (messageDay == today.subtract(const Duration(days: 1))) {
      return context.tr('yesterday');
    } else {
      return DateFormat('dd/MM').format(dateTime);
    }
  }

  void _navigateToProfile(String userId) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => 
            UserProfileScreen(userId: userId),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  Future<void> _deleteConversation(Conversation conversation) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('delete_conversation')),
        content: Text(context.tr('delete_conversation_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(context.tr('delete')),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _chatService.deleteConversation(conversation.id);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.tr('conversation_deleted'))),
          );
          _loadConversations();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.tr('delete_error'))),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPending = _pendingInvitationsReceived.length + _pendingInvitationsSent.length;
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            Text(
              'GOODLY',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.green[700],
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: Colors.green[700],
          indicatorWeight: 3,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.chat_bubble),
                  const SizedBox(width: 8),
                  Text(context.tr('messages')),
                  if (_conversations.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green[700],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _conversations.length.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.mail),
                  const SizedBox(width: 8),
                  Text(context.tr('invitations')),
                  if (totalPending > 0)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        totalPending.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: Colors.green[700]),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                // Onglet Messages
                _buildMessagesTab(),
                // Onglet Invitations
                _buildInvitationsTab(),
              ],
            ),
    );
  }

  Widget _buildMessagesTab() {
    if (_conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              context.tr('no_conversation'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('start_conversation'),
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadConversations,
      color: Colors.green[700],
      child: ListView.builder(
        itemCount: _conversations.length,
        itemBuilder: (context, index) => Dismissible(
          key: Key(_conversations[index].id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            color: Colors.red,
            child: const Icon(
              Icons.delete,
              color: Colors.white,
              size: 28,
            ),
          ),
          onDismissed: (direction) => _deleteConversation(_conversations[index]),
          child: _buildConversationTile(_conversations[index]),
        ),
      ),
    );
  }

  Widget _buildInvitationsTab() {
    if (_pendingInvitationsReceived.isEmpty && _pendingInvitationsSent.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mail_outline,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              context.tr('no_invitation'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('no_pending_invitation'),
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadConversations,
      color: Colors.green[700],
      child: ListView(
        children: [
          // Invitations reçues
          if (_pendingInvitationsReceived.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.inbox, color: Colors.orange[700], size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '${context.tr('invitations_received')} (${_pendingInvitationsReceived.length})',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[800],
                    ),
                  ),
                ],
              ),
            ),
            ..._pendingInvitationsReceived.map((conv) => 
              _buildPendingInvitationTile(conv, isReceived: true)
            ),
            const SizedBox(height: 16),
          ],
          // Invitations envoyées
          if (_pendingInvitationsSent.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.send, color: Colors.blue[700], size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '${context.tr('invitations_sent')} (${_pendingInvitationsSent.length})',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                ],
              ),
            ),
            ..._pendingInvitationsSent.map((conv) => 
              _buildPendingInvitationTile(conv, isReceived: false)
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConversationTile(Conversation conversation) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                conversationId: conversation.id,
                recipientId: conversation.otherUserId,
                recipientName: conversation.otherUserName,
              ),
            ),
          ).then((_) => _loadConversations());
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.grey[200]!),
            ),
            color: Colors.white,
          ),
          child: Row(
            children: [
              // Avatar avec système hybride
              GestureDetector(
                onTap: () => _navigateToProfile(conversation.otherUserId ?? ''),
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.2),
                      ),
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          radius: 27,
                          backgroundImage: conversation.otherUserPhoto != null && conversation.otherUserPhoto!.isNotEmpty
                              ? CachedNetworkImageProvider(_getProfilePhotoUrl(conversation.otherUserPhoto))
                              : null,
                          child: conversation.otherUserPhoto == null || conversation.otherUserPhoto!.isEmpty
                              ? Icon(Icons.person, size: 32, color: Colors.grey[400])
                              : null,
                        ),
                      ),
                    ),
                    if (conversation.hasBlueBadge)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Image.asset(
                          'assets/images/badge_bleu.png',
                          width: 24,
                          height: 24,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Contenu
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          conversation.otherUserName ?? context.tr('user'),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          _formatTime(conversation.lastMessageAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: conversation.unreadCount > 0
                                ? Colors.green[700]
                                : Colors.grey[500],
                            fontWeight: conversation.unreadCount > 0
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.lastMessage ?? context.tr('no_message'),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: conversation.unreadCount > 0
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (conversation.unreadCount > 0)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green[700],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              conversation.unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPendingInvitationTile(Conversation conversation, {required bool isReceived}) {
    // Debug: afficher les valeurs de la conversation
    print('[CHAT LIST] _buildPendingInvitationTile: id=${conversation.id}, otherUserName=${conversation.otherUserName}, otherUserPhoto=${conversation.otherUserPhoto}, otherUserId=${conversation.otherUserId}');
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                conversationId: conversation.id,
                recipientId: conversation.otherUserId,
                recipientName: conversation.otherUserName,
              ),
            ),
          ).then((_) => _loadConversations());
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.grey[200]!),
            ),
            color: isReceived ? Colors.orange[50] : Colors.blue[50],
          ),
          child: Row(
            children: [
              // Avatar
              GestureDetector(
                onTap: () => _navigateToProfile(conversation.otherUserId ?? ''),
                child: Stack(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isReceived ? Colors.orange[100] : Colors.blue[100],
                        image: conversation.otherUserPhoto != null && conversation.otherUserPhoto!.isNotEmpty
                            ? DecorationImage(
                                image: CachedNetworkImageProvider(conversation.otherUserPhoto!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: conversation.otherUserPhoto == null || conversation.otherUserPhoto!.isEmpty
                          ? Icon(
                              Icons.person,
                              color: isReceived ? Colors.orange[700] : Colors.blue[700],
                              size: 32,
                            )
                          : null,
                    ),
                    if (conversation.hasBlueBadge)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.verified,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Contenu
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          conversation.otherUserName ?? context.tr('user'),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Icon(
                          isReceived ? Icons.mail : Icons.hourglass_empty,
                          color: isReceived ? Colors.orange[700] : Colors.blue[700],
                          size: 16,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (isReceived) ...[
                      Text(
                        conversation.invitationMessage ?? context.tr('sent_invitation'),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton(
                            onPressed: () => _acceptInvitation(conversation),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[700],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: Text(context.tr('accept'), style: const TextStyle(fontSize: 12)),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: () => _declineInvitation(conversation),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red[700],
                              side: BorderSide(color: Colors.red[700]!),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: Text(context.tr('decline'), style: const TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ] else ...[
                      Text(
                        context.tr('waiting_response'),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _acceptInvitation(Conversation conversation) async {
    try {
      await _chatService.acceptInvitation(conversation.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('invitation_accepted'))),
        );
        await _loadConversations();
        // Aller directement aux messages
        _tabController.animateTo(0);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.tr('error')}: $e')),
        );
      }
    }
  }

  Future<void> _declineInvitation(Conversation conversation) async {
    try {
      await _chatService.rejectInvitation(conversation.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('invitation_declined'))),
        );
        _loadConversations();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.tr('error')}: $e')),
        );
      }
    }
  }

  String _getProfilePhotoUrl(String? photoUrl) {
    if (photoUrl == null || photoUrl.isEmpty) return '';
    if (photoUrl.startsWith('http://') || photoUrl.startsWith('https://')) {
      return photoUrl;
    }
    String normalizedUrl = photoUrl.replaceAll('\\', '/');
    if (!normalizedUrl.startsWith('/')) {
      normalizedUrl = '/$normalizedUrl';
    }
    return '${ApiConstants.baseUrl}$normalizedUrl';
  }
}

