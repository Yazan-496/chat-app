import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:my_chat_app/data/chat_repository.dart';
import 'package:my_chat_app/data/message_repository.dart';
import 'package:my_chat_app/data/user_repository.dart';
import 'package:my_chat_app/model/chat_summary.dart';
import 'package:my_chat_app/model/delivered_status.dart';
import 'package:my_chat_app/model/message.dart';
import 'package:my_chat_app/model/private_chat.dart';
import 'package:my_chat_app/model/profile.dart';
import 'package:my_chat_app/view/home_view.dart';
import 'package:my_chat_app/services/database_service.dart';
import 'dart:async';

class HomePresenter {
  final HomeView _view;
  final ChatRepository _chatRepository;
  final MessageRepository _messageRepository;
  final UserRepository _userRepository;
  final SupabaseClient _supabase = Supabase.instance.client;
  List<ChatSummary> _chats = [];
  final Map<String, StreamSubscription> _statusSubscriptions = {};
  StreamSubscription<List<PrivateChat>>? _chatsSubscription;

  HomePresenter(this._view)
      : _chatRepository = ChatRepository(),
        _messageRepository = MessageRepository(),
        _userRepository = UserRepository();

  List<ChatSummary> get chats => _chats;

  void loadChats({bool showLoading = true}) {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      _view.displayChats([]);
      _view.hideLoading();
      return;
    }

    if (showLoading) {
      _view.showLoading();
    }
    
    _chatsSubscription?.cancel();
    _chatsSubscription = _chatRepository.streamForUser(user.id).listen(
      (chats) async {
        _chats = await _buildChatSummaries(chats, user.id);
        _view.displayChats(_chats);
        if (showLoading) {
          _view.hideLoading();
        }
        
        // Subscribe to status updates for each chat's other user
        for (var chat in _chats) {
          final otherUserId = _getOtherUserId(chat.chat, user.id);
          if (otherUserId.isNotEmpty && !_statusSubscriptions.containsKey(otherUserId)) {
            _statusSubscriptions[otherUserId] = _userRepository.getCurrentUserStream(otherUserId).listen((updatedUser) {
              if (updatedUser != null) {
                _view.updateUserStatus(
                  otherUserId,
                  updatedUser.status == UserStatus.online,
                  updatedUser.lastSeen,
                );
              }
            });
          }
        }
      },
      onError: (error) {
        debugPrint('HomePresenter: Error loading chats: $error');
        // Only clear chats if we don't have any yet (initial load failure)
        // If we have local chats, keep them.
        if (_chats.isEmpty) {
          _view.displayChats(<ChatSummary>[]);
        }
        if (showLoading) {
          _view.hideLoading();
        }
      },
    );
  }

  Future<void> refreshChats() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      // 1. Sync any pending messages sent while offline
      await DatabaseService.syncPendingChanges();

      // 2. Force a manual fetch of chats
      final chatsData = await _chatRepository.streamForUser(user.id).first;
      _chats = await _buildChatSummaries(chatsData, user.id);
      _view.displayChats(_chats);

      // 3. Restart subscriptions without showing full loading state
      loadChats(showLoading: false);
    } catch (e) {
      debugPrint('HomePresenter: Error refreshing chats: $e');
    }
  }

  Future<void> syncPendingMessages() async {
    await DatabaseService.syncPendingChanges();
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
      await _chatRepository.delete(chatId);
      _view.showMessage('Chat deleted successfully.');
      loadChats();
    } catch (e) {
      _view.showMessage('Failed to delete chat: $e');
      _view.hideLoading();
    }
  }

  Future<ChatSummary?> getChat(String chatId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    try {
      final chat = await _chatRepository.fetchById(chatId);
      if (chat == null) return null;

      return await _buildChatSummary(chat, user.id);
    } catch (e) {
      debugPrint('Error fetching single chat: $e');
      return null;
    }
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
    _view.navigateToLogin();
  }

  String _getOtherUserId(PrivateChat chat, String currentUserId) {
    return chat.userOneId == currentUserId ? chat.userTwoId : chat.userOneId;
  }

  Future<List<ChatSummary>> _buildChatSummaries(
    List<PrivateChat> chats,
    String currentUserId,
  ) async {
    final summaries = await Future.wait(
      chats.map((chat) => _buildChatSummary(chat, currentUserId)),
    );
    summaries.sort((a, b) {
      final aTime = a.lastMessage?.createdAt ?? a.chat.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.lastMessage?.createdAt ?? b.chat.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
    return summaries;
  }

  Future<ChatSummary> _buildChatSummary(
    PrivateChat chat,
    String currentUserId,
  ) async {
    final otherUserId = _getOtherUserId(chat, currentUserId);
    final otherProfile = await _userRepository.getUser(otherUserId) ??
        Profile(
          id: otherUserId,
          username: otherUserId,
          displayName: otherUserId,
        );
    Message? lastMessage;
    if (chat.lastMessageId != null) {
      lastMessage = await _messageRepository.fetchById(chat.lastMessageId!);
    }
    final participant = await _chatRepository.fetchParticipant(chat.id, currentUserId);
    final deliveredStatus = DeliveredStatus(
      lastDeliveredMessageId: participant?.lastDeliveredMessageId,
      lastReadMessageId: participant?.lastReadMessageId,
    );
    return ChatSummary(
      chat: chat,
      otherProfile: otherProfile,
      lastMessage: lastMessage,
      unreadCount: participant?.unreadCount ?? 0,
      deliveredStatus: deliveredStatus,
    );
  }
}
