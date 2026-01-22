import 'package:flutter/foundation.dart';
import 'package:my_chat_app/data/user_repository.dart';
import 'package:my_chat_app/model/profile.dart' as app_user;
import 'package:my_chat_app/view/user_discovery_view.dart';
import 'package:my_chat_app/data/chat_repository.dart';
import 'package:my_chat_app/model/user_relationship.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserDiscoveryPresenter {
  final UserDiscoveryView _view;
  final UserRepository _userRepository;
  final ChatRepository _chatRepository;
  final SupabaseClient _supabase = Supabase.instance.client;
  List<app_user.Profile> _searchResults = [];

  UserDiscoveryPresenter(this._view)
      : _userRepository = UserRepository(),
        _chatRepository = ChatRepository();

  List<app_user.Profile> get searchResults => _searchResults;

  Future<void> searchUsers(String query) async {
    debugPrint('DEBUG: UserDiscoveryPresenter.searchUsers called with query: "$query"');
    _view.showLoading();
    try {
      final user = _supabase.auth.currentUser;
      debugPrint('DEBUG: Current user ID: ${user?.id}');
      // We allow searching even if not authenticated (using anon key)
      // to support the user's request for unauthorized profile access.
      _searchResults = await _userRepository.searchUsersByUsername(query, user?.id ?? '');
      debugPrint('DEBUG: Presenter received ${_searchResults.length} users from repository');
      _view.displaySearchResults(_searchResults);
    } catch (e) {
      debugPrint('DEBUG: UserDiscoveryPresenter ERROR: $e');
      _view.showMessage('Error searching users: $e');
    }
    _view.hideLoading();
  }

  Future<void> addUserToChatList(app_user.Profile otherUser, RelationshipType relationshipType) async {
    _view.showLoading();
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        _view.showMessage('User not authenticated.');
        _view.hideLoading();
        return;
      }
      await _chatRepository.getOrCreateChat(otherUser.id);
      _view.showMessage('${otherUser.displayName} added to chat list as ${relationshipType.name}!');
    } catch (e) {
      _view.showMessage('Failed to add user to chat list: $e');
    }
    _view.hideLoading();
  }
}
