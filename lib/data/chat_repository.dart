import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:my_chat_app/model/chat.dart';
import 'package:my_chat_app/model/relationship.dart';
import 'package:my_chat_app/model/user.dart' as app_user;
import 'package:my_chat_app/data/user_repository.dart';
import 'package:my_chat_app/model/message.dart';
import 'package:collection/collection.dart';
import 'package:my_chat_app/notification_service.dart';
import 'dart:convert';

/// Repository for managing chat and message data in Supabase.
/// It handles all interactions with the 'chats' and 'messages' tables.
class ChatRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  final UserRepository _userRepository = UserRepository();
  final _uuid = const Uuid();
  static const _chatNamespace = '6ba7b810-9dad-11d1-80b4-00c04fd430c8'; // Random UUID as namespace

  /// Retrieves a single chat by its ID.
  Future<Chat?> getChatById(String chatId) async {
    final data = await _supabase
        .from('chats')
        .select()
        .eq('id', chatId)
        .maybeSingle();
    
    if (data != null) {
      final chat = Chat.fromMap(data);
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId != null) {
        final otherParticipantId = chat.participantIds.firstWhereOrNull((id) => id != currentUserId);
        if (otherParticipantId != null) {
          final otherUser = await _userRepository.getUser(otherParticipantId);
          if (otherUser != null) {
            return chat.copyWith(
              displayName: otherUser.displayName,
              profilePictureUrl: otherUser.profilePictureUrl,
              avatarColor: otherUser.avatarColor,
              isOnline: otherUser.isOnline,
              lastSeen: otherUser.lastSeen,
            );
          }
        }
      }
      return chat;
    } else {
      return null;
    }
  }

  /// Retrieves a stream of chats for a given user.
  /// Chats are ordered by the last message time, with the most recent first.
  Stream<List<Chat>> getChatsForUser(String userId) {
    return _supabase
        .from('chats')
        .stream(primaryKey: ['id'])
        .order('last_message_time', ascending: false)
        .asyncMap((data) async {
          return _processChatsData(data, userId);
        })
        .handleError((error) {
          print('ChatRepository: Stream error in getChatsForUser: $error');
          return <Chat>[]; // Return empty list on error
        });
  }

  /// Fetches chats for a user manually (one-time fetch).
  Future<List<Chat>> fetchChatsForUser(String userId) async {
    final data = await _supabase
        .from('chats')
        .select()
        .order('last_message_time', ascending: false);
    return _processChatsData(data, userId);
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
    return newChat;
  }

  /// Sends a new message to a chat.
  Future<String?> sendMessage(Message message) async {
    try {
      await _supabase.from('messages').insert(message.toMap());

      // Update status to sent after successful initial write
      await updateMessageStatus(message.chatId, message.id, MessageStatus.sent);
      
      // Update last message in chat
      await _supabase.from('chats').update({
        'last_message_time': DateTime.now().toUtc().toIso8601String(),
        'last_message_content': message.type == MessageType.text ? message.content : '[${message.type.name} message]',
        'last_message_sender_id': message.senderId,
        'last_message_status': message.status.toString().split('.').last,
      }).eq('id', message.chatId);
      return null;
    } catch (e) {
      print('ChatRepository: Error sending message: $e');
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
  Stream<List<Message>> getChatMessages(String chatId) {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', chatId)
        .order('timestamp', ascending: false)
        .handleError((error) {
          print('ChatRepository: Stream error: $error');
        })
        .map((data) {
          return data.map((map) {
            try {
              return Message.fromMap(map);
            } catch (e) {
              print('ChatRepository: Error parsing message: $e');
              return Message(
                id: map['id'] ?? 'unknown',
                chatId: chatId,
                senderId: 'unknown',
                receiverId: 'unknown',
                type: MessageType.text,
                content: 'Error loading message',
                timestamp: DateTime.now(),
                status: MessageStatus.delivered,
              );
            }
          }).toList();
        });
  }

  /// Updates the status of a specific message.
  Future<void> updateMessageStatus(String chatId, String messageId, MessageStatus status) async {
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
    
    for (var entry in updates.entries) {
      await updateMessageStatus(chatId, entry.key, entry.value);
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
