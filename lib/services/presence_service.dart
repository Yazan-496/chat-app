import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

class PresenceService {
  final SupabaseClient _supabase = Supabase.instance.client;
  Timer? _heartbeatTimer;

  /// Marks the user as online and updates lastSeen to now.
  /// Also starts a periodic heartbeat to keep the user 'online'.
  Future<void> setUserOnline(String uid) async {
    try {
      await _supabase.from('profiles').update({
        'is_online': true,
        'last_seen': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', uid);
      
      _startHeartbeat(uid);
    } catch (e) {
      print('PresenceService: Failed to set online for $uid: $e');
    }
  }

  void _startHeartbeat(String uid) {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      try {
        await _supabase.from('profiles').update({
          'last_seen': DateTime.now().toUtc().toIso8601String(),
          'is_online': true,
        }).eq('id', uid);
      } catch (e) {
        print('PresenceService: Heartbeat failed for $uid: $e');
      }
    });
  }

  /// Marks the user as offline and updates lastSeen to now.
  Future<void> setUserOffline(String uid) async {
    _heartbeatTimer?.cancel();
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
