/// Écran de conversation individuelle de chat
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/message.dart';
import '../services/chat_service.dart';
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

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String? recipientId;
  final String? recipientName;
  final bool isNewConversation;

  const ChatScreen({
    super.key,
    required this.conversationId,
    this.recipientId,
    this.recipientName,
    this.isNewConversation = false,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Message> _messages = [];
  
  // États de l'écran
  bool _isLoading = true;
  bool _isSending = false;
  String? _currentUserId;
  String _otherUserName;
  String _otherUserPhoto = '';
  bool _otherUserHasBlueBadge = false;
  
  // États de l'invitation
  bool _hasConversation = false;
  bool _isPendingInvitation = false;
  bool _isRecipient = false;
  bool _isSendingInvitation = false;

  _ChatScreenState() : _otherUserName = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addObserver(this);
    // Initialiser _otherUserName immédiatement avec la valeur du widget
    _otherUserName = widget.recipientName ?? '';
    _initializeChat();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && !_isLoading) {
      _checkConversation();
    }
  }

  Future<void> _initializeChat() async {
    try {
      await _getCurrentUserId();
      await _checkConversation();
    } catch (e) {
      print('Erreur lors de l\'initialisation: $e');
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getCurrentUserId() async {
    // Essayer d'abord avec le JWT token (plus fiable)
    final userIdFromToken = await _getUserIdFromToken();
    if (userIdFromToken != null) {
      setState(() {
        _currentUserId = userIdFromToken;
        if (_otherUserName.isEmpty) {
          _otherUserName = widget.recipientName ?? 'Utilisateur';
        }
      });
      print('[CHAT] CurrentUserId récupéré du JWT: $_currentUserId');
      return;
    }
    
    // Fallback sur SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final sessionJson = prefs.getString('current_session') ?? prefs.getString('user_session');
    if (sessionJson != null) {
      try {
        final session = json.decode(sessionJson);
        setState(() {
          // Essayer plusieurs clés possibles pour l'ID utilisateur
          _currentUserId = session['id_utilisateur']?.toString() 
                        ?? session['user_id']?.toString() 
                        ?? session['id']?.toString();
          if (_otherUserName.isEmpty) {
            _otherUserName = widget.recipientName ?? 'Utilisateur';
          }
        });
        print('[CHAT] CurrentUserId récupéré de la session: $_currentUserId');
      } catch (e) {
        print('Erreur parsing session: $e');
      }
    }
  }

  Future<void> _checkConversation() async {
    // Si c'est une nouvelle conversation, l'utilisateur doit envoyer une invitation
    if (widget.isNewConversation) {
      print('[CHAT] Nouvelle conversation - attente d\'envoi d\'invitation');
      setState(() {
        _hasConversation = false;
        _isPendingInvitation = false;
        _isSendingInvitation = true;
        _isRecipient = false;
      });
      return;
    }
    
    // Si c'est une conversation avec ID temporaire
    if (widget.conversationId.startsWith('temp_') || widget.conversationId.isEmpty) {
      print('[CHAT] Conversation ID temporaire - pas d\'invitation');
      setState(() {
        _hasConversation = false;
        _isPendingInvitation = false;
        _isSendingInvitation = true;
        _isRecipient = false;
      });
      return;
    }
    
    try {
      final conversation = await _chatService.getConversation(widget.conversationId);
      
      if (conversation != null) {
        print('[CHAT] Conversation trouvée: id=${conversation.id}, statut=${conversation.statut}');
        
        // Déterminer si l'utilisateur est le destinataire AVANT setState
        bool isRecipientValue = false;
        bool isPending = conversation.statut == 'pending';
        
        if (isPending) {
          String? currentUserId = _currentUserId;
          if (currentUserId == null) {
            // Essayer avec le JWT token d'abord
            currentUserId = await _getUserIdFromToken();
            
            // Fallback sur SharedPreferences
            if (currentUserId == null) {
              final prefs = await SharedPreferences.getInstance();
              final sessionJson = prefs.getString('current_session') ?? prefs.getString('user_session');
              if (sessionJson != null) {
                try {
                  final session = json.decode(sessionJson);
                  // Essayer plusieurs clés possibles pour l'ID utilisateur
                  currentUserId = session['id_utilisateur']?.toString() 
                               ?? session['user_id']?.toString() 
                               ?? session['id']?.toString();
                } catch (e) {
                  print('Erreur parsing session: $e');
                }
              }
            }
          }
          // Si j'ai envoyé l'invitation, je ne suis PAS le destinataire
          isRecipientValue = conversation.lastMessageSenderId != null && 
              currentUserId != null && 
              conversation.lastMessageSenderId != currentUserId;
          print('[CHAT] Invitation en attente, isRecipient=$isRecipientValue, sender=${conversation.lastMessageSenderId}, me=$currentUserId');
        } else {
          print('[CHAT] Invitation acceptée, affichage des messages');
        }
        
        setState(() {
          _hasConversation = true;
          _otherUserName = conversation.otherUserName ?? _otherUserName;
          _otherUserPhoto = conversation.otherUserPhoto ?? '';
          _otherUserHasBlueBadge = conversation.hasBlueBadge;
          _isSendingInvitation = false;
          _isPendingInvitation = isPending;
          _isRecipient = isRecipientValue;
        });
        
        print('[CHAT] États mis à jour: _hasConversation=$_hasConversation, _isPendingInvitation=$_isPendingInvitation, _isRecipient=$_isRecipient');
        
        if (!isPending) {
          // S'assurer que _currentUserId est défini avant de charger les messages
          if (_currentUserId == null) {
            final userIdFromToken = await _getUserIdFromToken();
            if (userIdFromToken != null) {
              setState(() => _currentUserId = userIdFromToken);
            }
          }
          await _loadMessages();
        }
        await _markAsRead();
      } else {
        print('[CHAT] Conversation non trouvée dans la base de données');
        setState(() {
          _hasConversation = false;
          _isPendingInvitation = false;
          _isSendingInvitation = true;
          _isRecipient = false;
        });
      }
    } catch (e) {
      print('Erreur lors de la vérification de la conversation: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _loadMessages() async {
    try {
      final messages = await _chatService.getMessages(widget.conversationId);
      if (mounted) {
        // Trier les messages par date (plus anciens en premier, plus récents en dernier)
        final sortedMessages = List<Message>.from(messages);
        sortedMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        
        setState(() {
          _messages.clear();
          _messages.addAll(sortedMessages);
          print('[CHAT] Charger ${_messages.length} messages, triés du plus ancien au plus récent');
          for (var i = 0; i < _messages.length; i++) {
            final msg = _messages[i];
            final isMeMsg = msg.senderId.toString().trim() == _currentUserId?.toString().trim();
            print('[CHAT] Message $i: senderId=${msg.senderId}, isMeMsg=$isMeMsg, _currentUserId=$_currentUserId');
          }
        });
        Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
      }
    } catch (e) {
      print('Erreur lors du chargement des messages: $e');
    }
  }
  
  Future<void> _markAsRead() async {
    try {
      await _chatService.markAsRead(widget.conversationId);
    } catch (e) {
      print('Erreur lors du marquage comme lu: $e');
    }
  }
  
  void _scrollToBottom() {
    try {
      if (_scrollController.hasClients && _messages.isNotEmpty) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
        print('[CHAT] Scroll to bottom - maxExtent=${_scrollController.position.maxScrollExtent}');
      }
    } catch (e) {
      print('[CHAT] Erreur scroll to bottom: $e');
    }
  }
  
  Future<void> _sendMessage() async {
    print('[CHAT DEBUG] _sendMessage appelé');
    print('[CHAT DEBUG] _messageController.text = "${_messageController.text}"');
    print('[CHAT DEBUG] _isPendingInvitation = $_isPendingInvitation');
    print('[CHAT DEBUG] _isSending = $_isSending');
    print('[CHAT DEBUG] _isSendingInvitation = $_isSendingInvitation');
    print('[CHAT DEBUG] _hasConversation = $_hasConversation');
    print('[CHAT DEBUG] conversationId = ${widget.conversationId}');
    
    // Vérifier si on est en mode invitation
    if (_isSendingInvitation || !_hasConversation) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('send_invitation_first'))),
      );
      return;
    }
    
    if (_messageController.text.trim().isEmpty) {
      print('[CHAT DEBUG] Message vide, envoi annulé');
      return;
    }
    
    if (_isPendingInvitation) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('wait_invitation_accept'))),
      );
      return;
    }
    
    final messageText = _messageController.text.trim();
    print('[CHAT DEBUG] Envoi du message: "$messageText"');
    setState(() => _isSending = true);
    
    try {
      print('[CHAT DEBUG] Appel de _chatService.sendMessage...');
      final success = await _chatService.sendMessage(
        widget.conversationId,
        messageText,
      );
      
      print('[CHAT DEBUG] sendMessage result = $success');
      if (success) {
        _messageController.clear();
        // Recharger les messages avec un délai pour s'assurer que le backend a bien enregistré
        await Future.delayed(const Duration(milliseconds: 500));
        await _loadMessages();
        print('[CHAT DEBUG] Message envoyé avec succès');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('message_send_error'))),
        );
      }
    } catch (e) {
      print('Erreur lors de l\'envoi du message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${context.tr('error')}: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }
  
  Future<void> _sendInvitation() async {
    if (widget.recipientId == null || widget.recipientId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('cannot_send_invitation'))),
      );
      return;
    }
    
    setState(() => _isSending = true);
    
    try {
      // Pour une nouvelle conversation, on crée la conversation (qui envoie l'invitation)
      final result = await _chatService.createConversation(widget.recipientId!);
      
      if (result != null) {
        print('[CHAT] Invitation envoyée avec succès: ${result.id}');
        // Recharger l'état de la conversation pour mettre à jour l'UI
        // N'utilise PAS Navigator.pop() - l'invitation doit rester visible
        await _checkConversation();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('invitation_sent_success'))),
        );
        print('[CHAT] Invitation UI devrait rester visible avec _isPendingInvitation=true');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('invitation_send_error'))),
        );
      }
    } catch (e) {
      print('Erreur lors de l\'envoi de l\'invitation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${context.tr('error')}: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }
  
  Future<void> _acceptInvitation() async {
    setState(() => _isSending = true);
    
    try {
      final success = await _chatService.acceptInvitation(widget.conversationId);
      
      if (success) {
        print('[CHAT] Invitation acceptée');
        await _checkConversation();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('invitation_accepted'))),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('invitation_accept_error'))),
        );
      }
    } catch (e) {
      print('Erreur lors de l\'acceptation de l\'invitation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${context.tr('error')}: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }
  
  Future<void> _rejectInvitation() async {
    setState(() => _isSending = true);
    
    try {
      final success = await _chatService.rejectInvitation(widget.conversationId);
      
      if (success) {
        print('[CHAT] Invitation rejetée');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('invitation_rejected'))),
        );
        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('invitation_reject_error'))),
        );
      }
    } catch (e) {
      print('Erreur lors du rejet de l\'invitation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${context.tr('error')}: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance!.removeObserver(this);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    print("[CHAT] _formatTime appelé pour $dateTime"); // LOG TEMPORAIRE
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

  @override
  Widget build(BuildContext context) {
    print("[CHAT ULTRA-IMPORTANT] build() appelé - conversationId=${widget.conversationId}");
    final Map<String, List<Message>> messagesByDate = {};
    for (final message in _messages) {
      if (message.createdAt != null) {
        final dateKey = DateFormat('yyyy-MM-dd').format(message.createdAt!);
        if (!messagesByDate.containsKey(dateKey)) {
          messagesByDate[dateKey] = [];
        }
        messagesByDate[dateKey]!.add(message);
      }
    }
    
    // DEBUG
    print('[CHAT BUILD] _isPendingInvitation=$_isPendingInvitation, _isRecipient=$_isRecipient, _isSendingInvitation=$_isSendingInvitation, _hasConversation=$_hasConversation');
    print('[CHAT BUILD] _otherUserName=$_otherUserName');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Row(
          children: [
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.2),
                  ),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 18,
                      backgroundImage: _otherUserPhoto.isNotEmpty
                          ? CachedNetworkImageProvider(_getProfilePhotoUrl(_otherUserPhoto))
                          : null,
                      child: _otherUserPhoto.isEmpty
                          ? Icon(Icons.person, size: 20, color: Colors.grey[400])
                          : null,
                    ),
                  ),
                ),
                if (_otherUserHasBlueBadge)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Image.asset(
                      'assets/images/badge_bleu.png',
                      width: 16,
                      height: 16,
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _otherUserName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_isPendingInvitation && _isRecipient)
                    Text(
                      context.tr('invitation_received'),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.green[700]))
          : Column(
              children: [
                // VRAI indicateur d'invitation (sera affiché si les conditions sont remplies)
                if (_isPendingInvitation && _hasConversation)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    color: _isRecipient ? Colors.orange[50] : Colors.blue[50],
                    child: Row(
                      children: [
                        Icon(
                          _isRecipient ? Icons.mail : Icons.send,
                          color: _isRecipient ? Colors.orange : Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _isRecipient
                                ? context.trParams('user_sent_invitation', {'user': _otherUserName})
                                : context.trParams('you_sent_invitation', {'user': _otherUserName}),
                            style: TextStyle(
                              color: _isRecipient ? Colors.orange[800] : Colors.blue[800],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Zone de messages ou d'invitation
                Expanded(
                  child: _isSendingInvitation
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.mail_outline,
                                  size: 64,
                                  color: Colors.green[700],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  context.tr('send_invitation_title'),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  context.trParams('user_must_accept_invitation', {'user': _otherUserName}),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton.icon(
                                    onPressed: _isSending ? null : _sendInvitation,
                                    icon: _isSending
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : const Icon(Icons.send),
                                    label: Text(context.tr('send_invitation')),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green[700],
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : _isPendingInvitation && _isRecipient
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.mail_outline,
                                      size: 64,
                                      color: Colors.orange[700],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      context.trParams('user_sent_invitation', {'user': _otherUserName}),
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 24),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 50,
                                      child: ElevatedButton.icon(
                                        onPressed: _isSending ? null : _acceptInvitation,
                                        icon: _isSending
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(strokeWidth: 2),
                                              )
                                            : const Icon(Icons.check),
                                        label: Text(context.tr('accept')),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 50,
                                      child: ElevatedButton.icon(
                                        onPressed: _isSending ? null : _rejectInvitation,
                                        icon: _isSending
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(strokeWidth: 2),
                                              )
                                            : const Icon(Icons.close),
                                        label: Text(context.tr('decline')),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.grey[200],
                                          foregroundColor: Colors.black,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : _isPendingInvitation && !_isRecipient
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(32.0),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.hourglass_empty,
                                          size: 64,
                                          color: Colors.blue[700],
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          context.trParams('invitation_sent_to', {'user': _otherUserName}),
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          context.trParams('wait_user_accept', {'user': _otherUserName}),
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : Stack(
                                  children: [
                                    ListView.builder(
                                      controller: _scrollController,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      itemCount: _messages.length,
                                      itemBuilder: (context, index) {
                                        final message = _messages[index];
                                        final senderIdStr = message.senderId.toString().trim();
                                        final currentUserIdStr = _currentUserId?.toString().trim() ?? '';
                                        final isMe = senderIdStr.isNotEmpty && currentUserIdStr.isNotEmpty && senderIdStr == currentUserIdStr;
                                        
                                        if (index == 0 || index == _messages.length - 1) {
                                          print('[CHAT MSG] idx=$index: senderId="$senderIdStr" vs current="$currentUserIdStr" -> isMe=$isMe');
                                        }
                                        
                                        final showDate = index == 0 ||
                                            _messages[index - 1].createdAt == null ||
                                            DateFormat('yyyy-MM-dd').format(message.createdAt!) !=
                                                DateFormat('yyyy-MM-dd').format(_messages[index - 1].createdAt!);
                                        
                                        return SizedBox(
                                          width: double.infinity,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              if (showDate && message.createdAt != null)
                                                Center(
                                                  child: Container(
                                                    margin: const EdgeInsets.symmetric(vertical: 16),
                                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey[200],
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: Text(
                                                      DateFormat('d MMMM yyyy', 'fr_FR').format(message.createdAt!),
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              Align(
                                                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                                                child: Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                                  child: MessageBubble(
                                                    message: message,
                                                    isMe: isMe,
                                                    time: _formatTime(message.createdAt),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                    if (_messages.isNotEmpty)
                                      Positioned(
                                        bottom: 16,
                                        left: 16,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.lock,
                                                size: 12,
                                                color: Colors.grey[600],
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                context.tr('messages_encrypted'),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                ),
                
                // Zone de saisie de message
                if (!_isPendingInvitation || !_isRecipient)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        top: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    child: SafeArea(
                      top: false,
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              enabled: _hasConversation && !_isSendingInvitation,
                              controller: _messageController,
                              decoration: InputDecoration(
                                hintText: _isSendingInvitation ? context.tr('send_invitation_first_hint') : context.tr('message_hint'),
                                hintStyle: TextStyle(color: Colors.grey[500]),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.grey[100],
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                              maxLines: null,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _sendMessage(),
                              onChanged: (value) {
                                setState(() {});
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          FloatingActionButton(
                            heroTag: 'send_message',
                            onPressed: (_messageController.text.trim().isEmpty || _isSending || _isSendingInvitation || !_hasConversation) ? null : _sendMessage,
                            backgroundColor: (_messageController.text.trim().isEmpty || _isSending || _isSendingInvitation || !_hasConversation) ? Colors.grey[300] : Colors.green[700],
                            mini: true,
                            child: Icon(
                              _isSending ? Icons.hourglass_empty : Icons.send,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
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

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final String time;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isMe ? Colors.green[700] : Colors.grey[200],
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isMe ? 16 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 16),
        ),
      ),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            message.content,
            style: TextStyle(
              color: isMe ? Colors.white : Colors.black,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                time,
                style: TextStyle(
                  color: isMe ? Colors.white70 : Colors.grey[600],
                  fontSize: 11,
                ),
              ),
              if (isMe)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Icon(
                    message.readAt != null ? Icons.done_all : Icons.done,
                    size: 14,
                    color: message.readAt != null ? Colors.blue[300] : Colors.white70,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
