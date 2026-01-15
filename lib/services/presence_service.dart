import 'package:supabase_flutter/supabase_flutter.dart';

class PresenceService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Marks the user as online and updates lastSeen to now.
  Future<void> setUserOnline(String uid) async {
    try {
      await _supabase.from('profiles').update({
        'is_online': true,
        'last_seen': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', uid);
    } catch (e) {
      print('PresenceService: Failed to set online for $uid: $e');
    }
  }

  /// Marks the user as offline and updates lastSeen to now.
  Future<void> setUserOffline(String uid) async {
    try {
      await _supabase.from('profiles').update({
        'is_online': false,
        'last_seen': DateTime.now().toUtc().toIso8601String(),
        'active_chat_id': null,
      }).eq('id', uid);
    } catch (e) {
      print('PresenceService: Failed to set offline for $uid: $e');
    }
  }
}
