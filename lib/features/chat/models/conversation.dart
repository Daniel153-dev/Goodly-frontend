/// Modèle pour une conversation de chat
class Conversation {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? lastMessage;
  final String? lastMessageHash;
  final DateTime? lastMessageAt;
  final String? lastMessageSenderId;
  final int unreadCount;
  final bool isArchived;
  final bool isGroup;
  final String? groupName;
  final String? otherUserId;
  final String? otherUserName;
  final String? otherUserPhoto;
  final bool hasBlueBadge;
  final String statut; // 'pending', 'accepted', 'rejected'
  final String? invitationMessage;

  Conversation({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessage,
    this.lastMessageHash,
    this.lastMessageAt,
    this.lastMessageSenderId,
    this.unreadCount = 0,
    this.isArchived = false,
    this.isGroup = false,
    this.groupName,
    this.otherUserId,
    this.otherUserName,
    this.otherUserPhoto,
    this.hasBlueBadge = false,
    this.statut = 'accepted',
    this.invitationMessage,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at'] ?? DateTime.now().toIso8601String()) ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? DateTime.now().toIso8601String()) ?? DateTime.now(),
      lastMessage: json['last_message'],
      lastMessageHash: json['last_message_hash'],
      lastMessageAt: json['last_message_at'] != null ? DateTime.tryParse(json['last_message_at']) : null,
      lastMessageSenderId: json['last_message_sender_id'],
      unreadCount: json['unread_count'] ?? 0,
      isArchived: json['is_archived'] ?? false,
      isGroup: json['is_group'] ?? false,
      groupName: json['group_name'],
      otherUserId: json['other_user_id'],
      otherUserName: json['other_user_name'],
      otherUserPhoto: json['other_user_photo'],
      hasBlueBadge: json['has_blue_badge'] ?? false,
      statut: json['statut'] ?? 'accepted',
      invitationMessage: json['invitation_message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_message': lastMessage,
      'last_message_hash': lastMessageHash,
      'last_message_at': lastMessageAt?.toIso8601String(),
      'last_message_sender_id': lastMessageSenderId,
      'unread_count': unreadCount,
      'is_archived': isArchived,
      'is_group': isGroup,
      'group_name': groupName,
      'other_user_id': otherUserId,
      'other_user_name': otherUserName,
      'other_user_photo': otherUserPhoto,
      'has_blue_badge': hasBlueBadge,
      'statut': statut,
      'invitation_message': invitationMessage,
    };
  }

  Conversation copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? lastMessage,
    String? lastMessageHash,
    DateTime? lastMessageAt,
    String? lastMessageSenderId,
    int? unreadCount,
    bool? isArchived,
    bool? isGroup,
    String? groupName,
    String? otherUserId,
    String? otherUserName,
    String? otherUserPhoto,
    bool? hasBlueBadge,
    String? statut,
    String? invitationMessage,
  }) {
    return Conversation(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageHash: lastMessageHash ?? this.lastMessageHash,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      unreadCount: unreadCount ?? this.unreadCount,
      isArchived: isArchived ?? this.isArchived,
      isGroup: isGroup ?? this.isGroup,
      groupName: groupName ?? this.groupName,
      otherUserId: otherUserId ?? this.otherUserId,
      otherUserName: otherUserName ?? this.otherUserName,
      otherUserPhoto: otherUserPhoto ?? this.otherUserPhoto,
      hasBlueBadge: hasBlueBadge ?? this.hasBlueBadge,
      statut: statut ?? this.statut,
      invitationMessage: invitationMessage ?? this.invitationMessage,
    );
  }
}
