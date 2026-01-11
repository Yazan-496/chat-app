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
    this.lastMessageSenderId, // Add to constructor
    this.lastMessageStatus, // Add to constructor
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
      lastMessageSenderId: data['lastMessageSenderId'] as String?, // Retrieve from map
      lastMessageStatus: data['lastMessageStatus'] != null
          ? MessageStatus.values.firstWhere((e) => e.toString().split('.').last == data['lastMessageStatus'])
          : null, // Retrieve and parse status
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
      'lastMessageSenderId': lastMessageSenderId, // Add to map
      'lastMessageStatus': lastMessageStatus?.toString().split('.').last, // Add to map
    };
  }
}
