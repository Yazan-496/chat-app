import 'dart:async';
import 'package:flutter/services.dart';
import 'package:system_alert_window/system_alert_window.dart';
import 'package:my_chat_app/services/notification_service.dart';

class BubbleService {
  static final BubbleService instance = BubbleService._internal();
  BubbleService._internal() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onLaunchChatId') {
        final chatId = call.arguments['chatId'] as String?;
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
      // Try native bubbles first
      await _channel.invokeMethod('showBubble', {
        'chatId': chatId,
        'title': title ?? 'Chat',
        'body': body ?? 'New message',
        'profilePicUrl': profilePicUrl,
      });
      return true;
    } catch (e) {
      print('Error showing native bubble: $e. Falling back to SystemAlertWindow.');
      // Fallback to SystemAlertWindow if native fails
      final ok = await ensurePermissions();
      if (!ok) return false;
      
      // Send data to overlay before showing
      await SystemAlertWindow.sendMessageToOverlay({
        'chatId': chatId,
        'title': title,
        'body': body,
        'profilePicUrl': profilePicUrl,
      });

      await SystemAlertWindow.showSystemWindow(
        notificationTitle: title ?? 'New Message',
        notificationBody: body ?? 'Tap to view',
        prefMode: SystemWindowPrefMode.OVERLAY,
      );
      return true;
    }
  }

  @pragma('vm:entry-point')
  static void bubbleBackgroundCallback(String tag, dynamic arguments) {
    print('Bubble background callback: $tag');
  }

  Future<void> stop() async {
    await SystemAlertWindow.closeSystemWindow();
  }
}
