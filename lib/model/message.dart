enum MessageType {
  text,
  image,
  audio,
  file,
  system,
}

enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
}

extension MessageStatusJson on MessageStatus {
  String toJson() {
    switch (this) {
      case MessageStatus.sending:
        return 'sending';
      case MessageStatus.sent:
        return 'sent';
      case MessageStatus.delivered:
        return 'delivered';
      case MessageStatus.read:
        return 'read';
      case MessageStatus.failed:
        return 'failed';
    }
  }

  static MessageStatus fromJson(String? value) {
    switch (value?.toLowerCase()) {
      case 'sending':
        return MessageStatus.sending;
      case 'failed':
        return MessageStatus.failed;
      case 'delivered':
        return MessageStatus.delivered;
      case 'read':
        return MessageStatus.read;
      case 'sent':
      default:
        return MessageStatus.sent;
    }
  }
}

extension MessageTypeJson on MessageType {
  String toJson() {
    switch (this) {
      case MessageType.text:
        return 'TEXT';
      case MessageType.image:
        return 'IMAGE';
      case MessageType.audio:
        return 'AUDIO';
      case MessageType.file:
        return 'FILE';
      case MessageType.system:
        return 'SYSTEM';
    }
  }

  static MessageType fromJson(String? value) {
    switch (value?.toUpperCase()) {
      case 'IMAGE':
        return MessageType.image;
      case 'AUDIO':
        return MessageType.audio;
      case 'FILE':
        return MessageType.file;
      case 'SYSTEM':
        return MessageType.system;
      case 'TEXT':
      default:
        return MessageType.text;
    }
  }
}

DateTime? _parseDateTime(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }
  return DateTime.tryParse(value);
}

Map<String, String> _parseReactions(dynamic value) {
  if (value is Map) {
    return value.map(
      (key, val) => MapEntry(key.toString(), val?.toString() ?? ''),
    );
  }
  if (value is List) {
    final reactions = <String, String>{};
    for (final item in value) {
      if (item is Map) {
        final userId = item['user_id']?.toString();
        final emoji = item['emoji']?.toString();
        if (userId != null && emoji != null && emoji.isNotEmpty) {
          reactions[userId] = emoji;
        }
      }
    }
    return reactions;
  }
  return {};
}

class Message {
  final String id;
  final String chatId;
  final String? senderId;
  final String? content;
  final MessageType type;
  final String? replyToMessageId;
  final Map<String, String> reactions;
  final MessageStatus status;
  final bool isEdited;
  final bool isDeleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Message({
    required this.id,
    required this.chatId,
    this.senderId,
    this.content,
    this.type = MessageType.text,
    this.replyToMessageId,
    this.reactions = const {},
    this.status = MessageStatus.sent,
    this.isEdited = false,
    this.isDeleted = false,
    this.createdAt,
    this.updatedAt,
  });

  factory Message.fromMap(Map<String, dynamic> data) {
    return Message(
      id: data['id'] as String? ?? '',
      chatId: data['chat_id'] as String? ?? '',
      senderId: data['sender_id'] as String?,
      content: data['content'] as String?,
      type: MessageTypeJson.fromJson(data['type'] as String?),
      replyToMessageId: data['reply_to_message_id'] as String?,
      reactions: _parseReactions(data['message_reactions'] ?? data['reactions']),
      status: MessageStatusJson.fromJson(data['status'] as String?),
      isEdited: data['is_edited'] as bool? ?? false,
      isDeleted: data['is_deleted'] as bool? ?? false,
      createdAt: _parseDateTime(data['created_at']?.toString()),
      updatedAt: _parseDateTime(data['updated_at']?.toString()),
    );
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message.fromMap(json);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chat_id': chatId,
      'sender_id': senderId,
      'content': content,
      'type': type.toJson(),
      'reply_to_message_id': replyToMessageId,
      'is_edited': isEdited,
      'is_deleted': isDeleted,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toJson() {
    return toMap();
  }

  Message copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? content,
    MessageType? type,
    String? replyToMessageId,
    Map<String, String>? reactions,
    MessageStatus? status,
    bool? isEdited,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Message(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      type: type ?? this.type,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      reactions: reactions ?? this.reactions,
      status: status ?? this.status,
      isEdited: isEdited ?? this.isEdited,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
