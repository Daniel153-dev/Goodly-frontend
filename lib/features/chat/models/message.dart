/// Modèle pour un message de chat
class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final String contentHash;
  final String messageType;
  final DateTime createdAt;
  final DateTime? readAt;
  final bool isDeleted;
  final bool isEdited;
  final String status;
  final bool isFromMe;

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.contentHash,
    required this.messageType,
    required this.createdAt,
    this.readAt,
    this.isDeleted = false,
    this.isEdited = false,
    this.status = 'sent',
    required this.isFromMe,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    final currentUserId = _getCurrentUserId();
    return Message(
      id: json['id']?.toString() ?? '',
      conversationId: json['conversation_id']?.toString() ?? '',
      senderId: json['sender_id']?.toString() ?? '',
      content: json['content'] ?? '',
      contentHash: json['content_hash'] ?? '',
      messageType: json['message_type'] ?? 'text',
      createdAt: DateTime.tryParse(json['created_at'] ?? DateTime.now().toIso8601String()) ?? DateTime.now(),
      readAt: json['read_at'] != null ? DateTime.tryParse(json['read_at']) : null,
      isDeleted: json['is_deleted'] ?? false,
      isEdited: json['is_edited'] ?? false,
      status: json['status'] ?? 'sent',
      isFromMe: json['sender_id']?.toString() == currentUserId,
    );
  }

  static String _getCurrentUserId() {
    // Récupérer l'ID de l'utilisateur actuel depuis le storage
    // Cette méthode sera implémentée dans le provider
    return '';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'content': content,
      'content_hash': contentHash,
      'message_type': messageType,
      'created_at': createdAt.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
      'is_deleted': isDeleted,
      'is_edited': isEdited,
      'status': status,
    };
  }

  Message copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? content,
    String? contentHash,
    String? messageType,
    DateTime? createdAt,
    DateTime? readAt,
    bool? isDeleted,
    bool? isEdited,
    String? status,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      contentHash: contentHash ?? this.contentHash,
      messageType: messageType ?? this.messageType,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      isDeleted: isDeleted ?? this.isDeleted,
      isEdited: isEdited ?? this.isEdited,
      status: status ?? this.status,
      isFromMe: this.isFromMe,
    );
  }
}
