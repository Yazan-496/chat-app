import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_chat_app/model/message.dart';
import 'package:my_chat_app/model/profile.dart';
import 'package:my_chat_app/model/message_reaction.dart';
import 'package:my_chat_app/services/database_service.dart';

class MessageRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<Message?> fetchById(String messageId) async {
    final data = await _client
        .from('messages')
        .select()
        .eq('id', messageId)
        .maybeSingle();
    if (data == null) {
      return null;
    }
    final message = Message.fromJson(data);
    final withReactions = await _attachReactions([message]);
    await DatabaseService.saveMessages(withReactions);
    return withReactions.first;
  }

  Future<List<Message>> fetchByChat(
    String chatId, {
    int limit = 50,
    DateTime? before,
  }) async {
    final baseQuery = _client.from('messages').select().eq('chat_id', chatId);
    final filteredQuery = before != null
        ? baseQuery.lt('created_at', before.toIso8601String())
        : baseQuery;
    final data = await filteredQuery
        .order('created_at', ascending: false)
        .limit(limit);
    final messages = (data as List).map((row) => Message.fromJson(row)).toList();
    final withReactions = await _attachReactions(messages);
    await DatabaseService.saveMessages(withReactions);
    return withReactions;
  }

  Stream<List<Message>> streamByChat(String chatId) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', chatId)
        .order('created_at', ascending: true)
        .asyncMap((rows) async {
          final messages = rows.map(Message.fromJson).toList();
          final withReactions = await _attachReactions(messages);
          await DatabaseService.saveMessages(withReactions);
          return withReactions;
        });
  }

  Future<Message> create(Message message) async {
    final data = await _client
        .from('messages')
        .insert(message.toJson())
        .select()
        .single();
    final created = Message.fromJson(data);
    await DatabaseService.saveMessages([created]);
    return created;
  }

  Future<void> update(Message message) async {
    await _client.from('messages').update(message.toJson()).eq('id', message.id);
    await DatabaseService.saveMessages([message]);
  }

  Future<void> delete(String messageId) async {
    await _client.from('messages').delete().eq('id', messageId);
  }

  Future<void> markDeleted(String messageId) async {
    await _client.from('messages').update({'is_deleted': true}).eq('id', messageId);
  }

  Future<void> markEdited(String messageId) async {
    await _client.from('messages').update({'is_edited': true}).eq('id', messageId);
  }

  Future<MessageReaction> addReaction(MessageReaction reaction) async {
    final data = await _client
        .from('message_reactions')
        .insert(reaction.toJson())
        .select()
        .single();
    return MessageReaction.fromJson(data);
  }

  Future<void> removeReaction({
    required String messageId,
    required String userId,
    required String emoji,
  }) async {
    await _client
        .from('message_reactions')
        .delete()
        .eq('message_id', messageId)
        .eq('user_id', userId)
        .eq('emoji', emoji);
  }

  Stream<List<MessageReaction>> streamReactions(String messageId) {
    return _client
        .from('message_reactions')
        .stream(primaryKey: ['id'])
        .eq('message_id', messageId)
        .map((rows) => rows.map(MessageReaction.fromJson).toList());
  }

  Future<Map<String, dynamic>> fetchMessagesWithProfiles(
    String chatId, {
    int limit = 50,
    DateTime? before,
  }) async {
    final baseQuery = _client.from('messages').select().eq('chat_id', chatId);
    final filteredQuery = before != null
        ? baseQuery.lt('created_at', before.toIso8601String())
        : baseQuery;
    final data = await filteredQuery
        .order('created_at', ascending: false)
        .limit(limit);

    final messages = (data as List).map((row) => Message.fromJson(row)).toList();
    final withReactions = await _attachReactions(messages);
    final senderIds = withReactions.map((m) => m.senderId).toSet().toList();

    final profilesData = senderIds.isEmpty
        ? <dynamic>[]
        : await _client.from('profiles').select().filter('id', 'in', senderIds);
    final profilesList = profilesData
        .map((json) => Profile.fromJson(json))
        .toList();

    final profilesMap = {for (var p in profilesList) p.id: p};

    await DatabaseService.saveMessages(withReactions);

    return {
      'messages': withReactions,
      'profilesMap': profilesMap,
    };
  }

  Future<List<Message>> _attachReactions(List<Message> messages) async {
    if (messages.isEmpty) {
      return messages;
    }
    final messageIds =
        messages.map((m) => m.id).where((id) => id.isNotEmpty).toSet().toList();
    if (messageIds.isEmpty) {
      return messages;
    }
    final reactionsData = await _client
        .from('message_reactions')
        .select('message_id,user_id,emoji')
        .filter('message_id', 'in', messageIds);
    final rows = reactionsData as List;
    final reactionsByMessage = <String, Map<String, String>>{};
    for (final row in rows) {
      if (row is! Map) continue;
      final messageId = row['message_id']?.toString();
      final userId = row['user_id']?.toString();
      final emoji = row['emoji']?.toString();
      if (messageId == null || userId == null || emoji == null || emoji.isEmpty) {
        continue;
      }
      final map = reactionsByMessage.putIfAbsent(messageId, () => {});
      map[userId] = emoji;
    }
    return messages
        .map((m) => m.copyWith(reactions: reactionsByMessage[m.id] ?? m.reactions))
        .toList();
  }

}
