import 'dart:async';
import 'dart:developer';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_chat_app/notification_service.dart';

class PresenceService {
  static final PresenceService _instance = PresenceService._internal();
  factory PresenceService() => _instance;
  PresenceService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  RealtimeChannel? _statusChannel;
  String? _currentUserId;
  Timer? _heartbeatTimer;

  /// Sets up user status (Online/Offline) using Supabase Presence and a Heartbeat
  void setUserStatus(String userId) {
    if (_currentUserId == userId && _statusChannel != null) return;
    
    // Clear previous state if user ID changed
    if (_currentUserId != userId) {
      dispose();
    }
    
    _currentUserId = userId;
    
    // Initial online update - call immediately before subscription to be fast
    _sendOnlineStatus();
    _startHeartbeat();
    
    // 1. Setup the Realtime Channel for Presence (optional but good for tracking)
    _statusChannel = _supabase.channel('online-users');

    _statusChannel!.onPresenceSync((payload) {
      // Sync local state if needed
    }).onPresenceJoin((payload) {
      // Each user handles their own status via the heartbeat.
    }).onPresenceLeave((payload) {
      // Scenario 2: Abrupt Disconnect
      // Note: This callback runs on OTHER clients when a user disconnects abruptly.
      // The server-side Supabase Presence handles the 'leave' event automatically
      // when the WebSocket connection is lost (internet cut or app killed).
    }).subscribe((status, [error]) async {
      if (status == RealtimeSubscribeStatus.subscribed) {
        // Track the current user in presence
        await _statusChannel!.track({
          'user_id': userId,
          'online_at': DateTime.now().toUtc().toIso8601String(),
        });
      }
    });
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _sendOnlineStatus();
    });
  }

  Future<void> _sendOnlineStatus() async {
    if (_currentUserId == null) return;
    try {
      log('PresenceService: Sending heartbeat for user $_currentUserId');
      await _supabase.rpc('handle_user_status', params: {
        'p_user_id': _currentUserId,
        'p_online_status': true,
        'p_active_chat_id': NotificationService.currentActiveChatId,
      });
    } catch (e) {
      log('PresenceService: Error sending heartbeat: $e');
    }
  }
  /// Helper for compatibility with old code
  Future<void> setUserOnline(String uid) async {
    log('PresenceService: Manually setting user online: $uid');
    setUserStatus(uid);
  }

  /// Helper for compatibility with old code
  Future<void> setUserOffline(String uid) async {
    log('PresenceService: Manually setting user offline: $uid');
    if (uid.isEmpty) {
      dispose();
      return;
    }
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    
    try {
      await _supabase.rpc('handle_user_status', params: {
        'p_user_id': uid,
        'p_online_status': false,
      });
    } catch (e) {
      log('PresenceService: Error setting offline status: $e');
    }
    
    dispose();
  }

  void dispose() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    if (_statusChannel != null) {
      _statusChannel!.unsubscribe();
      _statusChannel = null;
    }
    _currentUserId = null;
  }
}
