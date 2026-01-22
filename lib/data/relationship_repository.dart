import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_chat_app/model/user_relationship.dart';
import 'package:my_chat_app/services/database_service.dart';

class RelationshipRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<UserRelationship?> fetchById(String relationshipId) async {
    final data = await _client
        .from('user_relationships')
        .select()
        .eq('id', relationshipId)
        .maybeSingle();
    if (data == null) {
      return null;
    }
    final relationship = UserRelationship.fromJson(data);
    await DatabaseService.saveRelationships([relationship]);
    return relationship;
  }

  Stream<List<UserRelationship>> streamForUser(String userId) {
    return _client
        .from('user_relationships')
        .stream(primaryKey: ['id'])
        .asyncMap((rows) async {
          final relationships = rows
              .where((row) =>
                  row['requester_id'] == userId || row['receiver_id'] == userId)
              .map(UserRelationship.fromJson)
              .toList();
          await DatabaseService.saveRelationships(relationships);
          return relationships;
        });
  }

  Future<UserRelationship> create(UserRelationship relationship) async {
    final data = await _client
        .from('user_relationships')
        .insert(relationship.toJson())
        .select()
        .single();
    final created = UserRelationship.fromJson(data);
    await DatabaseService.saveRelationships([created]);
    return created;
  }

  Future<UserRelationship> upsert(UserRelationship relationship) async {
    final data = await _client
        .from('user_relationships')
        .upsert(relationship.toJson(), onConflict: 'id')
        .select()
        .single();
    final updated = UserRelationship.fromJson(data);
    await DatabaseService.saveRelationships([updated]);
    return updated;
  }

  Future<void> update(UserRelationship relationship) async {
    await _client
        .from('user_relationships')
        .update(relationship.toJson())
        .eq('id', relationship.id);
    await DatabaseService.saveRelationships([relationship]);
  }

  Future<void> updateStatus(
    String relationshipId,
    RelationshipStatus status,
  ) async {
    await _client
        .from('user_relationships')
        .update({'status': status.toJson()})
        .eq('id', relationshipId);
  }

  Future<void> delete(String relationshipId) async {
    await _client.from('user_relationships').delete().eq('id', relationshipId);
  }

  Future<String> acceptRelationship(String relationshipId) async {
    final data = await _client.rpc(
      'accept_relationship',
      params: {'p_relationship': relationshipId},
    );
    return data as String;
  }
}
