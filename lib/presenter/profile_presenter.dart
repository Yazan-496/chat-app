import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:my_chat_app/data/user_repository.dart';
import 'package:my_chat_app/model/user.dart' as app_user;
import 'package:my_chat_app/view/profile_view.dart';

class ProfilePresenter {
  final ProfileView _view;
  final UserRepository _userRepository;
  final auth.FirebaseAuth _firebaseAuth = auth.FirebaseAuth.instance;
  app_user.User? _currentUser;

  ProfilePresenter(this._view) : _userRepository = UserRepository();

  void loadUserProfile() async {
    _view.showLoading();
    String? uid = _firebaseAuth.currentUser?.uid;
    if (uid != null) {
      _currentUser = await _userRepository.getUser(uid);
      if (_currentUser != null) {
        _view.displayUserProfile(_currentUser!);
      } else {
        _view.showMessage('User profile not found.');
      }
    } else {
      _view.showMessage('User not authenticated.');
    }
    _view.hideLoading();
  }

  Future<void> updateDisplayName(String newDisplayName) async {
    if (_currentUser == null) {
      _view.showMessage('No user profile to update.');
      return;
    }
    _view.showLoading();
    try {
      await _userRepository.updateDisplayName(_currentUser!.uid, newDisplayName);
      _currentUser!.displayName = newDisplayName;
      _view.displayUserProfile(_currentUser!); // Update the view with new data
      _view.showMessage('Display name updated successfully!');
    } catch (e) {
      _view.showMessage('Failed to update display name: $e');
    }
    _view.hideLoading();
  }

  Future<void> updateProfilePicture(String imagePath) async {
    if (_currentUser == null) {
      _view.showMessage('No user profile to update.');
      return;
    }
    _view.showLoading();
    try {
      String? downloadUrl = await _userRepository.uploadProfilePicture(_currentUser!.uid, imagePath);
      if (downloadUrl != null) {
        _currentUser!.profilePictureUrl = downloadUrl;
        _view.displayUserProfile(_currentUser!); // Update the view with new data
        _view.showMessage('Profile picture updated successfully!');
      } else {
        _view.showMessage('Failed to upload profile picture.');
      }
    } catch (e) {
      _view.showMessage('Failed to update profile picture: $e');
    }
    _view.hideLoading();
  }

  app_user.User? get currentUser => _currentUser;

  Future<void> deleteAccount() async {
    if (_currentUser == null) {
      _view.showMessage('No user logged in to delete.');
      return;
    }
    _view.showLoading();
    try {
      // This is where we will call the UserRepository to delete user data
      await _userRepository.deleteUserAccount(_currentUser!.uid);

      // Delete user from Firebase Authentication
      await _firebaseAuth.currentUser?.delete();

      _view.showMessage('Account deleted successfully.');
      _view.navigateBack(); // Navigate back to AuthScreen after deletion
    } catch (e) {
      _view.showMessage('Failed to delete account: $e');
    } finally {
      _view.hideLoading();
    }
  }
}
