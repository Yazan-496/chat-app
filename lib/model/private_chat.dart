DateTime? _parseDateTime(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }
  return DateTime.tryParse(value);
}

class PrivateChat {
  final String id;
  final String userOneId;
  final String userTwoId;
  final String? lastMessageId;
  final DateTime? createdAt;

  PrivateChat({
    required this.id,
    required this.userOneId,
    required this.userTwoId,
    this.lastMessageId,
    this.createdAt,
  });

  factory PrivateChat.fromMap(Map<String, dynamic> data) {
    return PrivateChat(
      id: data['id'] as String? ?? '',
      userOneId: data['user_one'] as String? ?? '',
      userTwoId: data['user_two'] as String? ?? '',
      lastMessageId: data['last_message_id'] as String?,
      createdAt: _parseDateTime(data['created_at']?.toString()),
    );
  }

  factory PrivateChat.fromJson(Map<String, dynamic> json) {
    return PrivateChat.fromMap(json);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_one': userOneId,
      'user_two': userTwoId,
      'last_message_id': lastMessageId,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toJson() {
    return toMap();
  }

  PrivateChat copyWith({
    String? id,
    String? userOneId,
    String? userTwoId,
    String? lastMessageId,
    DateTime? createdAt,
  }) {
    return PrivateChat(
      id: id ?? this.id,
      userOneId: userOneId ?? this.userOneId,
      userTwoId: userTwoId ?? this.userTwoId,
      lastMessageId: lastMessageId ?? this.lastMessageId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
