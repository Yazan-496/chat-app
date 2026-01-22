import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_chat_app/model/profile.dart';
import 'package:my_chat_app/services/database_service.dart';

class ProfileRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<Profile?> fetchById(String userId) async {
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (data == null) {
      return null;
    }
    final profile = Profile.fromJson(data);
    await DatabaseService.saveProfiles([profile]);
    return profile;
  }

  Stream<Profile?> streamById(String userId) {
    return _client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .asyncMap((rows) async {
          if (rows.isEmpty) {
            return null;
          }
          final profile = Profile.fromJson(rows.first);
          await DatabaseService.saveProfiles([profile]);
          return profile;
        });
  }

  Stream<List<Profile>> streamAll() {
    return _client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .asyncMap((rows) async {
          final profiles = rows.map(Profile.fromJson).toList();
          await DatabaseService.saveProfiles(profiles);
          return profiles;
        });
  }

  Future<List<Profile>> search(String query, {int limit = 20}) async {
    final data = await _client
        .from('profiles')
        .select()
        .or('username.ilike.%$query%,display_name.ilike.%$query%')
        .limit(limit);
    final profiles = (data as List).map((row) => Profile.fromJson(row)).toList();
    await DatabaseService.saveProfiles(profiles);
    return profiles;
  }

  Future<Profile> create(Profile profile) async {
    final data = await _client
        .from('profiles')
        .insert(profile.toJson())
        .select()
        .single();
    final created = Profile.fromJson(data);
    await DatabaseService.saveProfiles([created]);
    return created;
  }

  Future<Profile> upsert(Profile profile) async {
    final data = await _client
        .from('profiles')
        .upsert(profile.toJson(), onConflict: 'id')
        .select()
        .single();
    final updated = Profile.fromJson(data);
    await DatabaseService.saveProfiles([updated]);
    return updated;
  }

  Future<void> update(Profile profile) async {
    await _client.from('profiles').update(profile.toJson()).eq('id', profile.id);
    await DatabaseService.saveProfiles([profile]);
  }

  Future<void> delete(String userId) async {
    await _client.from('profiles').delete().eq('id', userId);
  }
}
