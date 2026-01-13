import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
}

enum MessageType {
  text,
  voice,
  image,
}

class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String receiverId;
  final MessageType type;
  final String content; // Encrypted for text, URL for media
  final DateTime timestamp;
  MessageStatus status;
  final String? replyToMessageId;
  final String? editedContent;
  final Map<String, String> reactions; // userId: emoji
  final bool deleted;

  Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.receiverId,
    required this.type,
    required this.content,
    required this.timestamp,
    this.status = MessageStatus.sending,
    this.replyToMessageId,
    this.editedContent,
    this.reactions = const {},
    this.deleted = false,
  });

  factory Message.fromMap(Map<String, dynamic> data) {
    return Message(
      id: data['id'] as String? ?? '',
      chatId: data['chatId'] as String? ?? '',
      senderId: data['senderId'] as String? ?? '',
      receiverId: data['receiverId'] as String? ?? '',
      type: MessageType.values.firstWhere(
          (e) => e.toString() == 'MessageType.' + (data['type'] as String? ?? 'text'),
          orElse: () => MessageType.text),
      content: data['content'] as String? ?? '',
      timestamp: data['timestamp'] is Timestamp 
          ? (data['timestamp'] as Timestamp).toDate() 
          : (data['timestamp'] != null ? DateTime.tryParse(data['timestamp'].toString()) ?? DateTime.now() : DateTime.now()),
      status: MessageStatus.values.firstWhere(
          (e) => e.toString() == 'MessageStatus.' + (data['status'] as String? ?? 'sent'),
          orElse: () => MessageStatus.sent),
      replyToMessageId: data['replyToMessageId'] as String?,
      editedContent: data['editedContent'] as String?,
      reactions: Map<String, String>.from(data['reactions'] as Map? ?? {}),
      deleted: (data['deleted'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'receiverId': receiverId,
      'type': type.toString().split('.').last,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'status': status.toString().split('.').last,
      'replyToMessageId': replyToMessageId,
      'editedContent': editedContent,
      'reactions': reactions,
      'deleted': deleted,
    };
  }

  Message copyWith({
    MessageStatus? status,
    String? content,
    String? editedContent,
    Map<String, String>? reactions,
    bool? deleted,
  }) {
    return Message(
      id: id,
      chatId: chatId,
      senderId: senderId,
      receiverId: receiverId,
      type: type,
      content: content ?? this.content,
      timestamp: timestamp,
      status: status ?? this.status,
      replyToMessageId: replyToMessageId,
      editedContent: editedContent ?? this.editedContent,
      reactions: reactions ?? this.reactions,
      deleted: deleted ?? this.deleted,
    );
  }
}
