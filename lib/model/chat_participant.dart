class ChatParticipant {
  final String chatId;
  final String userId;
  final String? lastDeliveredMessageId;
  final String? lastReadMessageId;
  final int unreadCount;

  ChatParticipant({
    required this.chatId,
    required this.userId,
    this.lastDeliveredMessageId,
    this.lastReadMessageId,
    this.unreadCount = 0,
  });

  factory ChatParticipant.fromMap(Map<String, dynamic> data) {
    return ChatParticipant(
      chatId: data['chat_id'] as String? ?? '',
      userId: data['user_id'] as String? ?? '',
      lastDeliveredMessageId: data['last_delivered_message_id'] as String?,
      lastReadMessageId: data['last_read_message_id'] as String?,
      unreadCount: data['unread_count'] as int? ?? 0,
    );
  }

  factory ChatParticipant.fromJson(Map<String, dynamic> json) {
    return ChatParticipant.fromMap(json);
  }

  Map<String, dynamic> toMap() {
    return {
      'chat_id': chatId,
      'user_id': userId,
      'last_delivered_message_id': lastDeliveredMessageId,
      'last_read_message_id': lastReadMessageId,
      'unread_count': unreadCount,
    };
  }

  Map<String, dynamic> toJson() {
    return toMap();
  }

  ChatParticipant copyWith({
    String? chatId,
    String? userId,
    String? lastDeliveredMessageId,
    String? lastReadMessageId,
    int? unreadCount,
  }) {
    return ChatParticipant(
      chatId: chatId ?? this.chatId,
      userId: userId ?? this.userId,
      lastDeliveredMessageId:
          lastDeliveredMessageId ?? this.lastDeliveredMessageId,
      lastReadMessageId: lastReadMessageId ?? this.lastReadMessageId,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}
