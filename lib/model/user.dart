class User {
  final String uid;
  final String username;
  String displayName;
  String? profilePictureUrl;

  User({
    required this.uid,
    required this.username,
    required this.displayName,
    this.profilePictureUrl,
  });

  // Factory constructor for creating a User from a map (e.g., from Firestore)
  factory User.fromMap(Map<String, dynamic> data) {
    return User(
      uid: data['uid'] as String,
      username: data['username'] as String,
      displayName: data['displayName'] as String,
      profilePictureUrl: data['profilePictureUrl'] as String?,
    );
  }

  // Method for converting a User to a map (e.g., for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'username': username,
      'displayName': displayName,
      'profilePictureUrl': profilePictureUrl,
    };
  }
}
