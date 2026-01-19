import 'dart:ui';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:my_chat_app/notification_service.dart';
import 'package:my_chat_app/supabase_client.dart';
import 'package:my_chat_app/services/local_storage_service.dart';

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  await SupabaseManager.initialize();
  await NotificationService.initNotifications();

  // Try to restore session
  final sessionJson = await LocalStorageService().getSession();
  if (sessionJson != null) {
    try {
      await SupabaseManager.client.auth.recoverSession(sessionJson);
    } catch (_) {}
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  service.on('app_in_foreground').listen((event) async {
    await NotificationService.stopGlobalMessageListener();
  });

  service.on('app_in_background').listen((event) async {
    String? userId = event?['user_id'];
    if (userId == null) {
      final user = SupabaseManager.client.auth.currentUser;
      userId = user?.id;
    }

    if (userId != null) {
      await NotificationService.startGlobalMessageListener(userId);
    }
  });

  final user = SupabaseManager.client.auth.currentUser;
  if (user != null) {
    await NotificationService.startGlobalMessageListener(user.id);
  }
}
