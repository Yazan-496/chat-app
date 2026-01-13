import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String uid;
  final String username;
  String displayName;
  String? profilePictureUrl;
  bool isOnline;
  DateTime? lastSeen;
  String? activeChatId;

  User({
    required this.uid,
    required this.username,
    required this.displayName,
    this.profilePictureUrl,
    this.isOnline = false,
    this.lastSeen,
    this.activeChatId,
  });

  // Factory constructor for creating a User from a map (e.g., from Firestore)
  factory User.fromMap(Map<String, dynamic> data) {
    DateTime? lastSeen;
    final lastSeenValue = data['lastSeen'];
    if (lastSeenValue != null) {
      if (lastSeenValue is Timestamp) {
        lastSeen = lastSeenValue.toDate();
      } else if (lastSeenValue is DateTime) {
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
      uid: data['uid'] as String? ?? '',
      username: data['username'] as String? ?? 'Unknown',
      displayName: data['displayName'] as String? ?? 'User',
      profilePictureUrl: data['profilePictureUrl'] as String?,
      isOnline: data['isOnline'] as bool? ?? false,
      lastSeen: lastSeen,
      activeChatId: data['activeChatId'] as String?,
    );
  }

  // Method for converting a User to a map (e.g., for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'username': username,
      'displayName': displayName,
      'profilePictureUrl': profilePictureUrl,
      'isOnline': isOnline,
      'lastSeen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,
      'activeChatId': activeChatId,
    };
  }
}
