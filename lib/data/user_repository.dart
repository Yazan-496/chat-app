import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:my_chat_app/model/user.dart' as model;
import 'dart:io';

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final auth.FirebaseAuth _firebaseAuth = auth.FirebaseAuth.instance;

  /// Retrieves a stream of the current user's data from Firestore.
  /// This allows for real-time updates to the user's profile.
  Stream<model.User?> getCurrentUserStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((snapshot) {
      if (snapshot.exists) {
        return model.User.fromMap(snapshot.data()!);
      } else {
        return null;
      }
    });
  }

  /// Retrieves a single instance of a user's data from Firestore by their UID.
  Future<model.User?> getUser(String uid) async {
    print('UserRepository: Fetching user with UID: $uid');
    DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      print('UserRepository: User $uid found.');
      return model.User.fromMap(doc.data() as Map<String, dynamic>);
    } else {
      print('UserRepository: User $uid not found.');
      return null;
    }
  }

  /// Creates a new user profile in Firestore.
  /// This is typically called after a successful Firebase Authentication registration.
  Future<void> createUserProfile({
    required String uid,
    required String username,
    required String displayName,
  }) async {
    model.User user = model.User(
      uid: uid,
      username: username,
      displayName: displayName,
    );
    await _firestore.collection('users').doc(uid).set(user.toMap());
  }

  /// Updates the display name of a user in Firestore and optionally in Firebase Authentication.
  Future<void> updateDisplayName(String uid, String newDisplayName) async {
    await _firestore.collection('users').doc(uid).update({'displayName': newDisplayName});
    // Also update Firebase Auth display name if it's the current user
    if (_firebaseAuth.currentUser?.uid == uid) {
      await _firebaseAuth.currentUser?.updateDisplayName(newDisplayName);
    }
  }

  /// Uploads a new profile picture to Firebase Storage and updates the user's profile with the new URL.
  Future<String?> uploadProfilePicture(String uid, String imagePath) async {
    try {
      File file = File(imagePath);
      String fileName = 'profile_pictures/$uid/${DateTime.now().millisecondsSinceEpoch}.jpg';
      UploadTask uploadTask = _storage.ref().child(fileName).putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      await _firestore.collection('users').doc(uid).update({'profilePictureUrl': downloadUrl});
      return downloadUrl;
    } catch (e) {
      print('Error uploading profile picture: $e');
      return null;
    }
  }

  /// Searches for users by their username.
  /// This performs a prefix search. For full-text search capabilities,
  /// a dedicated search service (e.g., Algolia, Elasticsearch) would be needed
  /// as Firestore does not directly support 'contains' queries.
  Future<List<model.User>> searchUsersByUsername(String query, String currentUserId) async {
    if (query.isEmpty) {
      return [];
    }
    // Firestore query for usernames that start with the query string and exclude current user
    QuerySnapshot snapshot = await _firestore
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: query)
        .where('username', isLessThanOrEqualTo: query + '')
        .where('uid', isNotEqualTo: currentUserId)
        .get();
    return snapshot.docs.map((doc) => model.User.fromMap(doc.data() as Map<String, dynamic>)).toList();
  }

  /// Deletes a user's profile and associated data from Firestore.
  /// This includes the user document and all chats the user is a participant in.
  /// NOTE: For a production app, you would typically use a Cloud Function
  /// to recursively delete subcollections (like messages within chats)
  /// to avoid manual client-side deletion which can be complex and error-prone.
  Future<void> deleteUserAccount(String uid) async {
    // 1. Delete user's own document
    await _firestore.collection('users').doc(uid).delete();
    print('UserRepository: Deleted user document for $uid');

    // 2. Find and delete chats where the user is a participant
    QuerySnapshot chatSnapshots = await _firestore
        .collection('chats')
        .where('participantIds', arrayContains: uid)
        .get();

    for (var chatDoc in chatSnapshots.docs) {
      // IMPORTANT: Recursively delete subcollections (e.g., 'messages') here.
      // This client-side approach is simplified. In production, use Cloud Functions.
      // For now, we'll just delete the chat document itself, leaving subcollections behind.
      // This is a known limitation for simplicity in this example.
      await chatDoc.reference.delete();
      print('UserRepository: Deleted chat document ${chatDoc.id}');
    }

    // 3. Delete profile picture from Firebase Storage (optional)
    // This would require more sophisticated logic to find all pictures,
    // especially if you allow multiple uploads. For now, skipping for simplicity.
    // In a real app, you might use a Cloud Function triggered by user deletion.
  }
}
