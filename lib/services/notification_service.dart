import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart'; // Import for playing custom sounds
import 'package:flutter/material.dart'; // For @required and other Flutter types

/// Global instance for FlutterLocalNotificationsPlugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// Handles background messages. This function must be a top-level function.
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
  // You can perform heavy background tasks here if needed.
  // For now, just show a notification.
  NotificationService()._showNotification(message);
}

/// A service for managing Firebase Cloud Messaging (FCM) and local notifications.
class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _customNotificationSoundPath;

  /// Initializes FCM and local notifications.
  Future<void> initialize() async {
    // Request permission for notifications
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('User granted permission: ${settings.authorizationStatus}');

    // Configure foreground message handling
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
        _showNotification(message);
        _playNotificationSound();
      }
    });

    // Configure background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle messages when the app is opened from a terminated state
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Initialize local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher'); // Your app icon

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Load custom notification sound path
    await _loadCustomNotificationSound();
  }

  /// Retrieves the FCM token for the device.
  Future<String?> getFCMToken() async {
    return await _firebaseMessaging.getToken();
  }

  /// Displays a local notification based on the FCM message.
  void _showNotification(RemoteMessage message) {
    flutterLocalNotificationsPlugin.show(
      message.notification.hashCode,
      message.notification?.title,
      message.notification?.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'my_chat_app_channel', // ID
          'My Chat App Notifications', // Name
          channelDescription: 'Notifications for My Chat Application',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
        ),
      ),
    );
  }

  /// Loads the custom notification sound path from SharedPreferences.
  Future<void> _loadCustomNotificationSound() async {
    final prefs = await SharedPreferences.getInstance();
    _customNotificationSoundPath = prefs.getString('customNotificationSound');
  }

  /// Plays the selected notification sound.
  /// If a custom sound is set, it plays that; otherwise, it relies on system default.
  Future<void> _playNotificationSound() async {
    if (_customNotificationSoundPath != null) {
      try {
        await _audioPlayer.play(DeviceFileSource(_customNotificationSoundPath!));
      } catch (e) {
        print('Error playing custom notification sound: $e');
        // Fallback to system default if custom sound fails
      }
    }
    // For system default, we rely on the AndroidNotificationDetails configuration
    // which uses the default notification sound if not explicitly overridden.
  }

  /// Sets a custom notification sound path and saves it to SharedPreferences.
  Future<void> setCustomNotificationSound(String? path) async {
    final prefs = await SharedPreferences.getInstance();
    if (path != null) {
      await prefs.setString('customNotificationSound', path);
    } else {
      await prefs.remove('customNotificationSound');
    }
    _customNotificationSoundPath = path;
  }

  /// Gets the currently set custom notification sound path.
  String? getCustomNotificationSoundPath() {
    return _customNotificationSoundPath;
  }

  /// Handles messages when the app is opened from a terminated state.
  /// This method is called when a user taps on a notification to open the app.
  void _handleMessageOpenedApp(RemoteMessage message) {
    print('Message opened app: ${message.data}');
    // TODO: Implement navigation to the specific chat screen based on message.data
  }
}