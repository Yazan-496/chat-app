import 'package:my_chat_app/model/relationship.dart';
import 'package:my_chat_app/model/message.dart'; // New import for MessageStatus

class Chat {
  final String id;
  final List<String> participantIds;
  final String displayName;
  final String? profilePictureUrl;
  final int? avatarColor;
  final RelationshipType relationshipType;
  final DateTime lastMessageTime;
  final String? lastMessageContent;
  final String? lastMessageSenderId;
  final MessageStatus? lastMessageStatus;
  bool isOnline;
  DateTime? lastSeen;
  int unreadCount;

  String getOtherUserId(String currentUserId) {
    return participantIds.firstWhere((id) => id != currentUserId);
  }

  Chat({
    required this.id,
    required this.participantIds,
    required this.displayName,
    this.profilePictureUrl,
    this.avatarColor,
    required this.relationshipType,
    required this.lastMessageTime,
    this.lastMessageContent,
    this.lastMessageSenderId,
    this.lastMessageStatus,
    this.isOnline = false,
    this.lastSeen,
    this.unreadCount = 0,
  });

  factory Chat.fromMap(Map<String, dynamic> data) {
    return Chat(
      id: data['id'] as String? ?? '',
      participantIds: data['participant_ids'] != null ? List<String>.from(data['participant_ids'] as List) : [],
      displayName: 'Unknown', 
      profilePictureUrl: null,
      avatarColor: null,
      relationshipType: RelationshipType.values.firstWhere(
          (e) => e.toString() == 'RelationshipType.' + (data['relationship_type'] ?? 'friend').toString(),
          orElse: () => RelationshipType.friend),
      lastMessageTime: data['last_message_time'] != null 
          ? DateTime.tryParse(data['last_message_time'].toString()) ?? DateTime.now() 
          : DateTime.now(),
      lastMessageContent: data['last_message_content'] as String?,
      lastMessageSenderId: data['last_message_sender_id'] as String?,
      lastMessageStatus: data['last_message_status'] != null
          ? MessageStatus.values.firstWhere(
              (e) => e.toString().split('.').last == data['last_message_status'].toString(),
              orElse: () => MessageStatus.sent)
          : null,
      isOnline: false,
      lastSeen: null,
      unreadCount: (data['unread_count'] ?? data['unreadcount']) as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'participant_ids': participantIds,
      'relationship_type': relationshipType.name,
      'last_message_time': lastMessageTime.toIso8601String(),
      'last_message_content': lastMessageContent,
      'last_message_sender_id': lastMessageSenderId,
      'last_message_status': lastMessageStatus?.toString().split('.').last,
      // Note: username, profile_picture_url, avatar_color, is_online, last_seen are NOT in the 'chats' table
    };
  }

  // Method to create a copy of the Chat object with updated fields
  Chat copyWith({
    String? id,
    List<String>? participantIds,
    String? displayName,
    String? profilePictureUrl,
    int? avatarColor,
    RelationshipType? relationshipType,
    DateTime? lastMessageTime,
    String? lastMessageContent,
    String? lastMessageSenderId,
    MessageStatus? lastMessageStatus,
    bool? isOnline,
    DateTime? lastSeen,
    int? unreadCount,
  }) {
    return Chat(
      id: id ?? this.id,
      participantIds: participantIds ?? this.participantIds,
      displayName: displayName ?? this.displayName,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      avatarColor: avatarColor ?? this.avatarColor,
      relationshipType: relationshipType ?? this.relationshipType,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      lastMessageContent: lastMessageContent ?? this.lastMessageContent,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      lastMessageStatus: lastMessageStatus ?? this.lastMessageStatus,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}
