import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_chat_app/model/chat_participant.dart';
import 'package:my_chat_app/model/private_chat.dart';
import 'package:my_chat_app/services/database_service.dart';

class ChatRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<PrivateChat?> fetchById(String chatId) async {
    final data = await _client
        .from('private_chats')
        .select()
        .eq('id', chatId)
        .maybeSingle();
    if (data == null) {
      return null;
    }
    final chat = PrivateChat.fromJson(data);
    await DatabaseService.saveChats([chat]);
    return chat;
  }

  Stream<PrivateChat?> streamById(String chatId) {
    return _client
        .from('private_chats')
        .stream(primaryKey: ['id'])
        .eq('id', chatId)
        .asyncMap((rows) async {
          if (rows.isEmpty) {
            return null;
          }
          final chat = PrivateChat.fromJson(rows.first);
          await DatabaseService.saveChats([chat]);
          return chat;
        });
  }

  Stream<List<PrivateChat>> streamForUser(String userId) {
    return _client
        .from('private_chats')
        .stream(primaryKey: ['id'])
        .asyncMap((rows) async {
          final chats = rows
              .where((row) =>
                  row['user_one'] == userId || row['user_two'] == userId)
              .map(PrivateChat.fromJson)
              .toList();
          await DatabaseService.saveChats(chats);
          return chats;
        });
  }

  Future<PrivateChat> create(PrivateChat chat) async {
    final data = await _client
        .from('private_chats')
        .insert(chat.toJson())
        .select()
        .single();
    final created = PrivateChat.fromJson(data);
    await DatabaseService.saveChats([created]);
    return created;
  }

  Future<PrivateChat> upsert(PrivateChat chat) async {
    final data = await _client
        .from('private_chats')
        .upsert(chat.toJson(), onConflict: 'id')
        .select()
        .single();
    final updated = PrivateChat.fromJson(data);
    await DatabaseService.saveChats([updated]);
    return updated;
  }

  Future<void> update(PrivateChat chat) async {
    await _client.from('private_chats').update(chat.toJson()).eq('id', chat.id);
    await DatabaseService.saveChats([chat]);
  }

  Future<void> delete(String chatId) async {
    await _client.from('private_chats').delete().eq('id', chatId);
  }

  Future<String> getOrCreateChat(String otherUserId) async {
    final data = await _client.rpc(
      'get_or_create_private_chat',
      params: {'p_other': otherUserId},
    );
    return data as String;
  }

  Future<void> markChatRead(String chatId) async {
    await _client.rpc(
      'mark_chat_read',
      params: {'p_chat': chatId},
    );
  }

  Future<void> markMessageDelivered(String chatId, String messageId) async {
    await _client.rpc(
      'mark_message_delivered',
      params: {'p_chat': chatId, 'p_message': messageId},
    );
  }

  Future<List<ChatParticipant>> fetchParticipants(String chatId) async {
    final data = await _client
        .from('chat_participants')
        .select()
        .eq('chat_id', chatId);
    return (data as List)
        .map((row) => ChatParticipant.fromJson(row))
        .toList();
  }

  Stream<List<ChatParticipant>> streamParticipants(String chatId) {
    return _client
        .from('chat_participants')
        .stream(primaryKey: ['chat_id', 'user_id'])
        .eq('chat_id', chatId)
        .map((rows) => rows.map(ChatParticipant.fromJson).toList());
  }

  Future<ChatParticipant?> fetchParticipant(
    String chatId,
    String userId,
  ) async {
    final data = await _client
        .from('chat_participants')
        .select()
        .eq('chat_id', chatId)
        .eq('user_id', userId)
        .maybeSingle();
    if (data == null) {
      return null;
    }
    return ChatParticipant.fromJson(data);
  }

  Future<ChatParticipant> upsertParticipant(
    ChatParticipant participant,
  ) async {
    final data = await _client
        .from('chat_participants')
        .upsert(
          participant.toJson(),
          onConflict: 'chat_id,user_id',
        )
        .select()
        .single();
    return ChatParticipant.fromJson(data);
  }
}
