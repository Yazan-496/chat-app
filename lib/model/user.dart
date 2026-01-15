class User {
  final String uid;
  String get id => uid;
  final String username;
  String displayName;
  String? profilePictureUrl;
  bool isOnline;
  DateTime? lastSeen;
  String? activeChatId;
  int? avatarColor;

  User({
    required this.uid,
    required this.username,
    required this.displayName,
    this.profilePictureUrl,
    this.isOnline = false,
    this.lastSeen,
    this.activeChatId,
    this.avatarColor,
  });

  // Factory constructor for creating a User from a map (e.g., from Firestore)
  factory User.fromMap(Map<String, dynamic> data) {
    DateTime? lastSeen;
    final lastSeenValue = data['last_seen'];
    if (lastSeenValue != null) {
      if (lastSeenValue is DateTime) {
        lastSeen = lastSeenValue;
      } else if (lastSeenValue is String) {
        try {
          lastSeen = DateTime.parse(lastSeenValue);
        } catch (e) {
          print('User.fromMap: Error parsing lastSeen string: $e');
          lastSeen = null;
        }
      }
    }
    
    return User(
      uid: data['id'] as String? ?? '',
      username: data['username'] as String? ?? 'Unknown',
      displayName: data['display_name'] as String? ?? 'User',
      profilePictureUrl: data['profile_picture_url'] as String?,
      isOnline: data['is_online'] as bool? ?? false,
      lastSeen: lastSeen,
      activeChatId: data['active_chat_id'] as String?,
      avatarColor: data['avatar_color'] != null 
          ? (data['avatar_color'] as int) | 0xFF000000 
          : null,
    );
  }

  // Method for converting a User to a map
  Map<String, dynamic> toMap() {
    return {
      'id': uid,
      'username': username,
      'display_name': displayName,
      'profile_picture_url': profilePictureUrl,
      'is_online': isOnline,
      'last_seen': lastSeen?.toIso8601String(),
      'active_chat_id': activeChatId,
      'avatar_color': avatarColor,
    };
  }
}
