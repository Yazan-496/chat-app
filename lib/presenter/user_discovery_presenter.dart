import 'package:my_chat_app/data/user_repository.dart';
import 'package:my_chat_app/model/user.dart' as app_user;
import 'package:my_chat_app/view/user_discovery_view.dart';
import 'package:my_chat_app/data/chat_repository.dart'; // New import
import 'package:my_chat_app/model/relationship.dart'; // New import
import 'package:firebase_auth/firebase_auth.dart' as auth;

class UserDiscoveryPresenter {
  final UserDiscoveryView _view;
  final UserRepository _userRepository;
  final ChatRepository _chatRepository;
  final auth.FirebaseAuth _firebaseAuth = auth.FirebaseAuth.instance;
  List<app_user.User> _searchResults = [];

  UserDiscoveryPresenter(this._view) : _userRepository = UserRepository(), _chatRepository = ChatRepository();

  List<app_user.User> get searchResults => _searchResults;

  Future<void> searchUsers(String query) async {
    _view.showLoading();
    try {
      final currentUserId = _firebaseAuth.currentUser?.uid;
      if (currentUserId == null) {
        _view.showMessage('User not authenticated.');
        _view.hideLoading();
        return;
      }
      _searchResults = await _userRepository.searchUsersByUsername(query, currentUserId);
      _view.displaySearchResults(_searchResults);
    } catch (e) {
      _view.showMessage('Error searching users: $e');
    }
    _view.hideLoading();
  }

  Future<void> addUserToChatList(app_user.User otherUser, RelationshipType relationshipType) async {
    _view.showLoading();
    try {
      final currentUserId = _firebaseAuth.currentUser?.uid;
      if (currentUserId == null) {
        _view.showMessage('User not authenticated.');
        _view.hideLoading();
        return;
      }
      await _chatRepository.createChat(currentUserId: currentUserId, otherUser: otherUser, relationshipType: relationshipType);
      _view.showMessage('${otherUser.displayName} added to chat list as ${relationshipType.name}!');
    } catch (e) {
      _view.showMessage('Failed to add user to chat list: $e');
    }
    _view.hideLoading();
  }
}
