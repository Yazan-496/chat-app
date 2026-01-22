DateTime? _parseDateTime(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }
  return DateTime.tryParse(value);
}

class MessageReaction {
  final String id;
  final String messageId;
  final String userId;
  final String emoji;
  final DateTime? createdAt;

  MessageReaction({
    required this.id,
    required this.messageId,
    required this.userId,
    required this.emoji,
    this.createdAt,
  });

  factory MessageReaction.fromMap(Map<String, dynamic> data) {
    return MessageReaction(
      id: data['id'] as String? ?? '',
      messageId: data['message_id'] as String? ?? '',
      userId: data['user_id'] as String? ?? '',
      emoji: data['emoji'] as String? ?? '',
      createdAt: _parseDateTime(data['created_at']?.toString()),
    );
  }

  factory MessageReaction.fromJson(Map<String, dynamic> json) {
    return MessageReaction.fromMap(json);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'message_id': messageId,
      'user_id': userId,
      'emoji': emoji,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toJson() {
    return toMap();
  }

  MessageReaction copyWith({
    String? id,
    String? messageId,
    String? userId,
    String? emoji,
    DateTime? createdAt,
  }) {
    return MessageReaction(
      id: id ?? this.id,
      messageId: messageId ?? this.messageId,
      userId: userId ?? this.userId,
      emoji: emoji ?? this.emoji,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
