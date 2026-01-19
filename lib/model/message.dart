import 'dart:convert';
import 'package:isar/isar.dart';
import 'package:my_chat_app/utils/isar_utils.dart';

part 'message.g.dart';

@enumerated
enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
}

@enumerated
enum MessageType {
  text,
  voice,
  image,
}

@collection
class Message {
  Id get isarId => fastHash(id);

  @Index(unique: true, replace: true)
  final String id;
  
  @Index()
  final String chatId;
  
  final String senderId;
  final String receiverId;
  
  @enumerated
  final MessageType type;
  
  final String content; // Encrypted for text, URL for media
  
  @Index()
  final DateTime timestamp;
  
  @enumerated
  MessageStatus status;
  
  final String? replyToMessageId;
  final String? editedContent;
  
  @ignore
  Map<String, String> reactions; // userId: emoji

  String? get reactionsRaw => jsonEncode(reactions);
  set reactionsRaw(String? value) {
    if (value != null && value.isNotEmpty) {
      try {
        reactions = Map<String, String>.from(jsonDecode(value));
      } catch (_) {
        reactions = {};
      }
    } else {
      reactions = {};
    }
  }
  
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
      chatId: data['chat_id'] as String? ?? '',
      senderId: data['sender_id'] as String? ?? '',
      receiverId: data['receiver_id'] as String? ?? '',
      type: MessageType.values.firstWhere(
          (e) => e.toString() == 'MessageType.' + (data['type'] as String? ?? 'text'),
          orElse: () => MessageType.text),
      content: data['content'] as String? ?? '',
      timestamp: data['timestamp'] != null 
          ? (DateTime.tryParse(data['timestamp'].toString())?.toUtc() ?? DateTime.now().toUtc()) 
          : DateTime.now().toUtc(),
      status: MessageStatus.values.firstWhere(
          (e) => e.toString() == 'MessageStatus.' + (data['status'] as String? ?? 'sent'),
          orElse: () => MessageStatus.sent),
      replyToMessageId: data['reply_to_message_id'] as String?,
      editedContent: data['edited_content'] as String?,
      reactions: Map<String, String>.from(data['reactions'] as Map? ?? {}),
      deleted: (data['deleted'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chat_id': chatId,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'type': type.toString().split('.').last,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'status': status.toString().split('.').last,
      'reply_to_message_id': replyToMessageId,
      'edited_content': editedContent,
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
