import 'dart:ui';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:my_chat_app/notification_service.dart';
import 'package:my_chat_app/supabase_client.dart';

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  await SupabaseManager.initialize();
  await NotificationService.initNotifications();

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  service.on('app_in_foreground').listen((event) async {
    await NotificationService.stopGlobalMessageListener();
  });

  service.on('app_in_background').listen((event) async {
    final user = SupabaseManager.client.auth.currentUser;
    if (user != null) {
      await NotificationService.startGlobalMessageListener(user.id);
    }
  });

  final user = SupabaseManager.client.auth.currentUser;
  if (user != null) {
    await NotificationService.startGlobalMessageListener(user.id);
  }
}
