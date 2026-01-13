import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:system_alert_window/system_alert_window.dart';
import 'package:my_chat_app/services/bubble_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:my_chat_app/model/message.dart' as chat_model;
import 'package:firebase_core/firebase_core.dart';
import 'package:my_chat_app/services/local_storage_service.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_chat_app/services/encryption_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_chat_app/main.dart'; // Add this import
import 'package:flutter/material.dart';

import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Action IDs
const String actionMarkAsRead = 'mark_as_read';
const String actionReply = 'reply';

/// Background notification action handler
@pragma('vm:entry-point')
Future<void> onNotificationAction(NotificationResponse response) async {
  print('NotificationService: onNotificationAction triggered. ActionId: ${response.actionId}, Payload: ${response.payload}');
  
  try {
    if (!kIsWeb) {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
        print('NotificationService: Firebase initialized in background isolate');
      }
      tz.initializeTimeZones();
    }

    final payload = response.payload != null ? jsonDecode(response.payload!) : null;
    
    if (payload == null) {
      print('NotificationService: Payload is null, cannot proceed');
      return;
    }

    final chatId = payload['chatId'] as String?;
    if (chatId == null) {
      print('NotificationService: chatId is null in payload, cannot proceed');
      return;
    }

    if (response.actionId == null) {
      // This is a tap!
      print('NotificationService: Tap detected in background handler for chat: $chatId');
      NotificationService._pendingNavigationChatId = chatId;
      // In terminated state, the app will start and consume this ID in HomeScreen
      return;
    }

    if (response.actionId == actionMarkAsRead) {
      print('NotificationService: Handling Mark as Read for chat: $chatId');
      
      // Cancel notifications immediately for better responsiveness
      if (response.id != null) {
        await flutterLocalNotificationsPlugin.cancel(response.id!);
      }
      await flutterLocalNotificationsPlugin.cancel(chatId.hashCode + 1);
      
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('NotificationService: User null, waiting for auth...');
        user = await FirebaseAuth.instance.authStateChanges().first.timeout(
          const Duration(seconds: 5),
          onTimeout: () => null,
        );
      }
      
      final uid = user?.uid;
      
      if (uid != null) {
        final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);
        final messagesSnapshot = await chatRef.collection('messages')
            .where('receiverId', isEqualTo: uid)
            .where('status', isNotEqualTo: 'read')
            .get();

        print('NotificationService: Marking ${messagesSnapshot.docs.length} messages as read');
        
        final batch = FirebaseFirestore.instance.batch();
        for (var doc in messagesSnapshot.docs) {
          batch.update(doc.reference, {'status': 'read'});
        }
        batch.update(chatRef, {'lastMessageStatus': 'read'});
        await batch.commit();
        print('NotificationService: Mark as Read successful');

        // Clear local notification history
        NotificationService._conversationHistory.remove(chatId);
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('noti_history_$chatId');
      } else {
        print('NotificationService: Error - UID is null after waiting, user might not be logged in');
      }
      
    } else if (response.actionId == actionReply) {
      final replyText = response.input;
      print('NotificationService: Handling Reply for chat: $chatId, Input: $replyText');
      
      // Cancel notifications immediately
      if (response.id != null) {
        await flutterLocalNotificationsPlugin.cancel(response.id!);
      }
      await flutterLocalNotificationsPlugin.cancel(chatId.hashCode + 1);
      
      if (replyText != null && replyText.isNotEmpty) {
        User? user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          print('NotificationService: User null for reply, waiting...');
          user = await FirebaseAuth.instance.authStateChanges().first.timeout(
            const Duration(seconds: 5),
            onTimeout: () => null,
          );
        }
        
        if (user != null) {
          final chatDoc = await FirebaseFirestore.instance.collection('chats').doc(chatId).get();
          if (chatDoc.exists) {
            final participantIds = List<String>.from(chatDoc.data()?['participantIds'] ?? []);
            final receiverId = participantIds.firstWhere((id) => id != user!.uid, orElse: () => ''); 

            if (receiverId.isNotEmpty) {
              final encryptedContent = EncryptionService().encryptText(replyText);
              final messageId = DateTime.now().millisecondsSinceEpoch.toString();
              
              final messageData = {
                'id': messageId,
                'chatId': chatId,
                'senderId': user!.uid,
                'receiverId': receiverId,
                'type': 'text',
                'content': encryptedContent,
                'timestamp': FieldValue.serverTimestamp(),
                'status': 'sent',
                'deleted': false,
                'reactions': {},
              };

              final batch = FirebaseFirestore.instance.batch();
              batch.set(chatDoc.reference.collection('messages').doc(messageId), messageData);
              batch.update(chatDoc.reference, {
                'lastMessageContent': encryptedContent,
                'lastMessageTime': FieldValue.serverTimestamp(),
                'lastMessageSenderId': user!.uid,
                'lastMessageStatus': 'sent',
              });
              await batch.commit();
              print('NotificationService: Reply sent successfully');
            }
          }
        } else {
          print('NotificationService: Error - User is null after waiting, cannot send reply');
        }
      }
    }
  } catch (e, stack) {
    print('NotificationService: Critical error in onNotificationAction: $e');
    print(stack);
  }
}

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
  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: onNotificationAction,
    onDidReceiveBackgroundNotificationResponse: onNotificationAction,
  );

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

  final title = message.notification?.title ?? message.data['title'] ?? localized['new_message']!;
  final bodyRaw = message.notification?.body ?? message.data['body'] ?? localized['you_have_new_message']!;
  final chatId = message.data['chatId'] as String?;
  String? profilePicUrl = message.data['profilePicUrl'] as String?;
  final senderId = message.data['senderId'] as String?;

  if (profilePicUrl == null && senderId != null) {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(senderId).get();
      if (userDoc.exists) {
        profilePicUrl = userDoc.data()?['profilePictureUrl'];
      }
    } catch (e) {
      print('NotificationService: Error fetching profile picture in background: $e');
    }
  }
  
  String body = bodyRaw;
  if (bodyRaw.isNotEmpty && !bodyRaw.startsWith('[') && bodyRaw != localized['you_have_new_message']) {
    try {
      body = EncryptionService().decryptText(bodyRaw);
    } catch (e) {
      print('NotificationService: Decryption failed in background: $e');
    }
  }

  final notificationId = chatId != null ? chatId.hashCode : message.hashCode;

  // Ensure senderId and chatId are in the payload for background too
  final Map<String, dynamic> dataForPayload = Map.from(message.data);
  if (senderId != null && !dataForPayload.containsKey('senderId')) {
    dataForPayload['senderId'] = senderId;
  }
  if (chatId != null && !dataForPayload.containsKey('chatId')) {
    dataForPayload['chatId'] = chatId;
  }
  final payload = jsonEncode(dataForPayload);

  // Use the service instance to show deduplicated notification
  // This now also handles showing the bubble
  await NotificationService().showDeduplicatedNotification(
    title: title,
    body: body,
    payload: payload,
    chatId: chatId,
    notificationId: notificationId,
    profilePicUrl: profilePicUrl,
  );
}

class NotificationService {
  static const String channelId = 'chat_channel';
  static Uri? relayEndpoint;
  static void configureRelay(Uri endpoint) {
    relayEndpoint = endpoint;
  }
  static String? currentActiveChatId;
  static void setActiveChatId(String? chatId) {
    currentActiveChatId = chatId;
    
    if (chatId != null) {
      // Clear notification history for the active chat
      _conversationHistory.remove(chatId);
      SharedPreferences.getInstance().then((prefs) {
        prefs.remove('noti_history_$chatId');
      });
      
      // Also cancel any existing notifications for this chat
      flutterLocalNotificationsPlugin.cancel(chatId.hashCode);
      flutterLocalNotificationsPlugin.cancel(chatId.hashCode + 1);
    }
    
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        FirebaseFirestore.instance.collection('users').doc(uid).set(
          {
            'activeChatId': chatId,
          },
          SetOptions(merge: true),
        );
      }
    } catch (_) {}
  }
  static Future<void> ensureBubblePermission() async {
    if (kIsWeb) return;
    final granted = await SystemAlertWindow.checkPermissions;
    if (granted != true) {
      await SystemAlertWindow.requestPermissions;
    }
  }
  static Future<void> showBubble({required String chatId, required String title, String body = '', String? profilePicUrl}) async {
    await BubbleService.instance.start(
      chatId: chatId,
      title: title,
      body: body.isNotEmpty ? body : 'Tap to open chat',
      profilePicUrl: profilePicUrl,
    );
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
      try {
        final uid = await FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          await FirebaseFirestore.instance.collection('users').doc(uid).update({
            'fcmToken': token,
          });
        }
      } catch (_) {}
    }
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      debugPrint('FCM_TOKEN_REFRESHED=$newToken');
      print('FCM_TOKEN_REFRESHED=$newToken');
    });
  }

  static Map<String, dynamic> buildFcmHttpV1Message({
    required String token,
    required String title,
    required String body,
    Map<String, String>? data,
  }) {
    return {
      'message': {
        'token': token,
        'notification': {
          'title': title,
          'body': body,
        },
        'data': data ?? {},
        'android': {
          'priority': 'HIGH',
          'notification': {
            'channel_id': channelId,
            'notification_priority': 'PRIORITY_MAX',
          },
        },
      }
    };
  }

  static Future<bool> sendFcmViaRelay({
    required Uri endpoint,
    required Map<String, dynamic> v1Message,
    Map<String, String>? headers,
  }) async {
    try {
      final client = HttpClient();
      final req = await client.postUrl(endpoint);
      req.headers.set('Content-Type', 'application/json');
      if (headers != null) {
        headers.forEach((k, v) => req.headers.set(k, v));
      }
      req.add(utf8.encode(jsonEncode(v1Message)));
      final res = await req.close();
      final ok = res.statusCode >= 200 && res.statusCode < 300;
      client.close(force: true);
      return ok;
    } catch (_) {
      return false;
    }
  }

  Future<void> _initializeLocalNotifications() async {
    tz.initializeTimeZones();
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
      onDidReceiveBackgroundNotificationResponse: onNotificationAction,
    );
  }

  Future<void> _onNotificationTap(NotificationResponse response) async {
    if (response.actionId == null) {
      // Handle normal tap - navigate to specific chat
      print('NotificationService: Notification tapped with payload: ${response.payload}');
      if (response.payload != null) {
        try {
          final payload = jsonDecode(response.payload!);
          final chatId = payload['chatId'] as String?;
          if (chatId != null) {
            // Clear notifications for this chat
            flutterLocalNotificationsPlugin.cancel(chatId.hashCode);
            flutterLocalNotificationsPlugin.cancel(chatId.hashCode + 1);
            
            NotificationService._pendingNavigationChatId = chatId;
            NotificationService._navigationStreamController.add(chatId);
            
            // Try direct navigation if navigatorKey is available
            final context = navigatorKey.currentContext;
            if (context != null) {
              // Navigation is handled by the stream listener in HomeScreen
            }
          }
        } catch (e) {
          print('NotificationService: Error processing notification tap: $e');
        }
      }
    } else {
      // Handle action buttons
      print('NotificationService: Action button tapped: ${response.actionId}');
      await onNotificationAction(response);
    }
  }

  static String? _pendingNavigationChatId;
  static final StreamController<String> _navigationStreamController = StreamController<String>.broadcast();

  /// Stream of chat IDs that should be navigated to when a notification is tapped.
  static Stream<String> get navigationStream => _navigationStreamController.stream;
  static void setPendingNavigationChatId(String chatId) {
    _pendingNavigationChatId = chatId;
  }
  
  static String? consumePendingNavigationChatId() {
    final id = _pendingNavigationChatId;
    _pendingNavigationChatId = null;
    return id;
  }

  static bool hasPendingNavigationChatId() {
    return _pendingNavigationChatId != null;
  }

  static final Map<String, List<Message>> _conversationHistory = {};

  static Future<void> _loadHistoryFromPrefs(String chatId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'noti_history_$chatId';
      final list = prefs.getStringList(key);
      if (list != null) {
        _conversationHistory[chatId] = list.map((e) {
          final map = jsonDecode(e);
          return Message(
            map['text'] ?? '',
            DateTime.parse(map['timestamp']),
            Person(name: map['name'], key: map['name']),
          );
        }).toList();
      }
    } catch (e) {
      print('Error loading notification history: $e');
    }
  }

  static Future<void> _saveHistoryToPrefs(String chatId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'noti_history_$chatId';
      final history = _conversationHistory[chatId] ?? [];
      final list = history.map((e) => jsonEncode({
        'text': e.text,
        'timestamp': e.timestamp.toIso8601String(),
        'name': e.person?.name,
      })).toList();
      await prefs.setStringList(key, list);
    } catch (e) {
      print('Error saving notification history: $e');
    }
  }

  static Future<NotificationDetails> getNotificationDetails({
    required String chatId,
    required String personName,
    required String groupKey,
    required String lastMessage,
    bool isSummary = false,
    String? payload, // Add payload here
  }) async {
    // Maintain history for MessagingStyleInformation
    if (!_conversationHistory.containsKey(chatId)) {
      await _loadHistoryFromPrefs(chatId);
      _conversationHistory[chatId] ??= [];
    }
    
    // Add current message to history if it's not a summary
    if (!isSummary) {
      _conversationHistory[chatId]!.add(
        Message(
          lastMessage,
          DateTime.now(),
          Person(
            name: personName,
            key: personName,
          ),
        ),
      );
      // Keep only last 5 messages
      if (_conversationHistory[chatId]!.length > 5) {
        _conversationHistory[chatId]!.removeAt(0);
      }
      await _saveHistoryToPrefs(chatId);
    }

    final messagingStyle = MessagingStyleInformation(
      Person(name: 'Me', key: 'me'),
      conversationTitle: personName,
      groupConversation: false,
      messages: _conversationHistory[chatId]!,
    );

    final androidDetails = AndroidNotificationDetails(
      NotificationService.channelId,
      'Chat Messages',
      channelDescription: 'Notifications for chat messages',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      playSound: true,
      enableVibration: true,
      groupKey: groupKey,
      setAsGroupSummary: isSummary,
      category: AndroidNotificationCategory.message,
      styleInformation: isSummary ? null : messagingStyle,
      // Only add actions if it's NOT a summary notification
      actions: isSummary ? null : [
        AndroidNotificationAction(
          actionMarkAsRead,
          'Mark as Read',
          showsUserInterface: false,
          cancelNotification: true,
          titleColor: const Color.fromARGB(255, 76, 175, 80), // Green for read
        ),
        AndroidNotificationAction(
          actionReply,
          'Reply',
          allowGeneratedReplies: true,
          showsUserInterface: false,
          inputs: [
            const AndroidNotificationActionInput(label: 'Type a message...'),
          ],
        ),
      ],
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      categoryIdentifier: 'message_category',
    );

    return NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );
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
    if (incomingChatId != null && incomingChatId == NotificationService.currentActiveChatId) {
      return;
    }
    // Show local notification when app is in foreground
    // This now also handles showing the bubble via showDeduplicatedNotification
    await _showLocalNotification(message);
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
    if (kIsWeb) return;
    
    final chatId = message.data['chatId'] as String?;
    if (chatId != null && chatId == NotificationService.currentActiveChatId) {
      return;
    }

    final localizedText = await _getLocalizedNotificationText();
    final title = message.notification?.title ?? message.data['title'] ?? localizedText['new_message']!;
    final bodyRaw = message.notification?.body ?? message.data['body'] ?? localizedText['you_have_new_message']!;
    String? profilePicUrl = message.data['profilePicUrl'] as String?;
    final senderId = message.data['senderId'] as String?;

    if (profilePicUrl == null && senderId != null) {
      try {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(senderId).get();
        if (userDoc.exists) {
          profilePicUrl = userDoc.data()?['profilePictureUrl'];
        }
      } catch (e) {
        print('NotificationService: Error fetching profile picture in foreground: $e');
      }
    }
    
    String body = bodyRaw;
    if (bodyRaw.isNotEmpty && !bodyRaw.startsWith('[') && bodyRaw != localizedText['you_have_new_message']) {
      try {
        body = EncryptionService().decryptText(bodyRaw);
      } catch (e) {
        print('NotificationService: Decryption failed for foreground: $e');
      }
    }

    final notificationId = chatId != null ? chatId.hashCode : message.hashCode;
    
    // Ensure senderId is in the payload so showDeduplicatedNotification can use it
    final Map<String, dynamic> dataWithSender = Map.from(message.data);
    if (senderId != null && !dataWithSender.containsKey('senderId')) {
      dataWithSender['senderId'] = senderId;
    }
    final payload = jsonEncode(dataWithSender);

    await showDeduplicatedNotification(
      title: title,
      body: body,
      payload: payload,
      chatId: chatId,
      notificationId: notificationId,
      profilePicUrl: profilePicUrl,
    );
  }

  /// Get FCM token for this device
  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }

  // Cache to prevent duplicate notifications for the same message content
  static final Map<String, String> _lastDisplayedContentPerChat = {};
  static final Map<String, DateTime> _lastDisplayedTimePerChat = {};

  /// Shows a notification with deduplication logic
  Future<void> showDeduplicatedNotification({
    required String title,
    required String body,
    String? payload,
    String? chatId,
    int? notificationId,
    String? profilePicUrl,
  }) async {
    final groupKey = chatId ?? 'default_group';
    final finalNotificationId = notificationId ?? (chatId != null ? chatId.hashCode : DateTime.now().millisecondsSinceEpoch.hashCode);

    if (chatId != null) {
      final lastContent = _lastDisplayedContentPerChat[chatId];
      final lastTime = _lastDisplayedTimePerChat[chatId];
      final now = DateTime.now();

      // If it's the same content and was shown very recently (within 2 seconds), skip it
      if (lastContent == body && lastTime != null && now.difference(lastTime).inSeconds < 2) {
        print('Skipping duplicate notification for chat $chatId');
        return;
      }

      _lastDisplayedContentPerChat[chatId] = body;
      _lastDisplayedTimePerChat[chatId] = now;
    }

    // Prepare payload with chatId if not provided
    String? finalPayload = payload;
    if (finalPayload == null && chatId != null) {
      finalPayload = jsonEncode({'chatId': chatId});
    }

    // Show the actual notification
    final details = await NotificationService.getNotificationDetails(
      chatId: groupKey,
      personName: title,
      groupKey: groupKey,
      lastMessage: body,
      payload: finalPayload,
    );
    await flutterLocalNotificationsPlugin.show(finalNotificationId, title, body, details, payload: finalPayload);

    // Show summary notification for grouping
    final summaryDetails = await NotificationService.getNotificationDetails(
      chatId: groupKey,
      personName: title,
      groupKey: groupKey,
      lastMessage: body,
      isSummary: true,
      payload: finalPayload,
    );
    final summaryId = groupKey.hashCode + 1;
    await flutterLocalNotificationsPlugin.show(summaryId, title, body, summaryDetails, payload: finalPayload);

    // Also show bubble
    if (chatId != null) {
      try {
        // If profilePicUrl is missing, try to fetch it before showing the bubble
        String? finalProfilePicUrl = profilePicUrl;
        if (finalProfilePicUrl == null) {
          // Extract senderId from payload if possible
          String? senderId;
          if (payload != null) {
            try {
              final data = jsonDecode(payload);
              senderId = data['senderId'] as String?;
            } catch (_) {}
          }
          
          if (senderId != null) {
            try {
              final userDoc = await FirebaseFirestore.instance.collection('users').doc(senderId).get();
              if (userDoc.exists) {
                finalProfilePicUrl = userDoc.data()?['profilePictureUrl'];
              }
            } catch (e) {
              print('Error fetching profile pic for bubble: $e');
            }
          }
        }

        await BubbleService.instance.start(
          chatId: chatId,
          title: title,
          body: body,
          profilePicUrl: finalProfilePicUrl,
        );
      } catch (e) {
        print('Error showing bubble from deduplicated notification: $e');
      }
    }
  }

  /// Manually show a local notification (used by global listener)
  Future<void> showLocalNotificationManually({
    required String title,
    required String body,
    String? payload,
    String? chatId,
    String? profilePicUrl,
  }) async {
    if (kIsWeb) return;

    if (chatId != null && chatId == NotificationService.currentActiveChatId) {
      return;
    }

    await showDeduplicatedNotification(
      title: title,
      body: body,
      payload: payload,
      chatId: chatId,
      profilePicUrl: profilePicUrl,
    );
  }

  StreamSubscription? _globalListenerSubscription;
  DateTime? _lastNotificationTime;
  final Map<String, DateTime> _lastSeenTimesPerChat = {};
  final Map<String, String> _lastSeenContentsPerChat = {};

  /// Starts listening to all chats for new messages while in foreground.
  /// This provides notifications even if FCM relay is not configured.
  void startGlobalMessageListener(String userId) {
    _globalListenerSubscription?.cancel();
    _lastNotificationTime = DateTime.now();
    _lastSeenTimesPerChat.clear();
    _lastSeenContentsPerChat.clear();

    _globalListenerSubscription = FirebaseFirestore.instance
        .collection('chats')
        .where('participantIds', arrayContains: userId)
        .snapshots()
        .listen((snapshot) async {
      for (var change in snapshot.docChanges) {
        // We only care about modifications (new messages or status updates)
        // On initial snapshot (DocumentChangeType.added), we just seed the times
        final chatData = change.doc.data() as Map<String, dynamic>;
        final chatId = change.doc.id;
        final lastMessageTimeRaw = chatData['lastMessageTime'];
        
        DateTime? msgTime;
        if (lastMessageTimeRaw is Timestamp) {
          msgTime = lastMessageTimeRaw.toDate();
        } else if (lastMessageTimeRaw is String) {
          msgTime = DateTime.tryParse(lastMessageTimeRaw);
        }

        if (change.type == DocumentChangeType.added) {
          if (msgTime != null) {
            _lastSeenTimesPerChat[chatId] = msgTime;
          }
          final content = chatData['lastMessageContent'] as String?;
          if (content != null) {
            _lastSeenContentsPerChat[chatId] = content;
          }
          continue;
        }

        if (change.type == DocumentChangeType.modified) {
          final lastMessageSenderId = chatData['lastMessageSenderId'];
          final lastMessageStatus = chatData['lastMessageStatus'];
          final currentContent = chatData['lastMessageContent'] as String?;

          final lastSeen = _lastSeenTimesPerChat[chatId];
          final lastContent = _lastSeenContentsPerChat[chatId];
          
          final isNewTime = msgTime != null && (lastSeen == null || msgTime.isAfter(lastSeen));
          final isNewContent = currentContent != null && currentContent != lastContent;

          if (msgTime != null) {
            _lastSeenTimesPerChat[chatId] = msgTime;
          }
          if (currentContent != null) {
            _lastSeenContentsPerChat[chatId] = currentContent;
          }

          if (lastMessageStatus == 'read') {
            // If the message was marked as read, cancel any active notifications for this chat
            flutterLocalNotificationsPlugin.cancel(chatId.hashCode);
            flutterLocalNotificationsPlugin.cancel(chatId.hashCode + 1);
            
            // Clear notification history for this chat since it's now read
            _conversationHistory.remove(chatId);
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('noti_history_$chatId');
            
            continue;
          }

          if ((isNewTime || isNewContent) && 
              lastMessageSenderId != null && 
              lastMessageSenderId != userId && 
              lastMessageStatus != 'read') {
            
            if (chatId != NotificationService.currentActiveChatId) {
                String senderName = 'New Message';
                String? profilePicUrl;
                  try {
                    final userDoc = await FirebaseFirestore.instance.collection('users').doc(lastMessageSenderId).get();
                    if (userDoc.exists) {
                      senderName = userDoc.data()?['displayName'] ?? userDoc.data()?['username'] ?? 'New Message';
                      profilePicUrl = userDoc.data()?['profilePictureUrl'];
                    }
                  } catch (_) {}

                  final bodyRaw = chatData['lastMessageContent'] ?? 'You have a new message';
                  String body = bodyRaw;
                  
                  // Decrypt if it looks like encrypted text (not an attachment placeholder)
                  if (bodyRaw.isNotEmpty && !bodyRaw.startsWith('[')) {
                    try {
                      body = EncryptionService().decryptText(bodyRaw);
                    } catch (e) {
                      print('NotificationService: Decryption failed for global listener: $e');
                    }
                  }
                  
                  showLocalNotificationManually(
                    title: senderName,
                    body: body,
                    payload: jsonEncode({'chatId': chatId, 'type': 'message'}),
                    chatId: chatId,
                    profilePicUrl: profilePicUrl,
                  );
                }
            }
          }
        }
    });
  }

  void stopGlobalMessageListener() {
    _globalListenerSubscription?.cancel();
    _globalListenerSubscription = null;
  }

  /// Delete FCM token
  Future<void> deleteToken() async {
    await _firebaseMessaging.deleteToken();
  }
}
