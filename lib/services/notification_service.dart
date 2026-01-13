import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:my_chat_app/services/local_storage_service.dart';
import 'package:flutter/services.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// Background message handler - must be a top-level function for terminated state.
/// This handler is called when the app is in background or terminated state.
/// Note: FCM automatically shows notifications if they include a notification payload.
/// This handler is mainly for data-only messages or custom processing.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (!kIsWeb) {
    await Firebase.initializeApp();
  }
  if (kIsWeb) {
    return;
  }
  final localStorage = LocalStorageService();
  String languageCode = await localStorage.getLanguageCode() ?? Platform.localeName.split('_').first;
  final translations = {
    'en': {
      'new_message': 'New Message',
      'you_have_new_message': 'You have a new message',
    },
    'ar': {
      'new_message': 'رسالة جديدة',
      'you_have_new_message': 'لديك رسالة جديدة',
    },
  };
  final localized = translations[languageCode] ?? translations['en']!;
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const darwinInit = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );
  final initSettings = InitializationSettings(
    android: androidInit,
    iOS: darwinInit,
    macOS: darwinInit,
  );
  await flutterLocalNotificationsPlugin.initialize(initSettings);
  if (Platform.isAndroid) {
    const channel = AndroidNotificationChannel(
      NotificationService.channelId,
      'Chat Messages',
      description: 'Notifications for chat messages',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );
    final androidImplementation = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidImplementation?.createNotificationChannel(channel);
  }
  const androidDetails = AndroidNotificationDetails(
    NotificationService.channelId,
    'Chat Messages',
    channelDescription: 'Notifications for chat messages',
    importance: Importance.high,
    priority: Priority.high,
    showWhen: true,
    playSound: true,
    enableVibration: true,
  );
  const darwinDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );
  final notificationDetails = NotificationDetails(
    android: androidDetails,
    iOS: darwinDetails,
    macOS: darwinDetails,
  );
  if (message.notification != null) {
    return;
  }
  final title = message.data['title'] ?? localized['new_message']!;
  final body = message.data['body'] ?? localized['you_have_new_message']!;
  await flutterLocalNotificationsPlugin.show(
    message.hashCode,
    title,
    body,
    notificationDetails,
    payload: jsonEncode(message.data),
  );
}

class NotificationService {
  static const String channelId = 'chat_channel';
  static String? currentActiveChatId;
  static void setActiveChatId(String? chatId) {
    currentActiveChatId = chatId;
  }
  static const MethodChannel _bubbleChannel = MethodChannel('com.example.my_chat_app/bubbles');
  static Future<void> ensureBubblePermission() async {
    try {
      final ready = await _bubbleChannel.invokeMethod<bool>('isBubblePermissionReady') ?? false;
      if (!ready) {
        await _bubbleChannel.invokeMethod('requestBubblePermission');
      }
    } catch (_) {}
  }
  static Future<void> showBubble({required String chatId, required String title, String body = ''}) async {
    try {
      await ensureBubblePermission();
      await _bubbleChannel.invokeMethod('showBubble', {
        'chatId': chatId,
        'title': title,
        'body': body,
      });
    } catch (_) {}
  }

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final LocalStorageService _localStorageService = LocalStorageService();

  /// Initialize notification service - must be called before runApp()
  Future<void> initialize() async {
    // Request permissions (iOS/macOS/Web)
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('Notification permissions granted');
    } else {
      print('Notification permissions denied');
    }

    // Initialize local notifications plugin
    await _initializeLocalNotifications();

    // Create Android notification channel
    await _createNotificationChannel();

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background/terminated messages (when user taps notification)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Check if app was opened from a terminated state via notification
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }

    // Get FCM token for sending notifications to this device
    String? token;
    if (kIsWeb) {
      // Replace with your actual VAPID key from Firebase Console -> Project Settings -> Cloud Messaging -> Web Configuration
      token = await _firebaseMessaging.getToken(
        vapidKey: 'BDYOxK-R128GkY_67t7f44QvmKF4lq86sl1w0ShrjKvQyqMR4emyXtJvS-p3aVDxNc1xoSid-saG8Damf1-37t8',
      );
    } else {
      token = await _firebaseMessaging.getToken();
    }
    if (token != null) {
      debugPrint('FCM_TOKEN=$token');
      print('FCM_TOKEN=$token');
    }
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      debugPrint('FCM_TOKEN_REFRESHED=$newToken');
      print('FCM_TOKEN_REFRESHED=$newToken');
    });
  }

  Future<void> _initializeLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final initSettings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
      macOS: darwinInit,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
  }

  void _onNotificationTap(NotificationResponse response) {
    // Handle notification tap - can navigate to specific chat
    print('Notification tapped: ${response.payload}');
  }

  Future<void> _createNotificationChannel() async {
    if (kIsWeb || !Platform.isAndroid) return;

    const channel = AndroidNotificationChannel(
      channelId,
      'Chat Messages',
      description: 'Notifications for chat messages',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    final androidImplementation = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    await androidImplementation?.createNotificationChannel(channel);
  }

  /// Handle foreground messages (app is open)
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final incomingChatId = message.data['chatId'] as String?;
    if (incomingChatId != null && incomingChatId == currentActiveChatId) {
      return;
    }
    // Show local notification when app is in foreground
    await _showLocalNotification(message);
    // Optionally request bubble
    if (incomingChatId != null && (message.notification != null || message.data.isNotEmpty)) {
      try {
        await _bubbleChannel.invokeMethod('showBubble', {
          'chatId': incomingChatId,
          'title': message.notification?.title ?? message.data['title'] ?? 'New Message',
          'body': message.notification?.body ?? message.data['body'] ?? '',
        });
      } catch (_) {}
    }
  }

  /// Handle notification tap (opens app from background/terminated state)
  void _handleMessageOpenedApp(RemoteMessage message) {
    // Navigate to specific chat if needed
    // You can extract chat ID from message.data and navigate accordingly
    print('Notification opened app: ${message.data}');
  }

  /// Get localized notification text based on user's language preference
  Future<Map<String, String>> _getLocalizedNotificationText() async {
    String languageCode = 'en';
    if (!kIsWeb) {
      languageCode = await _localStorageService.getLanguageCode() ?? 
                          Platform.localeName.split('_').first;
    } else {
      // Simple fallback for Web or use a web-specific locale getter if available
      languageCode = await _localStorageService.getLanguageCode() ?? 'en';
    }
    
    const translations = {
      'en': {
        'new_message': 'New Message',
        'you_have_new_message': 'You have a new message',
      },
      'ar': {
        'new_message': 'رسالة جديدة',
        'you_have_new_message': 'لديك رسالة جديدة',
      },
    };

    return translations[languageCode] ?? translations['en']!;
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    // Skip local notifications on Web for now (or implement custom UI/HTML notifications)
    if (kIsWeb) {
      print('Foreground message received on Web: ${message.notification?.title}');
      return;
    }

    final localizedText = await _getLocalizedNotificationText();

    const androidDetails = AndroidNotificationDetails(
      channelId,
      'Chat Messages',
      channelDescription: 'Notifications for chat messages',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      playSound: true,
      enableVibration: true,
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      message.hashCode,
      message.notification?.title ?? localizedText['new_message']!,
      message.notification?.body ?? message.data['body'] ?? localizedText['you_have_new_message']!,
      notificationDetails,
      payload: jsonEncode(message.data),
    );
  }

  /// Get FCM token for this device
  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }

  /// Delete FCM token
  Future<void> deleteToken() async {
    await _firebaseMessaging.deleteToken();
  }
}
