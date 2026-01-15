import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_chat_app/data/chat_repository.dart';
import 'package:my_chat_app/data/user_repository.dart';
import 'package:my_chat_app/model/chat.dart';
import 'package:my_chat_app/model/user.dart' as model;
import 'package:my_chat_app/view/home_view.dart';
import 'dart:async';

class HomePresenter {
  final HomeView _view;
  final ChatRepository _chatRepository;
  final UserRepository _userRepository;
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Chat> _chats = [];
  final Map<String, StreamSubscription> _statusSubscriptions = {};
  StreamSubscription<List<Chat>>? _chatsSubscription;

  HomePresenter(this._view)
      : _chatRepository = ChatRepository(),
        _userRepository = UserRepository();

  List<Chat> get chats => _chats;

  void loadChats() {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      _view.displayChats([]);
      _view.hideLoading();
      return;
    }

    _view.showLoading();
    
    _chatsSubscription?.cancel();
    _chatsSubscription = _chatRepository.getChatsForUser(user.id).listen(
      (chats) async {
        _chats = chats;
        _view.displayChats(_chats);
        _view.hideLoading();
        
        // Subscribe to status updates for each chat's other user
        for (var chat in _chats) {
          final otherUserId = chat.participantIds.firstWhere((id) => id != user.id, orElse: () => '');
          if (otherUserId.isNotEmpty && !_statusSubscriptions.containsKey(otherUserId)) {
            _statusSubscriptions[otherUserId] = _userRepository.getCurrentUserStream(otherUserId).listen((updatedUser) {
              if (updatedUser != null) {
                _view.updateUserStatus(otherUserId, updatedUser.isOnline, updatedUser.lastSeen);
              }
            });
          }
        }
      },
      onError: (error) {
        print('HomePresenter: Error loading chats: $error');
        _view.displayChats([]);
        _view.hideLoading();
      },
    );
  }

  Future<void> refreshChats() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    _view.showLoading();
    try {
      // 1. Force a manual fetch of chats
      final chatsData = await _chatRepository.fetchChatsForUser(user.id);
      _chats = chatsData;
      _view.displayChats(_chats);

      // 2. Restart subscriptions
      loadChats();
    } catch (e) {
      print('HomePresenter: Error refreshing chats: $e');
    } finally {
      _view.hideLoading();
    }
  }

  void dispose() {
    _chatsSubscription?.cancel();
    for (var sub in _statusSubscriptions.values) {
      sub.cancel();
    }
    _statusSubscriptions.clear();
  }

  Future<void> deleteChat(String chatId) async {
    _view.showLoading();
    try {
      await _chatRepository.deleteChat(chatId);
      _view.showMessage('Chat deleted successfully.');
      loadChats();
    } catch (e) {
      _view.showMessage('Failed to delete chat: $e');
      _view.hideLoading();
    }
  }

  Future<Chat?> getChat(String chatId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    try {
      final chat = await _chatRepository.getChatById(chatId);
      if (chat == null) return null;

      final otherUserId = chat.participantIds.firstWhere((id) => id != user.id, orElse: () => '');
      if (otherUserId.isEmpty) return chat;

      final otherUser = await _userRepository.getUser(otherUserId);
      if (otherUser != null) {
        return chat.copyWith(
          displayName: otherUser.displayName,
          profilePictureUrl: otherUser.profilePictureUrl,
          isOnline: otherUser.isOnline,
          lastSeen: otherUser.lastSeen,
        );
      }
      return chat;
    } catch (e) {
      print('Error fetching single chat: $e');
      return null;
    }
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
    _view.navigateToLogin();
  }
}
