import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_chat_app/data/chat_repository.dart';
import 'package:my_chat_app/data/user_repository.dart'; // New import
import 'package:my_chat_app/model/chat.dart';
import 'package:my_chat_app/model/user.dart' as model; // New import
import 'package:my_chat_app/view/home_view.dart';
import 'dart:async'; // New import

class HomePresenter {
  final HomeView _view;
  final ChatRepository _chatRepository;
  final UserRepository _userRepository; // New instance
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  List<Chat> _chats = [];
  final Map<String, StreamSubscription> _statusSubscriptions = {}; // To manage status subscriptions
  StreamSubscription<List<Chat>>? _chatsSubscription; // Track chats stream subscription

  HomePresenter(this._view) : _chatRepository = ChatRepository(), _userRepository = UserRepository(); // Initialize UserRepository

  List<Chat> get chats => _chats;

  void loadChats() {
    final currentUserId = _firebaseAuth.currentUser?.uid;
    if (currentUserId == null) {
      _view.showMessage('User not authenticated.');
      return;
    }

    // Cancel existing subscription if any
    _chatsSubscription?.cancel();
    
    _view.showLoading();
    _chatsSubscription = _chatRepository.getChatsForUser(currentUserId).listen(
      (chats) {
        _chats = chats;
        _view.displayChats(_chats);

        // Update other users' statuses for each chat
        for (var chat in _chats) {
          final otherUserId = chat.getOtherUserId(currentUserId);
          // Cancel existing subscription if any
          _statusSubscriptions[otherUserId]?.cancel();
          _statusSubscriptions[otherUserId] = _userRepository.streamUserStatus(otherUserId).listen((otherUser) {
            if (otherUser != null) {
              final index = _chats.indexWhere((c) => c.id == chat.id);
              if (index != -1) {
                _chats[index] = _chats[index].copyWith(
                  otherUserIsOnline: otherUser.isOnline,
                  otherUserLastSeen: otherUser.lastSeen,
                );
                _view.updateView(); // Notify UI to rebuild with updated status
              }
            }
          });
        }

        _view.hideLoading();
        _view.updateView();
      },
      onError: (error) {
        _view.showMessage('Error loading chats: $error');
        _view.hideLoading();
        _view.updateView();
      },
    );
  }

  Future<void> refreshChats() async {
    // Cancel existing subscriptions
    _chatsSubscription?.cancel();
    for (var subscription in _statusSubscriptions.values) {
      subscription.cancel();
    }
    _statusSubscriptions.clear();
    
    // Reload chats
    loadChats();
    
    // Wait a bit to ensure the refresh animation shows
    await Future.delayed(const Duration(milliseconds: 500));
  }

  void dispose() {
    // Cancel all subscriptions to prevent memory leaks
    _chatsSubscription?.cancel();
    for (var subscription in _statusSubscriptions.values) {
      subscription.cancel();
    }
    _statusSubscriptions.clear();
  }

  Future<void> deleteChat(String chatId) async {
    _view.showLoading();
    try {
      await _chatRepository.deleteChat(chatId);
      _view.showMessage('Chat deleted successfully.');
      // Reload chats to update the UI
      loadChats();
    } catch (e) {
      _view.showMessage('Failed to delete chat: $e');
    } finally {
      _view.hideLoading();
    }
  }
}
