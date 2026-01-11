import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_chat_app/services/backend_service.dart';
import 'package:my_chat_app/data/user_repository.dart'; // New import

/// This service implements the BackendService interface using Firebase Authentication.
/// It handles user registration, login, and profile updates related to Firebase Auth.
class FirebaseAuthService implements BackendService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final UserRepository _userRepository = UserRepository();

  @override
  Future<void> initialize() async {
    // Firebase initialization is typically handled in main.dart.
    // For this service, we just ensure Firebase is ready. This method might be
    // more relevant for other backend services (e.g., Supabase client init).
  }

  /// Converts a given username to a dummy email format for Firebase Authentication.
  /// Firebase Auth primarily uses email/password, so this workaround is necessary
  /// for username-based login. The format is "username@mychatapp.com".
  String _toEmail(String username) => "$username@mychatapp.com";

  /// Extracts the username from a dummy email format.
  String _toUsername(String email) => email.split('@').first;

  @override
  Future<String?> registerUser(String username, String password) async {
    try {
      UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: _toEmail(username),
        password: password,
      );
      String uid = userCredential.user!.uid;
      // Create user profile in Firestore after successful Firebase Auth registration
      await _userRepository.createUserProfile(
        uid: uid,
        username: username,
        displayName: username, // Initial display name is the username
      );
      return uid;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        return 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        return 'The account already exists for that username.';
      }
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  @override
  Future<String?> loginUser(String username, String password) async {
    try {
      UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: _toEmail(username),
        password: password,
      );
      return userCredential.user?.uid;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return 'No user found for that username.';
      } else if (e.code == 'wrong-password') {
        return 'Wrong password provided for that user.';
      }
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  @override
  Future<void> updateDisplayName(String userId, String newDisplayName) async {
    User? user = _firebaseAuth.currentUser;
    if (user != null && user.uid == userId) {
      await user.updateDisplayName(newDisplayName);
    } else {
      throw Exception("User not authenticated or unauthorized to update profile.");
    }
  }

  @override
  Future<String?> uploadProfilePicture(String userId, String filePath) async {
    return await _userRepository.uploadProfilePicture(userId, filePath);
  }

  @override
  Future<String?> uploadVoiceMessage(String chatId, String filePath) async {
    // In this MVP, voice message upload is handled directly by MediaService
    // and ChatPresenter, so FirebaseAuthService doesn't need to implement it.
    // A more comprehensive backend service might handle it.
    return null; 
  }
}
