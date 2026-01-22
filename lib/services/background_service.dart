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
  });

  service.on('app_in_background').listen((event) async {
  });
}
