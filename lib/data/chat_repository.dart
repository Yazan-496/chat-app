import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_chat_app/model/chat.dart';
import 'package:my_chat_app/model/relationship.dart';
import 'package:my_chat_app/model/user.dart';
import 'package:my_chat_app/data/user_repository.dart';
import 'package:my_chat_app/model/relationship.dart'; // Ensure Relationship is imported
import 'package:my_chat_app/model/message.dart';
// dart:io and firebase_storage removed because not used in this repository file
import 'package:collection/collection.dart'; // For firstWhereOrNull

/// Repository for managing chat and message data in Firestore.
/// It handles all interactions with the 'chats' and 'messages' collections.
class ChatRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _relationshipsCollection = FirebaseFirestore.instance.collection('relationships');
  final UserRepository _userRepository = UserRepository();

  /// Retrieves a single chat by its ID.
  Future<Chat?> getChatById(String chatId) async {
    DocumentSnapshot doc = await _firestore.collection('chats').doc(chatId).get();
    if (doc.exists) {
      return Chat.fromMap(doc.data() as Map<String, dynamic>);
    } else {
      return null;
    }
  }

  /// Retrieves a stream of chats for a given user.
  /// Chats are ordered by the last message time, with the most recent first.
  Stream<List<Chat>> getChatsForUser(String userId) {
    return _firestore
        .collection('chats')
        .where('participantIds', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      print('ChatRepository: Received chat snapshot with ${snapshot.docs.length} documents.');
      List<Chat> chats = [];
      for (var doc in snapshot.docs) {
        final chatData = doc.data() as Map<String, dynamic>;
        final participantIds = List<String>.from(chatData['participantIds']);
        final otherParticipantId = participantIds.firstWhereOrNull((id) => id != userId);

        if (otherParticipantId == null) {
          print('ChatRepository: Could not find other participant ID for chat ${doc.id}. Skipping.');
          continue; // Skip to the next chat document
        }

        print('ChatRepository: Fetching other user with ID: $otherParticipantId');
        final otherUser = await _userRepository.getUser(otherParticipantId);

        if (otherUser != null) {
          print('ChatRepository: Found other user: ${otherUser.username}');
          chats.add(Chat(
            id: doc.id,
            participantIds: participantIds,
            otherUserName: otherUser.username,
            otherUserProfilePictureUrl: otherUser.profilePictureUrl,
            relationshipType: RelationshipType.values.firstWhereOrNull(
                (e) => e.toString() == 'RelationshipType.' + (chatData['relationshipType'] as String)) ?? RelationshipType.friend,
            lastMessageTime: DateTime.parse(chatData['lastMessageTime'] as String),
            lastMessageContent: chatData['lastMessageContent'] as String?,
          ));
        }
      }
      return chats;
    });
  }

  /// Generates a deterministic chat ID based on two user IDs.
  /// This ensures that there's only one chat document for any pair of users.
  String _generateChatId(String userId1, String userId2) {
    List<String> userIds = [userId1, userId2]..sort();
    return userIds.join('_');
  }

  /// Returns a stream of the chat document snapshots for the given chatId.
  Stream<DocumentSnapshot> getChatDocStream(String chatId) {
    return _firestore.collection('chats').doc(chatId).snapshots();
  }

  /// Creates a new chat between two users if it doesn't already exist.
  Future<Chat> createChat(
      {required String currentUserId, required User otherUser, required RelationshipType relationshipType}) async {
    final chatId = _generateChatId(currentUserId, otherUser.uid);
    final chatRef = _firestore.collection('chats').doc(chatId);

    // Check if chat already exists
    final doc = await chatRef.get();
    if (doc.exists) {
      return Chat.fromMap(doc.data() as Map<String, dynamic>); // Corrected casting
    }

    final newChat = Chat(
      id: chatId,
      participantIds: [currentUserId, otherUser.uid],
      otherUserName: otherUser.username,
      otherUserProfilePictureUrl: otherUser.profilePictureUrl,
      relationshipType: relationshipType,
      lastMessageTime: DateTime.now(), // Initial message time
      lastMessageContent: null,
    );

    await chatRef.set(newChat.toMap());
    return newChat;
  }

  /// Sends a new message to a chat.
  /// Also updates the 'lastMessageTime' and 'lastMessageContent' fields in the chat document.
  Future<void> sendMessage(Message message) async {
    final chatRef = _firestore.collection('chats').doc(message.chatId);
    final messageRef = chatRef.collection('messages').doc(message.id);

    await messageRef.set(message.toMap());
    // Update status to sent after successful initial write
    await updateMessageStatus(message.chatId, message.id, MessageStatus.sent);
    // Update last message in chat for real-time chat list updates
    await chatRef.update({
      'lastMessageTime': message.timestamp.toIso8601String(),
      'lastMessageContent': message.type == MessageType.text ? message.content : '[${message.type.name} message]',
      'lastMessageSenderId': message.senderId, // Update with sender ID
      'lastMessageStatus': message.status.toString().split('.').last, // Update with message status
    });
  }

  /// Sets typing status for a given user in a chat.
  Future<void> setTypingStatus(String chatId, String userId, bool isTyping) async {
    try {
      final chatRef = _firestore.collection('chats').doc(chatId);
      await chatRef.set({
        'typing': {userId: isTyping}
      }, SetOptions(merge: true));
    } catch (e) {
      print('ChatRepository: Failed to set typing status for $userId in $chatId: $e');
    }
  }

  /// Retrieves a stream of messages for a given chat.
  /// Messages are ordered by timestamp, with the most recent first.
  Stream<List<Message>> getChatMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
          try {
            return Message.fromMap(doc.data());
          } catch (e) {
            print('ChatRepository: Error parsing message document ${doc.id}: $e. Data: ${doc.data()}');
            // Return a dummy message or rethrow, depending on desired error handling
            // For now, returning a dummy message to prevent crash and continue processing other messages
            return Message(
              id: doc.id,
              chatId: chatId, // Use the current chatId
              senderId: 'unknown',
              receiverId: 'unknown',
              type: MessageType.text,
              content: 'Error loading message',
              timestamp: DateTime.now(),
              status: MessageStatus.delivered,
            );
          }
        }).toList());
  }

  /// Updates the status of a specific message (e.g., sent, delivered, read).
  Future<void> updateMessageStatus(String chatId, String messageId, MessageStatus status) async {
    await _firestore.collection('chats').doc(chatId).collection('messages').doc(messageId).update({
      'status': status.toString().split('.').last,
    });
  }

  /// Edits the text content of an existing message.
  Future<void> editTextMessage(String chatId, String messageId, String newContent) async {
    await _firestore.collection('chats').doc(chatId).collection('messages').doc(messageId).update({
      'editedContent': newContent,
    });
  }

  /// Adds an emoji reaction to a message.
  Future<void> addReactionToMessage(String chatId, String messageId, String userId, String emoji) async {
    await _firestore.collection('chats').doc(chatId).collection('messages').doc(messageId).update({
      'reactions.$userId': emoji,
    });
  }

  /// Removes an emoji reaction from a message.
  Future<void> removeReactionFromMessage(String chatId, String messageId, String userId) async {
    await _firestore.collection('chats').doc(chatId).collection('messages').doc(messageId).update({
      'reactions.${userId}': FieldValue.delete(),
    });
  }

  /// Deletes a chat and all its messages.
  /// This is a critical operation as it recursively deletes subcollections.
  Future<void> deleteChat(String chatId) async {
    final chatRef = _firestore.collection('chats').doc(chatId);

    // Delete all messages in the subcollection first
    final messagesSnapshot = await chatRef.collection('messages').get();
    for (var doc in messagesSnapshot.docs) {
      await doc.reference.delete();
    }
    print('ChatRepository: Deleted all messages for chat $chatId');

    // Then delete the chat document itself
    await chatRef.delete();
    print('ChatRepository: Deleted chat document $chatId');
  }

  /// Creates or updates a relationship between two users.
  Future<void> createOrUpdateRelationship(String user1Id, String user2Id, RelationshipType type) async {
    final relationshipId = _generateChatId(user1Id, user2Id); // Re-using chat ID generation for relationship ID
    final relationshipRef = _relationshipsCollection.doc(relationshipId);

    final relationship = Relationship(
      id: relationshipId,
      userId1: user1Id,
      userId2: user2Id,
      type: type,
      createdAt: DateTime.now(),
    );

    await relationshipRef.set(relationship.toMap(), SetOptions(merge: true));
  }

  /// Retrieves a specific relationship between two users.
  Future<Relationship?> getRelationship(String user1Id, String user2Id) async {
    final relationshipId = _generateChatId(user1Id, user2Id);
    final doc = await _relationshipsCollection.doc(relationshipId).get();
    if (doc.exists) {
      return Relationship.fromMap(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  /// Retrieves a stream of a specific relationship between two users.
  Stream<Relationship?> streamRelationship(String user1Id, String user2Id) {
    final relationshipId = _generateChatId(user1Id, user2Id);
    return _relationshipsCollection.doc(relationshipId).snapshots().map((snapshot) {
      if (snapshot.exists) {
        return Relationship.fromMap(snapshot.data() as Map<String, dynamic>);
      }
      return null;
    });
  }
}
