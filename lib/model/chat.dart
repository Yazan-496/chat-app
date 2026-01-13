import 'package:my_chat_app/model/relationship.dart';
import 'package:my_chat_app/model/message.dart'; // New import for MessageStatus

import 'package:my_chat_app/model/relationship.dart';
import 'package:my_chat_app/model/message.dart'; // New import for MessageStatus

class Chat {
  final String id;
  final List<String> participantIds;
  final String otherUserName;
  final String? otherUserProfilePictureUrl;
  final RelationshipType relationshipType;
  final DateTime lastMessageTime;
  final String? lastMessageContent;
  final String? lastMessageSenderId; // New field
  final MessageStatus? lastMessageStatus; // New field
  bool otherUserIsOnline;
  DateTime? otherUserLastSeen;

  String getOtherUserId(String currentUserId) {
    return participantIds.firstWhere((id) => id != currentUserId);
  }

  Chat({
    required this.id,
    required this.participantIds,
    required this.otherUserName,
    this.otherUserProfilePictureUrl,
    required this.relationshipType,
    required this.lastMessageTime,
    this.lastMessageContent,
    this.lastMessageSenderId,
    this.lastMessageStatus,
    this.otherUserIsOnline = false,
    this.otherUserLastSeen,
  });

  factory Chat.fromMap(Map<String, dynamic> data) {
    return Chat(
      id: data['id'] as String,
      participantIds: List<String>.from(data['participantIds'] as List),
      otherUserName: data['otherUserName'] as String,
      otherUserProfilePictureUrl: data['otherUserProfilePictureUrl'] as String?,
      relationshipType: RelationshipType.values.firstWhere(
          (e) => e.toString() == 'RelationshipType.' + (data['relationshipType'] as String)),
      lastMessageTime: DateTime.parse(data['lastMessageTime'] as String),
      lastMessageContent: data['lastMessageContent'] as String?,
      lastMessageSenderId: data['lastMessageSenderId'] as String?,
      lastMessageStatus: data['lastMessageStatus'] != null
          ? MessageStatus.values.firstWhere((e) => e.toString().split('.').last == data['lastMessageStatus'])
          : null,
      otherUserIsOnline: data['otherUserIsOnline'] as bool? ?? false,
      otherUserLastSeen: (data['otherUserLastSeen'] as String?) != null ? DateTime.parse(data['otherUserLastSeen'] as String) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'participantIds': participantIds,
      'otherUserName': otherUserName,
      'otherUserProfilePictureUrl': otherUserProfilePictureUrl,
      'relationshipType': relationshipType.name,
      'lastMessageTime': lastMessageTime.toIso8601String(),
      'lastMessageContent': lastMessageContent,
      'lastMessageSenderId': lastMessageSenderId,
      'lastMessageStatus': lastMessageStatus?.toString().split('.').last,
      'otherUserIsOnline': otherUserIsOnline,
      'otherUserLastSeen': otherUserLastSeen?.toIso8601String(),
    };
  }

  // Method to create a copy of the Chat object with updated fields
  Chat copyWith({
    String? id,
    List<String>? participantIds,
    String? otherUserName,
    String? otherUserProfilePictureUrl,
    RelationshipType? relationshipType,
    DateTime? lastMessageTime,
    String? lastMessageContent,
    String? lastMessageSenderId,
    MessageStatus? lastMessageStatus,
    bool? otherUserIsOnline,
    DateTime? otherUserLastSeen,
  }) {
    return Chat(
      id: id ?? this.id,
      participantIds: participantIds ?? this.participantIds,
      otherUserName: otherUserName ?? this.otherUserName,
      otherUserProfilePictureUrl: otherUserProfilePictureUrl ?? this.otherUserProfilePictureUrl,
      relationshipType: relationshipType ?? this.relationshipType,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      lastMessageContent: lastMessageContent ?? this.lastMessageContent,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      lastMessageStatus: lastMessageStatus ?? this.lastMessageStatus,
      otherUserIsOnline: otherUserIsOnline ?? this.otherUserIsOnline,
      otherUserLastSeen: otherUserLastSeen ?? this.otherUserLastSeen,
    );
  }
}
