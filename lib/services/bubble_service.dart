import 'dart:async';
import 'package:flutter/services.dart';
import 'package:system_alert_window/system_alert_window.dart';
import 'package:my_chat_app/notification_service.dart';

class BubbleService {
  static final BubbleService instance = BubbleService._internal();
  BubbleService._internal() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onLaunchChatId') {
        final chatId = (call.arguments['chat_id'] ?? call.arguments['chatid']) as String?;
        if (chatId != null && chatId.isNotEmpty) {
          NotificationService.setPendingNavigationChatId(chatId);
          _navigationStreamController.add(chatId);
        }
      }
    });
  }

  static const MethodChannel _channel = MethodChannel('com.example.my_chat_app/bubbles');
  static final StreamController<String> _navigationStreamController = StreamController<String>.broadcast();
  static Stream<String> get navigationStream => _navigationStreamController.stream;

  Future<bool> ensurePermissions() async {
    final granted = await SystemAlertWindow.checkPermissions;
    if (granted != true) {
      final req = await SystemAlertWindow.requestPermissions;
      return req == true;
    }
    return granted == true;
  }

  Future<bool> start({required String chatId, String? title, String? body, String? profilePicUrl}) async {
    try {
      // Check Android version
      final int sdkVersion = await _channel.invokeMethod('getAndroidVersion');
      
      if (sdkVersion >= 30) { // Android 11+
        // Try native bubbles first
        await _channel.invokeMethod('showBubble', {
          'chat_id': chatId,
          'title': title ?? 'Chat',
          'body': body ?? 'New message',
          'profile_picture_url': profilePicUrl,
        });
        return true;
      } else {
        // Force overlay for Android < 11
        return await _showOverlay(chatId, title, body, profilePicUrl);
      }
    } catch (e) {
      print('Error showing bubble/overlay: $e. Falling back to SystemAlertWindow.');
      return await _showOverlay(chatId, title, body, profilePicUrl);
    }
  }

  Future<bool> _showOverlay(String chatId, String? title, String? body, String? profilePicUrl) async {
    final ok = await ensurePermissions();
    if (!ok) return false;
    
    // Send data to overlay before showing
    await SystemAlertWindow.sendMessageToOverlay({
      'chat_id': chatId,
      'title': title,
      'body': body,
      'profile_picture_url': profilePicUrl,
    });

    await SystemAlertWindow.showSystemWindow(
      notificationTitle: title ?? 'New Message',
      notificationBody: body ?? 'Tap to view',
      prefMode: SystemWindowPrefMode.OVERLAY,
    );
    return true;
  }

  @pragma('vm:entry-point')
  static void bubbleBackgroundCallback(String tag, dynamic arguments) {
    print('Bubble background callback: $tag');
  }

  Future<void> stop() async {
    await SystemAlertWindow.closeSystemWindow();
  }
}
