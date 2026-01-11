import 'dart:io';

import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// Background message handler.
///
/// IMPORTANT: This runs in a separate background isolate. Many plugins that
/// use platform channels (including `flutter_local_notifications`) are not
/// available in that isolate. Calling them here can silently fail or crash.
///
/// Strategy used here:
/// - Persist the incoming message summary into `SharedPreferences` so the
///   main isolate can pick it up when the app resumes and show a local
///   notification or update UI.
/// - Do not call `flutter_local_notifications` from this isolate.
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    final prefs = await SharedPreferences.getInstance();

    final summary = jsonEncode({
      'messageId': message.messageId,
      'title': message.notification?.title,
      'body': message.notification?.body,
      'data': message.data,
      'receivedAt': DateTime.now().toIso8601String(),
    });

    final pending = prefs.getStringList('pending_messages') ?? <String>[];
    pending.add(summary);
    await prefs.setStringList('pending_messages', pending);

    // Keep a log entry for debugging on devices.
    print('Background message persisted: $summary');
  } catch (e) {
    print('Error in background message handler: $e');
  }
}

class NotificationService {
  static const String channelId = 'chat_channel';

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((message) async {
      // Foreground message: show a local notification and attempt to play a
      // short bundled sound as a fallback (some platforms suppress sound for
      // foreground notifications). The asset should be added to
      // `assets/sounds/chat_sound.mp3` and listed in `pubspec.yaml`.
      await showNotification(message);
      _playForegroundSoundIfAvailable();
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      // navigate to chat
    });

    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS / macOS initialization settings — if running on Apple platforms include
    // the Darwin initialization so local notifications with custom sounds work.
    final DarwinInitializationSettings? darwinInit =
        Platform.isIOS || Platform.isMacOS
            ? const DarwinInitializationSettings()
            : null;

    final initSettings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
    );

    await flutterLocalNotificationsPlugin.initialize(initSettings);

    await _createNotificationChannel();
    // After initializing plugins, process any messages that were persisted
    // by the background handler while the app was not running.
    await _processPendingMessages();
  }

  static Future<void> _playForegroundSoundIfAvailable() async {
    try {
      final player = AudioPlayer();
      // Attempt to play an app-bundled asset. Add the file at
      // `assets/sounds/chat_sound.mp3` and reference it in pubspec.yaml under
      // `flutter.assets` for this to work.
      await player.play(AssetSource('sounds/chat_sound.mp3'));
      await Future.delayed(const Duration(seconds: 2));
      await player.dispose();
    } catch (e) {
      // Not critical — missing asset or playback issues shouldn't crash.
      print('Foreground sound playback failed: $e');
    }
  }

  static Future<void> showNotification(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      channelId,
      'Chat Messages',
      channelDescription: 'Chat notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('chat_sound'),
      showWhen: true,
    );

    // iOS / macOS notification details: iOS expects the sound filename with
    // extension (e.g. 'chat_sound.aiff') and the sound must be included in the
    // app bundle. On Android the raw resource name (without extension) is used.
    DarwinNotificationDetails? darwinDetails;
    if (Platform.isIOS || Platform.isMacOS) {
      darwinDetails = const DarwinNotificationDetails(
        presentSound: true,
        sound: 'chat_sound.aiff',
      );
    }

    final details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    try {
      await flutterLocalNotificationsPlugin.show(
        message.hashCode,
        message.notification?.title,
        message.notification?.body,
        details,
      );
    } catch (e) {
      // Log the error to help debugging missing sound resources or platform issues.
      print('Error showing local notification: $e');
    }
  }

  /// Show a local notification from a persisted message summary (used when
  /// background handler saved messages to SharedPreferences).
  static Future<void> showNotificationFromSummary(Map<String, dynamic> s) async {
    final title = s['title'] as String?;
    final body = s['body'] as String?;

    const androidDetails = AndroidNotificationDetails(
      channelId,
      'Chat Messages',
      channelDescription: 'Chat notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('chat_sound'),
      showWhen: true,
    );

    DarwinNotificationDetails? darwinDetails;
    if (Platform.isIOS || Platform.isMacOS) {
      darwinDetails = const DarwinNotificationDetails(
        presentSound: true,
        sound: 'chat_sound.aiff',
      );
    }

    final details = NotificationDetails(android: androidDetails, iOS: darwinDetails);

    try {
      await flutterLocalNotificationsPlugin.show(
        s['messageId']?.hashCode ?? DateTime.now().hashCode,
        title,
        body,
        details,
      );
    } catch (e) {
      print('Error showing persisted notification: $e');
    }
  }

  Future<void> _processPendingMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pending = prefs.getStringList('pending_messages') ?? <String>[];
      if (pending.isEmpty) return;

      for (final item in pending) {
        try {
          final Map<String, dynamic> s = jsonDecode(item) as Map<String, dynamic>;
          await NotificationService.showNotificationFromSummary(s);
        } catch (e) {
          print('Error processing pending message item: $e');
        }
      }

      // Clear pending after processing.
      await prefs.remove('pending_messages');
    } catch (e) {
      print('Error reading pending messages: $e');
    }
  }

  Future<void> _createNotificationChannel() async {
    const channel = AndroidNotificationChannel(
      channelId,
      'Chat Messages',
      description: 'Chat notifications',
      importance: Importance.high,
      sound: RawResourceAndroidNotificationSound('chat_sound'),
      playSound: true,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }
}
