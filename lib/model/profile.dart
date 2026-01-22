enum UserStatus {
  online,
  offline,
}

extension UserStatusJson on UserStatus {
  String toJson() {
    switch (this) {
      case UserStatus.online:
        return 'ONLINE';
      case UserStatus.offline:
        return 'OFFLINE';
    }
  }

  static UserStatus fromJson(String? value) {
    switch (value?.toUpperCase()) {
      case 'ONLINE':
        return UserStatus.online;
      case 'OFFLINE':
      default:
        return UserStatus.offline;
    }
  }
}

DateTime? _parseDateTime(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }
  return DateTime.tryParse(value);
}

int? _normalizeAvatarColor(int? value) {
  if (value == null) {
    return null;
  }
  if (value >= 0 && value <= 0x00FFFFFF) {
    return value | 0xFF000000;
  }
  return value;
}

class Profile {
  final String id;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final int? avatarColor;
  final UserStatus status;
  final DateTime? lastSeen;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Profile({
    required this.id,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    this.avatarColor,
    this.status = UserStatus.offline,
    this.lastSeen,
    this.createdAt,
    this.updatedAt,
  });

  factory Profile.fromMap(Map<String, dynamic> data) {
    return Profile(
      id: data['id'] as String? ?? '',
      username: data['username'] as String? ?? '',
      displayName: data['display_name'] as String? ?? '',
      avatarUrl: data['avatar_url'] as String?,
      avatarColor: _normalizeAvatarColor(data['avatar_color'] as int?),
      status: UserStatusJson.fromJson(data['status'] as String?),
      lastSeen: _parseDateTime(data['last_seen']?.toString()),
      createdAt: _parseDateTime(data['created_at']?.toString()),
      updatedAt: _parseDateTime(data['updated_at']?.toString()),
    );
  }

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile.fromMap(json);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'avatar_color': avatarColor,
      'status': status.toJson(),
      'last_seen': lastSeen?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toJson() {
    return toMap();
  }

  Profile copyWith({
    String? id,
    String? username,
    String? displayName,
    String? avatarUrl,
    int? avatarColor,
    UserStatus? status,
    DateTime? lastSeen,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Profile(
      id: id ?? this.id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      avatarColor: avatarColor ?? this.avatarColor,
      status: status ?? this.status,
      lastSeen: lastSeen ?? this.lastSeen,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
