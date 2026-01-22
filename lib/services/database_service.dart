import 'dart:convert';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:my_chat_app/model/message.dart';
import 'package:my_chat_app/model/private_chat.dart';
import 'package:my_chat_app/model/profile.dart';
import 'package:my_chat_app/model/user_relationship.dart';
import 'package:my_chat_app/supabase_client.dart';
import 'package:my_chat_app/utils/isar_utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'database_service.g.dart';

class DatabaseService {
  static late Isar isar;

  static Future<void> initialize() async {
    final dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open(
      [
        LocalMessageSchema,
        LocalChatSchema,
        LocalProfileSchema,
        LocalRelationshipSchema,
        PendingChangeSchema,
      ],
      directory: dir.path,
    );
  }

  static Future<void> saveChats(List<PrivateChat> chats) async {
    final entities = chats.map(_localChatFromModel).toList();
    await isar.writeTxn(() async {
      await isar.localChats.putAll(entities);
    });
  }

  static Future<List<PrivateChat>> getAllChats() async {
    final chats = await isar.localChats.where().sortByCreatedAtDesc().findAll();
    return chats.map(_chatFromLocal).toList();
  }

  static Future<PrivateChat?> getChat(String chatId) async {
    final local = await isar.localChats.filter().chatIdEqualTo(chatId).findFirst();
    if (local == null) {
      return null;
    }
    return _chatFromLocal(local);
  }

  static Future<void> deleteChat(String chatId) async {
    await isar.writeTxn(() async {
      await isar.localChats.filter().chatIdEqualTo(chatId).deleteAll();
    });
  }

  static Future<void> saveMessages(
    List<Message> messages, {
    bool pendingSync = false,
  }) async {
    final entities =
        messages.map((message) => _localMessageFromModel(message, pendingSync)).toList();
    await isar.writeTxn(() async {
      await isar.localMessages.putAll(entities);
    });
  }

  static Future<List<Message>> getMessages(
    String chatId, {
    int limit = 100,
    int offset = 0,
  }) async {
    final messages = await isar.localMessages
        .filter()
        .chatIdEqualTo(chatId)
        .sortByCreatedAtDesc()
        .offset(offset)
        .limit(limit)
        .findAll();
    return messages.map(_messageFromLocal).toList();
  }

  static Future<Message?> getLastMessage(String chatId) async {
    final message = await isar.localMessages
        .filter()
        .chatIdEqualTo(chatId)
        .sortByCreatedAtDesc()
        .findFirst();
    if (message == null) {
      return null;
    }
    return _messageFromLocal(message);
  }

  static Future<Message?> getMessage(String messageId) async {
    final message =
        await isar.localMessages.filter().messageIdEqualTo(messageId).findFirst();
    if (message == null) {
      return null;
    }
    return _messageFromLocal(message);
  }

  static Future<List<Message>> getMessagesByIds(List<String> messageIds) async {
    final messages = await isar.localMessages
        .filter()
        .anyOf(messageIds, (q, String id) => q.messageIdEqualTo(id))
        .findAll();
    return messages.map(_messageFromLocal).toList();
  }

  static Future<List<Message>> getPendingMessages() async {
    final messages = await isar.localMessages
        .filter()
        .pendingSyncEqualTo(true)
        .sortByCreatedAtDesc()
        .findAll();
    return messages.map(_messageFromLocal).toList();
  }

  static Future<void> saveProfiles(List<Profile> profiles) async {
    final entities = profiles.map(_localProfileFromModel).toList();
    await isar.writeTxn(() async {
      await isar.localProfiles.putAll(entities);
    });
  }

  static Future<Profile?> getProfile(String userId) async {
    final local =
        await isar.localProfiles.filter().profileIdEqualTo(userId).findFirst();
    if (local == null) {
      return null;
    }
    return _profileFromLocal(local);
  }

  static Future<void> saveRelationships(
    List<UserRelationship> relationships, {
    bool pendingSync = false,
  }) async {
    await isar.writeTxn(() async {
      for (final relationship in relationships) {
        final existing = await isar.localRelationships
            .filter()
            .relationshipIdEqualTo(relationship.id)
            .findFirst();
        if (_shouldReplaceRelationship(relationship, existing)) {
          await isar.localRelationships.put(
            _localRelationshipFromModel(relationship, pendingSync),
          );
        }
      }
    });
  }

  static Future<UserRelationship?> getRelationship(String relationshipId) async {
    final local = await isar.localRelationships
        .filter()
        .relationshipIdEqualTo(relationshipId)
        .findFirst();
    if (local == null) {
      return null;
    }
    return _relationshipFromLocal(local);
  }

  static Future<List<UserRelationship>> getRelationshipsForUser(
    String userId,
  ) async {
    final relationships = await isar.localRelationships
        .filter()
        .requesterIdEqualTo(userId)
        .or()
        .receiverIdEqualTo(userId)
        .sortByUpdatedAtDesc()
        .findAll();
    return relationships.map(_relationshipFromLocal).toList();
  }

  static Future<int> enqueueMessageChange(
    Message message, {
    required String action,
  }) async {
    final change = PendingChange(
      entityType: 'message',
      entityId: message.id,
      action: action,
      payload: jsonEncode(message.toJson()),
      createdAt: DateTime.now().toUtc(),
    );
    await isar.writeTxn(() async {
      await isar.pendingChanges.put(change);
    });
    return change.id;
  }

  static Future<int> enqueueRelationshipChange(
    UserRelationship relationship, {
    required String action,
  }) async {
    final change = PendingChange(
      entityType: 'relationship',
      entityId: relationship.id,
      action: action,
      payload: jsonEncode(relationship.toJson()),
      createdAt: DateTime.now().toUtc(),
    );
    await isar.writeTxn(() async {
      await isar.pendingChanges.put(change);
    });
    return change.id;
  }

  static Future<List<PendingChange>> getPendingChanges() async {
    return await isar.pendingChanges.where().sortByCreatedAt().findAll();
  }

  static Future<void> removePendingChange(int changeId) async {
    await isar.writeTxn(() async {
      await isar.pendingChanges.delete(changeId);
    });
  }

  static Future<int> syncPendingChanges({
    SupabaseClient? client,
  }) async {
    final syncClient = client ?? SupabaseManager.client;
    final pending = await getPendingChanges();
    var syncedCount = 0;
    for (final change in pending) {
      final success = await _syncChange(syncClient, change);
      if (success) {
        await removePendingChange(change.id);
        syncedCount++;
      }
    }
    return syncedCount;
  }

  static Future<bool> _syncChange(
    SupabaseClient client,
    PendingChange change,
  ) async {
    try {
      final payload = jsonDecode(change.payload) as Map<String, dynamic>;
      if (change.entityType == 'message') {
        if (change.action == 'delete') {
          await client.from('messages').delete().eq('id', change.entityId);
          return true;
        }
        await client
            .from('messages')
            .upsert(payload, onConflict: 'id');
        return true;
      }
      if (change.entityType == 'relationship') {
        if (change.action == 'delete') {
          await client
              .from('user_relationships')
              .delete()
              .eq('id', change.entityId);
          return true;
        }
        await client
            .from('user_relationships')
            .upsert(payload, onConflict: 'id');
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  static LocalMessage _localMessageFromModel(
    Message message,
    bool pendingSync,
  ) {
    return LocalMessage(
      messageId: message.id,
      chatId: message.chatId,
      senderId: message.senderId,
      content: message.content,
      type: message.type.toJson(),
      replyToMessageId: message.replyToMessageId,
      isEdited: message.isEdited,
      isDeleted: message.isDeleted,
      createdAt: message.createdAt,
      updatedAt: message.updatedAt,
      pendingSync: pendingSync,
    );
  }

  static Message _messageFromLocal(LocalMessage local) {
    return Message(
      id: local.messageId,
      chatId: local.chatId,
      senderId: local.senderId,
      content: local.content,
      type: MessageTypeJson.fromJson(local.type),
      replyToMessageId: local.replyToMessageId,
      isEdited: local.isEdited,
      isDeleted: local.isDeleted,
      createdAt: local.createdAt,
      updatedAt: local.updatedAt,
    );
  }

  static LocalChat _localChatFromModel(PrivateChat chat) {
    return LocalChat(
      chatId: chat.id,
      userOneId: chat.userOneId,
      userTwoId: chat.userTwoId,
      lastMessageId: chat.lastMessageId,
      createdAt: chat.createdAt,
    );
  }

  static PrivateChat _chatFromLocal(LocalChat local) {
    return PrivateChat(
      id: local.chatId,
      userOneId: local.userOneId,
      userTwoId: local.userTwoId,
      lastMessageId: local.lastMessageId,
      createdAt: local.createdAt,
    );
  }

  static LocalProfile _localProfileFromModel(Profile profile) {
    return LocalProfile(
      profileId: profile.id,
      username: profile.username,
      displayName: profile.displayName,
      avatarUrl: profile.avatarUrl,
      avatarColor: profile.avatarColor,
      status: profile.status.toJson(),
      lastSeen: profile.lastSeen,
      createdAt: profile.createdAt,
      updatedAt: profile.updatedAt,
    );
  }

  static Profile _profileFromLocal(LocalProfile local) {
    return Profile(
      id: local.profileId,
      username: local.username,
      displayName: local.displayName,
      avatarUrl: local.avatarUrl,
      avatarColor: local.avatarColor,
      status: UserStatusJson.fromJson(local.status),
      lastSeen: local.lastSeen,
      createdAt: local.createdAt,
      updatedAt: local.updatedAt,
    );
  }

  static LocalRelationship _localRelationshipFromModel(
    UserRelationship relationship,
    bool pendingSync,
  ) {
    return LocalRelationship(
      relationshipId: relationship.id,
      requesterId: relationship.requesterId,
      receiverId: relationship.receiverId,
      type: relationship.type.toJson(),
      status: relationship.status.toJson(),
      createdAt: relationship.createdAt,
      updatedAt: relationship.updatedAt,
      pendingSync: pendingSync,
    );
  }

  static UserRelationship _relationshipFromLocal(LocalRelationship local) {
    return UserRelationship(
      id: local.relationshipId,
      requesterId: local.requesterId,
      receiverId: local.receiverId,
      type: RelationshipTypeJson.fromJson(local.type),
      status: RelationshipStatusJson.fromJson(local.status),
      createdAt: local.createdAt,
      updatedAt: local.updatedAt,
    );
  }

  static bool _shouldReplaceRelationship(
    UserRelationship incoming,
    LocalRelationship? existing,
  ) {
    if (existing == null) {
      return true;
    }
    final incomingTime =
        incoming.updatedAt ?? incoming.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final existingTime =
        existing.updatedAt ?? existing.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return incomingTime.isAfter(existingTime) || incomingTime.isAtSameMomentAs(existingTime);
  }
}

@collection
class LocalMessage {
  Id id;

  @Index(unique: true)
  String messageId;

  @Index()
  String chatId;

  String? senderId;
  String? content;
  String type;
  String? replyToMessageId;
  bool isEdited;
  bool isDeleted;
  DateTime? createdAt;
  DateTime? updatedAt;
  bool pendingSync;

  LocalMessage({
    required this.messageId,
    required this.chatId,
    this.senderId,
    this.content,
    required this.type,
    this.replyToMessageId,
    this.isEdited = false,
    this.isDeleted = false,
    this.createdAt,
    this.updatedAt,
    this.pendingSync = false,
  }) : id = fastHash(messageId);
}

@collection
class LocalChat {
  Id id;

  @Index(unique: true)
  String chatId;

  String userOneId;
  String userTwoId;
  String? lastMessageId;
  DateTime? createdAt;

  LocalChat({
    required this.chatId,
    required this.userOneId,
    required this.userTwoId,
    this.lastMessageId,
    this.createdAt,
  }) : id = fastHash(chatId);
}

@collection
class LocalProfile {
  Id id;

  @Index(unique: true)
  String profileId;

  String username;
  String displayName;
  String? avatarUrl;
  int? avatarColor;
  String status;
  DateTime? lastSeen;
  DateTime? createdAt;
  DateTime? updatedAt;

  LocalProfile({
    required this.profileId,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    this.avatarColor,
    required this.status,
    this.lastSeen,
    this.createdAt,
    this.updatedAt,
  }) : id = fastHash(profileId);
}

@collection
class LocalRelationship {
  Id id;

  @Index(unique: true)
  String relationshipId;

  @Index()
  String requesterId;

  @Index()
  String receiverId;

  String type;
  String status;
  DateTime? createdAt;
  DateTime? updatedAt;
  bool pendingSync;

  LocalRelationship({
    required this.relationshipId,
    required this.requesterId,
    required this.receiverId,
    required this.type,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.pendingSync = false,
  }) : id = fastHash(relationshipId);
}

@collection
class PendingChange {
  Id id = Isar.autoIncrement;
  String entityType;
  String entityId;
  String action;
  String payload;
  DateTime createdAt;

  PendingChange({
    required this.entityType,
    required this.entityId,
    required this.action,
    required this.payload,
    required this.createdAt,
  });
}
