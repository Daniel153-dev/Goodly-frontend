/// Service de chat pour la communication avec le backend
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../../../core/api/api_constants.dart';

/// Timeout global pour toutes les requêtes HTTP (15 secondes)
const Duration _kHttpTimeout = Duration(seconds: 15);

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  String? _authToken;
  StreamSubscription? _webSocketSubscription;
  final _messagesStreamController = StreamController<Map<String, dynamic>>.broadcast();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  /// Client HTTP avec timeout strict
  /// IMPORTANT: Toujours utiliser _getClient() pour les requêtes
  http.Client? _client;

  Stream<Map<String, dynamic>> get messagesStream => _messagesStreamController.stream;

  /// Retourne un client HTTP configuré avec timeout
  http.Client _getClient() {
    _client ??= http.Client();
    return _client!;
  }

  /// Recrée le client HTTP (sans fermer complètement)
  void _resetClient() {
    _client = null;
  }

  /// Ferme le client HTTP proprement
  void _closeClient() {
    if (_client != null) {
      _client!.close();
      _client = null;
      print('[CHAT] Client HTTP fermé avec succès');
    }
  }

  Future<void> _getToken() async {
    // Essayer d'abord FlutterSecureStorage (utilisé par auth_service)
    _authToken = await _secureStorage.read(key: 'access_token');
    
    // Fallback sur SharedPreferences pour compatibilité
    if (_authToken == null) {
      final prefs = await SharedPreferences.getInstance();
      _authToken = prefs.getString('access_token') ?? prefs.getString('auth_token') ?? prefs.getString('token');
    }
  }

  Future<List<Conversation>> getConversations() async {
    await _getToken();
    if (_authToken == null) return [];

    try {
      final client = _getClient();
      final response = await client.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.chatConversations}'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
          'Connection': 'close', // Force la fermeture de la connexion
        },
      ).timeout(_kHttpTimeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('[CHAT SERVICE] getConversations response: $data');
        for (var item in data) {
          print('[CHAT SERVICE] Conversation: id=${item['id']}, other_user_name=${item['other_user_name']}, other_user_photo=${item['other_user_photo']}, statut=${item['statut']}');
        }
        return data.map((e) => Conversation.fromJson(e)).toList();
      }
      return [];
    } on TimeoutException catch (e) {
      print('Timeout getConversations: $e');
      _resetClient(); // Recréer le client sans fermer
      return [];
    } catch (e) {
      print('Erreur getConversations: $e');
      return [];
    }
  }

  Future<Conversation?> createConversation(String recipientId, {String? initialMessage}) async {
    await _getToken();
    if (_authToken == null) return null;

    try {
      final client = _getClient();
      final response = await client.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.chatConversations}'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
          'Connection': 'close',
        },
        body: json.encode({
          'recipient_id': recipientId,
          'initial_message': initialMessage,
        }),
      ).timeout(_kHttpTimeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Conversation.fromJson(json.decode(response.body));
      }
      return null;
    } on TimeoutException catch (e) {
      print('Timeout createConversation: $e');
      _resetClient();
      return null;
    } catch (e) {
      print('Erreur createConversation: $e');
      return null;
    }
  }

  Future<List<Message>> getMessages(String conversationId, {int limit = 50, String? before}) async {
    await _getToken();
    if (_authToken == null) return [];

    try {
      final queryParams = {'limit': limit.toString()};
      if (before != null) queryParams['before'] = before;

      final client = _getClient();
      final response = await client.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.chatConversationMessages(conversationId)}?${Uri(queryParameters: queryParams).query}'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
          'Connection': 'close',
        },
      ).timeout(_kHttpTimeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((e) => Message.fromJson(e)).toList();
      }
      return [];
    } on TimeoutException catch (e) {
      print('Timeout getMessages: $e');
      _resetClient();
      return [];
    } catch (e) {
      print('Erreur getMessages: $e');
      return [];
    }
  }

  Future<bool> sendMessage(String conversationId, String content) async {
    await _getToken();
    if (_authToken == null) {
      print('[CHAT SERVICE] sendMessage: Token null!');
      return false;
    }

    try {
      print('[CHAT SERVICE] sendMessage: conversationId=$conversationId, content=$content');
      final client = _getClient();
      final url = '${ApiConstants.baseUrl}${ApiConstants.chatConversationMessages(conversationId)}';
      print('[CHAT SERVICE] sendMessage: URL=$url');
      final response = await client.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
          'Connection': 'close',
        },
        body: json.encode({
          'content': content,
          'message_type': 'text',
        }),
      ).timeout(_kHttpTimeout);

      print('[CHAT SERVICE] sendMessage: response.statusCode=${response.statusCode}');
      print('[CHAT SERVICE] sendMessage: response.body=${response.body}');
      return response.statusCode == 200 || response.statusCode == 201;
    } on TimeoutException catch (e) {
      print('Timeout sendMessage: $e');
      _resetClient();
      return false;
    } catch (e) {
      print('Erreur sendMessage: $e');
      return false;
    }
  }

  Future<bool> markAsRead(String conversationId) async {
    await _getToken();
    if (_authToken == null) return false;

    try {
      final client = _getClient();
      final response = await client.put(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.chatConversation(conversationId)}/read'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
          'Connection': 'close',
        },
      ).timeout(_kHttpTimeout);

      return response.statusCode == 200;
    } on TimeoutException catch (e) {
      print('Timeout markAsRead: $e');
      _resetClient();
      return false;
    } catch (e) {
      print('Erreur markAsRead: $e');
      return false;
    }
  }

  Future<bool> deleteMessage(String conversationId, String messageId) async {
    await _getToken();
    if (_authToken == null) return false;

    try {
      final client = _getClient();
      final response = await client.delete(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.chatConversationMessages(conversationId)}/$messageId'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
          'Connection': 'close',
        },
      ).timeout(_kHttpTimeout);

      return response.statusCode == 200;
    } on TimeoutException catch (e) {
      print('Timeout deleteMessage: $e');
      _resetClient();
      return false;
    } catch (e) {
      print('Erreur deleteMessage: $e');
      return false;
    }
  }

  void dispose() {
    _webSocketSubscription?.cancel();
    _messagesStreamController.close();
    // Ne pas fermer le client - il sera recréé automatiquement
  }

  Future<Conversation?> getConversation(String conversationId) async {
    await _getToken();
    if (_authToken == null) return null;

    try {
      final client = _getClient();
      final response = await client.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.chatConversation(conversationId)}'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
          'Connection': 'close',
        },
      ).timeout(_kHttpTimeout);

      if (response.statusCode == 200) {
        return Conversation.fromJson(json.decode(response.body));
      }
      return null;
    } on TimeoutException catch (e) {
      print('Timeout getConversation: $e');
      _resetClient();
      return null;
    } catch (e) {
      print('Erreur getConversation: $e');
      return null;
    }
  }

  Future<bool> acceptInvitation(String conversationId) async {
    await _getToken();
    if (_authToken == null) return false;

    try {
      final client = _getClient();
      final response = await client.put(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.chatConversationAccept(conversationId)}'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
          'Connection': 'close',
        },
      ).timeout(_kHttpTimeout);

      return response.statusCode == 200;
    } on TimeoutException catch (e) {
      print('Timeout acceptInvitation: $e');
      _resetClient();
      return false;
    } catch (e) {
      print('Erreur acceptInvitation: $e');
      return false;
    }
  }

  Future<bool> rejectInvitation(String conversationId) async {
    await _getToken();
    if (_authToken == null) return false;

    try {
      final client = _getClient();
      final response = await client.put(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.chatConversationReject(conversationId)}'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
          'Connection': 'close',
        },
      ).timeout(_kHttpTimeout);

      return response.statusCode == 200;
    } on TimeoutException catch (e) {
      print('Timeout rejectInvitation: $e');
      _resetClient();
      return false;
    } catch (e) {
      print('Erreur rejectInvitation: $e');
      return false;
    }
  }

  Future<bool> sendInvitation(String conversationId, String recipientId, String message) async {
    await _getToken();
    if (_authToken == null) {
      print('Erreur sendInvitation: Token d\'authentification manquant');
      return false;
    }

    try {
      final client = _getClient();
      final response = await client.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.chatConversationInvitation(conversationId)}'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
          'Connection': 'close',
        },
        body: json.encode({
          'recipient_id': recipientId,
          'message': message,
        }),
      ).timeout(_kHttpTimeout);

      print('sendInvitation response: ${response.statusCode} - ${response.body}');
      return response.statusCode == 200 || response.statusCode == 201;
    } on TimeoutException catch (e) {
      print('Timeout sendInvitation: $e');
      _resetClient();
      return false;
    } catch (e) {
      print('Erreur sendInvitation: $e');
      return false;
    }
  }

  Future<bool> deleteConversation(String conversationId) async {
    await _getToken();
    if (_authToken == null) return false;

    try {
      final client = _getClient();
      final response = await client.delete(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.chatConversationDelete(conversationId)}'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
          'Connection': 'close',
        },
      ).timeout(_kHttpTimeout);

      return response.statusCode == 200;
    } on TimeoutException catch (e) {
      print('Timeout deleteConversation: $e');
      _resetClient();
      return false;
    } catch (e) {
      print('Erreur deleteConversation: $e');
      return false;
    }
  }
}
