import 'package:cloud_firestore/cloud_firestore.dart';

class PresenceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Marks the user as online and updates lastSeen to now.
  Future<void> setUserOnline(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'isOnline': true,
        'lastSeen': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('PresenceService: Failed to set online for $uid: $e');
    }
  }

  /// Marks the user as offline and updates lastSeen to now.
  Future<void> setUserOffline(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'isOnline': false,
        'lastSeen': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('PresenceService: Failed to set offline for $uid: $e');
    }
  }
}
