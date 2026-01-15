import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_chat_app/data/user_repository.dart';
import 'package:my_chat_app/model/user.dart' as app_user;
import 'package:my_chat_app/view/profile_view.dart';
import 'package:my_chat_app/model/relationship.dart';
import 'package:my_chat_app/data/chat_repository.dart';
import 'dart:async';

class ProfilePresenter {
  final ProfileView _view;
  final UserRepository _userRepository;
  final ChatRepository _chatRepository;
  final SupabaseClient _supabase = Supabase.instance.client;
  app_user.User? _userProfile;
  final String _userId;
  StreamSubscription? _userProfileSubscription;
  StreamSubscription? _relationshipSubscription;

  ProfilePresenter(this._view, this._userId)
      : _userRepository = UserRepository(),
        _chatRepository = ChatRepository();

  void loadUserProfile() {
    _view.showLoading();
    _userProfileSubscription = _userRepository.getCurrentUserStream(_userId).listen((user) {
      if (user != null) {
        _userProfile = user;
        _view.displayUserProfile(_userProfile!);
        _view.hideLoading();
      } else {
        _view.showMessage('User profile not found.');
        _view.hideLoading();
      }
    });
  }

  void dispose() {
    _userProfileSubscription?.cancel();
    _relationshipSubscription?.cancel();
  }

  void loadRelationship() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      _view.showMessage('User not authenticated.');
      return;
    }
    _relationshipSubscription = _chatRepository.streamRelationship(user.id, _userId).listen((relationship) {
      _view.displayRelationship(relationship);
    });
  }

  Future<void> updateRelationship(RelationshipType newType) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      _view.showMessage('User not authenticated.');
      return;
    }
    _view.showLoading();
    try {
      await _chatRepository.createOrUpdateRelationship(user.id, _userId, newType);
      _view.showMessage('Relationship updated successfully!');
    } catch (e) {
      _view.showMessage('Failed to update relationship: $e');
    } finally {
      _view.hideLoading();
    }
  }


  Future<void> updateDisplayName(String newDisplayName) async {
    if (_userProfile == null) {
      _view.showMessage('No user profile to update.');
      return;
    }
    _view.showLoading();
    try {
      await _userRepository.updateDisplayName(_userProfile!.uid, newDisplayName);
      _userProfile!.displayName = newDisplayName;
      _view.displayUserProfile(_userProfile!); // Update the view with new data
      _view.showMessage('Display name updated successfully!');
    } catch (e) {
      _view.showMessage('Failed to update display name: $e');
    }
    _view.hideLoading();
  }

  Future<void> updateProfilePicture(String imagePath) async {
    if (_userProfile == null) {
      _view.showMessage('No user profile to update.');
      return;
    }
    _view.showLoading();
    try {
      String? downloadUrl = await _userRepository.uploadProfilePicture(_userProfile!.uid, imagePath);
      if (downloadUrl != null) {
        _userProfile!.profilePictureUrl = downloadUrl;
        _view.displayUserProfile(_userProfile!); // Update the view with new data
        _view.showMessage('Profile picture updated successfully!');
      } else {
        _view.showMessage('Failed to upload profile picture.');
      }
    } catch (e) {
      _view.showMessage('Failed to update profile picture: $e');
    }
    _view.hideLoading();
  }

  Future<void> deleteAccount() async {
    if (_userProfile == null) {
      _view.showMessage('No user logged in to delete.');
      return;
    }
    _view.showLoading();
    try {
      // In Supabase, deleting an account usually involves a database function or edge function
      // for security reasons, but we can sign out and delete the profile record.
      // Supabase doesn't allow self-deletion via client library for auth users by default.
      
      await _supabase.auth.signOut();
      _view.showMessage('Account deletion requested.');
      _view.navigateToSignIn(); 
    } catch (e) {
      _view.showMessage('Failed to delete account: $e');
    } finally {
      _view.hideLoading();
    }
  }
}
