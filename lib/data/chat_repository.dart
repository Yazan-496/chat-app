import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:my_chat_app/model/chat.dart';
import 'package:my_chat_app/model/relationship.dart';
import 'package:my_chat_app/model/user.dart' as app_user;
import 'package:my_chat_app/data/user_repository.dart';
import 'package:my_chat_app/model/message.dart';
import 'package:collection/collection.dart';
import 'package:my_chat_app/notification_service.dart';
import 'package:my_chat_app/services/database_service.dart';
import 'dart:async';
import 'dart:convert';

/// Repository for managing chat and message data in Supabase.
/// It handles all interactions with the 'chats' and 'messages' tables.
class ChatRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  final UserRepository _userRepository = UserRepository();
  final DatabaseService _dbService = DatabaseService();
  final _uuid = const Uuid();
  static const _chatNamespace = '6ba7b810-9dad-11d1-80b4-00c04fd430c8'; // Random UUID as namespace

  // Stream controller to manage combined local and remote messages
  final Map<String, StreamController<List<Message>>> _messageControllers = {};
  final Map<String, StreamSubscription> _messageSubscriptions = {};
  final Map<String, int> _messageLimits = {};

  /// Fetches a specific chat by its ID.
  Future<Chat?> getChatById(String chatId) async {
    // Try local first
    final localChat = await _dbService.getChat(chatId);
    if (localChat != null) return localChat;

    final response = await _supabase.from('chats').select().eq('id', chatId).maybeSingle();
    if (response == null) return null;
    
    // We need current user ID for _processChatsData
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final processed = await _processChatsData([response], userId);
    if (processed.isNotEmpty) {
      await _dbService.saveChats([processed.first]);
      return processed.first;
    }
    return null;
  }

  /// Retrieves a stream of chats for a given user.
  /// Offline-First: Emits local data first, then listens to Supabase for updates.
  Stream<List<Chat>> getChatsForUser(String userId) {
    final controller = StreamController<List<Chat>>.broadcast();

    // 1. Load from local database immediately
    _loadLocalChats(userId, controller);

    // 2. Setup Supabase stream
    final subscription = _supabase
        .from('chats')
        .stream(primaryKey: ['id'])
        .order('last_message_time', ascending: false)
        .listen((data) async {
          final processed = await _processChatsData(data, userId);
          // Save to local DB for offline access
          await _dbService.saveChats(processed);
          if (!controller.isClosed) {
            controller.add(processed);
          }
        }, onError: (error) {
          print('ChatRepository: Stream error in getChatsForUser: $error');
        });

    controller.onCancel = () => subscription.cancel();
    return controller.stream;
  }

  Future<void> _loadLocalChats(String userId, StreamController<List<Chat>> controller) async {
    final localChats = await _dbService.getAllChats();
    // Filter by participantIds locally since Isar doesn't support complex collection filtering easily in this setup
    final filtered = localChats.where((c) => c.participantIds.contains(userId)).toList();
    if (!controller.isClosed) {
      controller.add(filtered);
    }
  }

  /// Fetches chats for a user manually (one-time fetch).
  Future<List<Chat>> fetchChatsForUser(String userId) async {
    final data = await _supabase
        .from('chats')
        .select()
        .order('last_message_time', ascending: false);
    final processed = await _processChatsData(data, userId);
    await _dbService.saveChats(processed);
    return processed;
  }

  /// Common logic to process raw chat data into Chat models.
  Future<List<Chat>> _processChatsData(List<Map<String, dynamic>> data, String userId) async {
    print('ChatRepository: Processing ${data.length} chat documents.');
    List<Chat> chats = [];
    for (var chatData in data) {
      final participantIds = List<String>.from(chatData['participant_ids'] ?? []);
      if (!participantIds.contains(userId)) continue;

      final otherParticipantId = participantIds.firstWhereOrNull((id) => id != userId);

      if (otherParticipantId == null) {
        print('ChatRepository: Could not find other participant ID for chat ${chatData['id']}. Skipping.');
        continue;
      }

      final otherUser = await _userRepository.getUser(otherParticipantId);

      if (otherUser != null) {
        // Fetch unread messages count for this chat
        final unreadRes = await _supabase
            .from('messages')
            .select('id')
            .eq('chat_id', chatData['id'])
            .eq('receiver_id', userId)
            .neq('status', 'read');
        
        final unreadCount = unreadRes.length;

        chats.add(Chat(
          id: chatData['id'],
          participantIds: participantIds,
          displayName: otherUser.displayName,
          profilePictureUrl: otherUser.profilePictureUrl,
          avatarColor: otherUser.avatarColor,
          relationshipType: RelationshipType.values.firstWhereOrNull(
              (e) => e.toString() == 'RelationshipType.' + (chatData['relationship_type'] ?? 'friend').toString()) ?? RelationshipType.friend,
          lastMessageTime: chatData['last_message_time'] != null 
              ? DateTime.tryParse(chatData['last_message_time'].toString())?.toUtc() ?? DateTime.now().toUtc() 
              : DateTime.now().toUtc(),
          lastMessageContent: chatData['last_message_content'] as String?,
          lastMessageSenderId: chatData['last_message_sender_id'] as String?,
          lastMessageStatus: chatData['last_message_status'] != null
              ? MessageStatus.values.firstWhere(
                  (e) => e.toString().split('.').last == chatData['last_message_status'].toString(),
                  orElse: () => MessageStatus.sent)
              : MessageStatus.sent,
          unreadCount: unreadCount,
          isOnline: otherUser.isOnline,
          lastSeen: otherUser.lastSeen,
        ));
      }
    }
    return chats;
  }

  /// Generates a deterministic chat ID based on two user IDs.
  String _generateChatId(String userId1, String userId2) {
    List<String> userIds = [userId1, userId2]..sort();
    final combined = userIds.join('_');
    // Using v5 to generate a deterministic UUID from the combined user IDs
    return _uuid.v5(_chatNamespace, combined);
  }

  /// Returns a stream of the chat document for the given chatId.
  Stream<Map<String, dynamic>> getChatDocStream(String chatId) {
    return _supabase
        .from('chats')
        .stream(primaryKey: ['id'])
        .eq('id', chatId)
        .map((data) => data.isNotEmpty ? data.first : {});
  }

  /// Creates a new chat between two users if it doesn't already exist.
  Future<Chat> createChat(
      {required String currentUserId, required app_user.User otherUser, required RelationshipType relationshipType}) async {
    final chatId = _generateChatId(currentUserId, otherUser.uid);
    
    final existingChat = await getChatById(chatId);
    if (existingChat != null) {
      return existingChat;
    }

    final newChat = Chat(
      id: chatId,
      participantIds: [currentUserId, otherUser.uid],
      displayName: otherUser.displayName,
      profilePictureUrl: otherUser.profilePictureUrl,
      avatarColor: otherUser.avatarColor,
      relationshipType: relationshipType,
      lastMessageTime: DateTime.now().toUtc(),
      lastMessageContent: null,
    );

    await _supabase.from('chats').insert(newChat.toMap());
    await _dbService.saveChats([newChat]);
    return newChat;
  }

  /// Sends a new message to a chat.
  /// Offline-First: Saves to local DB immediately (Optimistic UI), then uploads to Supabase.
  Future<String?> sendMessage(Message message) async {
    try {
      // 1. Save to local database immediately with 'sending' status
      await _dbService.saveMessages([message]);
      
      // Update the local stream if it exists
      if (_messageControllers.containsKey(message.chatId)) {
        final limit = _messageLimits[message.chatId] ?? 100;
        final localMessages = await _dbService.getMessages(message.chatId, limit: limit);
        _messageControllers[message.chatId]!.add(localMessages);
      }

      // Update local chat last message immediately (Optimistic Chat List)
      final localChat = await _dbService.getChat(message.chatId);
      if (localChat != null) {
        final updatedChat = localChat.copyWith(
          lastMessageTime: message.timestamp,
          lastMessageContent: message.type == MessageType.text ? message.content : '[${message.type.name} message]',
          lastMessageSenderId: message.senderId,
          lastMessageStatus: MessageStatus.sending,
        );
        await _dbService.saveChats([updatedChat]);
      }

      // 2. Upload to Supabase
      await _supabase.from('messages').insert(message.toMap());

      // 3. Update status to 'sent' after successful initial write
      await updateMessageStatus(message.chatId, message.id, MessageStatus.sent);
      
      // 4. Update last message in chat in Supabase
      await _supabase.from('chats').update({
        'last_message_time': DateTime.now().toUtc().toIso8601String(),
        'last_message_content': message.type == MessageType.text ? message.content : '[${message.type.name} message]',
        'last_message_sender_id': message.senderId,
        'last_message_status': MessageStatus.sent.toString().split('.').last,
      }).eq('id', message.chatId);

      return null;
    } catch (e) {
      print('ChatRepository: Error sending message: $e');
      // Status remains 'sending' locally, could implement a retry mechanism here
      return e.toString();
    }
  }

  /// Sets typing status for a given user in a chat.
  Future<void> setTypingStatus(String chatId, String userId, bool isTyping) async {
    try {
      // Fetch current typing map
      final res = await _supabase.from('chats').select('typing_status').eq('id', chatId).single();
      Map<String, dynamic> typing = Map<String, dynamic>.from(res['typing_status'] ?? {});
      typing[userId] = isTyping;
      
      await _supabase.from('chats').update({
        'typing_status': typing,
      }).eq('id', chatId);
    } catch (e) {
      print('ChatRepository: Failed to set typing status for $userId in $chatId: $e');
    }
  }

  /// Retrieves a stream of messages for a given chat.
  /// Offline-First: Emits local data immediately, then syncs with Supabase.
  Stream<List<Message>> getChatMessages(String chatId) {
    if (_messageControllers.containsKey(chatId)) {
      return _messageControllers[chatId]!.stream;
    }

    final controller = StreamController<List<Message>>.broadcast();
    _messageControllers[chatId] = controller;
    _messageLimits[chatId] = 100; // Initial limit

    // 1. Load initial 100 messages from local database
    _loadInitialLocalMessages(chatId, controller);

    // 2. Setup Supabase stream for real-time updates
    _setupSupabaseStream(chatId, controller);

    // 3. Perform background sync for missed messages
    _syncMissedMessages(chatId);

    return controller.stream;
  }

  Future<void> _loadInitialLocalMessages(String chatId, StreamController<List<Message>> controller) async {
    final limit = _messageLimits[chatId] ?? 100;
    final localMessages = await _dbService.getMessages(chatId, limit: limit);
    if (!controller.isClosed) {
      controller.add(localMessages);
    }
  }

  void _setupSupabaseStream(String chatId, StreamController<List<Message>> controller) {
    _messageSubscriptions[chatId]?.cancel();
    _messageSubscriptions[chatId] = _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', chatId)
        .order('timestamp', ascending: false)
        .listen((data) async {
          final messages = data.map((m) => Message.fromMap(m)).toList();
          // Save all incoming messages to local cache
          await _dbService.saveMessages(messages);
          
          // Re-fetch from local DB to ensure consistent ordering and pagination
          final limit = _messageLimits[chatId] ?? 100;
          final updatedLocal = await _dbService.getMessages(chatId, limit: limit);
          if (!controller.isClosed) {
            controller.add(updatedLocal);
          }
        }, onError: (error) {
          print('ChatRepository: Supabase stream error for $chatId: $error');
        });
  }

  Future<void> _syncMissedMessages(String chatId) async {
    try {
      final lastLocal = await _dbService.getLastMessage(chatId);
      final query = _supabase.from('messages').select().eq('chat_id', chatId);
      
      if (lastLocal != null) {
        query.gt('timestamp', lastLocal.timestamp.toUtc().toIso8601String());
      }

      final data = await query.order('timestamp', ascending: false);
      if (data.isNotEmpty) {
        final newMessages = (data as List).map((m) => Message.fromMap(m)).toList();
        await _dbService.saveMessages(newMessages);
        print('ChatRepository: Synced ${newMessages.length} new messages for $chatId');
      }
    } catch (e) {
      print('ChatRepository: Background sync failed for $chatId: $e');
    }
  }

  /// Loads older messages from local DB for pagination.
  /// If local data is exhausted, it could optionally fetch from Supabase.
  Future<List<Message>> loadOlderMessages(String chatId, int currentCount) async {
    final older = await _dbService.getMessages(chatId, limit: 100, offset: currentCount);
    
    // Update the limit for the stream so new messages don't truncate the list
    _messageLimits[chatId] = currentCount + 100;

    if (older.isEmpty) {
      // Local exhausted, try fetching from Supabase
      final lastLocal = await _dbService.getMessages(chatId, limit: 1, offset: currentCount - 1);
      if (lastLocal.isNotEmpty) {
        final data = await _supabase
            .from('messages')
            .select()
            .eq('chat_id', chatId)
            .lt('timestamp', lastLocal.first.timestamp.toUtc().toIso8601String())
            .order('timestamp', ascending: false)
            .limit(100);
        
        if (data.isNotEmpty) {
          final fetched = (data as List).map((m) => Message.fromMap(m)).toList();
          await _dbService.saveMessages(fetched);
          return fetched;
        }
      }
    }
    return older;
  }

  /// Stops the stream for a specific chat.
  void disposeChatStream(String chatId) {
    _messageSubscriptions[chatId]?.cancel();
    _messageSubscriptions.remove(chatId);
    _messageControllers[chatId]?.close();
    _messageControllers.remove(chatId);
  }

  /// Updates the status of a specific message.
  Future<void> updateMessageStatus(String chatId, String messageId, MessageStatus status) async {
    // 1. Update local database
    final localMessage = await _dbService.getMessage(messageId);
    if (localMessage != null) {
      localMessage.status = status;
      await _dbService.saveMessages([localMessage]);
      
      // Update local chat last message status if this is the last message
      final localChat = await _dbService.getChat(chatId);
      if (localChat != null && localChat.lastMessageTime.isAtSameMomentAs(localMessage.timestamp)) {
        final updatedChat = localChat.copyWith(lastMessageStatus: status);
        await _dbService.saveChats([updatedChat]);
      }

      // Update stream if active
      if (_messageControllers.containsKey(chatId)) {
        final limit = _messageLimits[chatId] ?? 100;
        final updated = await _dbService.getMessages(chatId, limit: limit);
        _messageControllers[chatId]!.add(updated);
      }
    }

    // 2. Update Supabase
    await _supabase
        .from('messages')
        .update({'status': status.toString().split('.').last})
        .eq('id', messageId);
    
    if (status == MessageStatus.read || status == MessageStatus.delivered) {
      await _supabase
          .from('chats')
          .update({'last_message_status': status.toString().split('.').last})
          .eq('id', chatId);
    }
  }

  /// Batch update statuses for multiple messages in a chat.
  Future<void> updateMessagesStatusBatch(String chatId, Map<String, MessageStatus> updates) async {
    if (updates.isEmpty) return;
    
    // 1. Update local database in batch
    final messageIds = updates.keys.toList();
    final localMessages = await _dbService.getMessagesByIds(messageIds);
    
    for (var m in localMessages) {
      if (updates.containsKey(m.id)) {
        m.status = updates[m.id]!;
      }
    }
    await _dbService.saveMessages(localMessages);

    // Update stream if active
    if (_messageControllers.containsKey(chatId)) {
      final updated = await _dbService.getMessages(chatId, limit: 100);
      _messageControllers[chatId]!.add(updated);
    }

    // 2. Update Supabase (individually or via RPC if available)
    for (var entry in updates.entries) {
      await _supabase
          .from('messages')
          .update({'status': entry.value.toString().split('.').last})
          .eq('id', entry.key);
    }
  }

  /// Edits the text content of an existing message.
  Future<void> editTextMessage(String chatId, String messageId, String newContent) async {
    await _supabase.from('messages').update({
      'edited_content': newContent,
    }).eq('id', messageId);
  }

  /// Marks a message as deleted and replaces content with a placeholder.
  Future<void> deleteMessage(String chatId, String messageId) async {
    await _supabase.from('messages').update({
      'deleted': true,
      'content': 'Removed message',
      'type': 'text',
    }).eq('id', messageId);
  }

  /// Adds an emoji reaction to a message.
  Future<void> addReactionToMessage(String chatId, String messageId, String userId, String emoji) async {
    // For Supabase, we might want a separate reactions table or use a jsonb column
    // Assuming 'reactions' is a jsonb column in the 'messages' table
    final res = await _supabase.from('messages').select('reactions').eq('id', messageId).single();
    Map<String, dynamic> reactions = Map<String, dynamic>.from(res['reactions'] ?? {});
    reactions[userId] = emoji;
    
    await _supabase.from('messages').update({
      'reactions': reactions,
    }).eq('id', messageId);
  }

  /// Removes an emoji reaction from a message.
  Future<void> removeReactionFromMessage(String chatId, String messageId, String userId) async {
    final res = await _supabase.from('messages').select('reactions').eq('id', messageId).single();
    Map<String, dynamic> reactions = Map<String, dynamic>.from(res['reactions'] ?? {});
    reactions.remove(userId);
    
    await _supabase.from('messages').update({
      'reactions': reactions,
    }).eq('id', messageId);
  }

  /// Deletes a chat and all its messages.
  Future<void> deleteChat(String chatId) async {
    // Delete all messages for the chat
    await _supabase.from('messages').delete().eq('chat_id', chatId);
    print('ChatRepository: Deleted all messages for chat $chatId');

    // Then delete the chat document itself
    await _supabase.from('chats').delete().eq('id', chatId);
    print('ChatRepository: Deleted chat document $chatId');
  }

  /// Creates or updates a relationship between two users.
  Future<void> createOrUpdateRelationship(String user1Id, String user2Id, RelationshipType type) async {
    final relationshipId = _generateChatId(user1Id, user2Id);

    final relationship = Relationship(
      id: relationshipId,
      userId1: user1Id,
      userId2: user2Id,
      type: type,
      createdAt: DateTime.now(),
    );

    await _supabase.from('relationships').upsert(relationship.toMap());
  }

  /// Retrieves a specific relationship between two users.
  Future<Relationship?> getRelationship(String user1Id, String user2Id) async {
    final relationshipId = _generateChatId(user1Id, user2Id);
    final data = await _supabase.from('relationships').select().eq('id', relationshipId).maybeSingle();
    if (data != null) {
      return Relationship.fromMap(data);
    }
    return null;
  }

  /// Retrieves a stream of a specific relationship between two users.
  Stream<Relationship?> streamRelationship(String user1Id, String user2Id) {
    final relationshipId = _generateChatId(user1Id, user2Id);
    return _supabase
        .from('relationships')
        .stream(primaryKey: ['id'])
        .eq('id', relationshipId)
        .map((data) {
      if (data.isNotEmpty) {
        return Relationship.fromMap(data.first);
      }
      return null;
    });
  }
}
