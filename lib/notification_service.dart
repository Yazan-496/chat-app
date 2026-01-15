import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:my_chat_app/model/message.dart' as app_message;
import 'package:my_chat_app/model/chat.dart';
import 'package:my_chat_app/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A utility class for managing local notifications in the application.
///
/// This class handles the initialization of `flutter_local_notifications`,
/// displaying message notifications, and managing notification actions.
class NotificationService {
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  static FlutterLocalNotificationsPlugin get flutterLocalNotificationsPlugin => _flutterLocalNotificationsPlugin;

  static String? _activeChatId;
  static String? _pendingNavigationChatId;
  static final StreamController<String> _navigationStreamController =
      StreamController<String>.broadcast();

  static Stream<String> get navigationStream => _navigationStreamController.stream;

  static String? get currentActiveChatId => _activeChatId;

  static void setActiveChatId(String? chatId) {
    _activeChatId = chatId;
  }

  static void setPendingNavigationChatId(String? chatId) {
    _pendingNavigationChatId = chatId;
    if (chatId != null) {
      _navigationStreamController.add(chatId);
    }
  }

  static String? consumePendingNavigationChatId() {
    final String? chatId = _pendingNavigationChatId;
    _pendingNavigationChatId = null;
    return chatId;
  }

  static bool hasPendingNavigationChatId() {
    return _pendingNavigationChatId != null;
  }

  /// A set to keep track of displayed notification IDs to prevent duplicates.
  static final Set<int> _displayedNotificationIds = <int>{};
  static StreamSubscription<List<Map<String, dynamic>>>? _messageSubscription;

  /// Initializes the notification service.
  ///
  /// This method sets up the necessary notification settings for Android and iOS,
  /// and configures how notifications are handled when the app is in the foreground,
  /// when a notification is tapped, or when a notification action is performed.
  static Future<void> initNotifications() async {
    await ensureSupabaseInitialized();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          _onDidReceiveBackgroundNotificationResponse,
    );

    _requestPermissions();
  }

  /// Starts a global listener for new messages from Supabase Realtime.
  ///
  /// This listener will monitor the 'messages' table for new inserts and
  /// display a local notification if the message is not from the current user
  /// and not in the currently active chat.
  ///
  /// [currentUserId] The ID of the currently authenticated user.
  static Future<void> startGlobalMessageListener(String currentUserId) async {
    // Ensure any previous subscription is cancelled to avoid duplicates
    await _messageSubscription?.cancel();

    _messageSubscription = SupabaseManager.client
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: true)
        .limit(1) // Only interested in the latest message
        .listen((List<Map<String, dynamic>> messages) async {
      if (messages.isEmpty) return;

      final latestMessageData = messages.first;
      final message = app_message.Message.fromMap(latestMessageData);

      // Only show notification if it's not from the current user
      // and not for the currently active chat
      if (message.senderId != currentUserId && message.chatId != _activeChatId) {
        // Fetch chat data and join with profile to get username
        final chatData = await SupabaseManager.client
            .from('chats')
            .select()
            .eq('id', message.chatId)
            .single();
        
        final chat = Chat.fromMap(chatData);
        
        // Fetch sender profile to update chat info
        final senderProfile = await SupabaseManager.client
            .from('profiles')
            .select()
            .eq('id', message.senderId)
            .single();
        
        final updatedChat = chat.copyWith(
          displayName: senderProfile['display_name'] ?? 'Unknown',
          profilePictureUrl: senderProfile['profile_picture_url'],
          isOnline: senderProfile['is_online'] ?? false,
        );
        
        showMessageNotification(message, updatedChat);
      }
    });
    log('Global message listener started for user: $currentUserId');
  }

  /// Stops the global message listener.
  static Future<void> stopGlobalMessageListener() async {
    await _messageSubscription?.cancel();
    _messageSubscription = null;
    log('Global message listener stopped.');
  }

  /// Ensures that Supabase is initialized.
  ///
  /// This is a safeguard to ensure that Supabase client is ready before
  /// any notification-related operations that might depend on it.
  static Future<void> ensureSupabaseInitialized() async {
    try {
      Supabase.instance.client;
    } catch (_) {
      await Supabase.initialize(
        url: 'https://rwxznbitzniokfgzjmkg.supabase.co',
        anonKey:
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ3eHpuYml0em5pb2tmZ3pqbWtnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjgyODc4NTUsImV4cCI6MjA4Mzg2Mzg1NX0.Vba99L2UG73q3WdmPRINQcRb9Y9JQjFsnISVbrA-eLM',
      );
    }
  }

  /// Requests necessary notification permissions for iOS.
  ///
  /// This method checks the current platform using the `NavigationService.navigatorKey.currentContext`
  /// to determine if the app is running on iOS and requests specific permissions
  /// for alerts, badges, and sounds.
  static Future<void> _requestPermissions() async {
    if (Theme.of(
            NavigationService.navigatorKey.currentContext ??
                BuildContext as BuildContext)
        .platform ==
        TargetPlatform.iOS) {
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    }
  }

  /// Displays a message notification.
  ///
  /// This method shows a local notification for a new message. It includes
  /// the sender's name, message content, and a reply action.
  ///
  /// The `notificationId` is generated using `message.id.hashCode` to ensure
  /// that each unique message has a distinct notification, preventing
  /// duplicate notifications for the same message.
  ///
  /// [message] The message object to display in the notification.
  /// [chat] The chat object associated with the message.
  static Future<void> showMessageNotification(app_message.Message message, Chat chat) async {
    // Use message ID as notification ID to prevent duplicate notifications for the same message
    final int notificationId = message.id.hashCode;

    if (_displayedNotificationIds.contains(notificationId)) {
      log('Notification with ID $notificationId already displayed. Skipping.');
      return;
    }

    _displayedNotificationIds.add(notificationId);

    final String? currentUserId = SupabaseManager.client.auth.currentUser?.id;
    if (currentUserId == null || message.senderId == currentUserId) {
      // Don't show notification for messages sent by the current user
      return;
    }

    final String senderName = chat.displayName;

    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'messages_channel',
      'Messages',
      channelDescription: 'Notifications for new messages',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'reply_action',
          'Reply',
          showsUserInterface: true,
        ),
      ],
      // This is crucial for showing the custom UI for reply
      // fullScreenIntent: true,
    );

    final DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      interruptionLevel: InterruptionLevel.active,
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    final payload = jsonEncode({
      'chat_id': chat.id,
      'message_id': message.id,
      'sender_id': message.senderId,
    });

    await flutterLocalNotificationsPlugin.show(
      notificationId,
      senderName,
      message.content,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  /// Handles notification responses when the app is in the foreground or background.
  ///
  /// This method is called when a user interacts with a notification. It parses
  /// the payload and handles reply actions. It serves as the entry point for
  /// notification interactions when the app is active or in the background.
  static void _onDidReceiveNotificationResponse(
      NotificationResponse notificationResponse) {
    _handleNotificationAction(notificationResponse);
  }

  /// Handles notification responses when the app is terminated.
  ///
  /// This method is called when a user interacts with a notification and the app
  /// was terminated. It parses the payload and handles reply actions,
  /// ensuring that notification interactions are processed even when the app
  /// is not actively running.
  @pragma('vm:entry-point')
  static void _onDidReceiveBackgroundNotificationResponse(
      NotificationResponse notificationResponse) {
    _handleNotificationAction(notificationResponse);
  }

  /// Processes the notification action based on the response.
  ///
  /// This method extracts information from the notification response, such as
  /// chat ID, message ID, and any reply text, then performs the appropriate
  /// action (e.g., sending a reply).
  static Future<void> _handleNotificationAction(
      NotificationResponse notificationResponse) async {
    final String? payload = notificationResponse.payload;
    if (payload == null) {
      log('Notification payload is null');
      return;
    }

    final Map<String, dynamic> data = jsonDecode(payload);
    final String? chatId = data['chat_id'];
    final String? messageId = data['message_id'];
    final String? senderId = data['sender_id'];

    if (chatId == null || messageId == null || senderId == null) {
      log('Missing chat_id, message_id, or sender_id in payload');
      return;
    }

    if (notificationResponse.actionId == 'reply_action') {
      final String? replyText =
          notificationResponse.input; // Get the reply text from the input
      if (replyText != null && replyText.isNotEmpty) {
        log('Reply action received for message $messageId in chat $chatId with text: $replyText');
        await _sendReply(chatId, messageId, replyText);
      } else {
        log('Reply action received, but reply text is empty.');
      }
    } else {
      log('Notification tapped with payload: $payload');
      // Handle other notification taps, e.g., navigate to the chat screen
      // This would typically involve a Navigator push, but requires a BuildContext.
      // For simplicity, we'll just log for now.
    }
  }

  /// Sends a reply message to Supabase.
  ///
  /// This method inserts the reply message into the 'messages' table in Supabase,
  /// linking it to the original message via `replyToMessageId`.
  ///
  /// [chatId] The ID of the chat the reply belongs to.
  /// [replyToMessageId] The ID of the message being replied to.
  /// [replyText] The content of the reply message.
  static Future<void> _sendReply(
      String chatId, String replyToMessageId, String replyText) async {
    final String? currentUserId = SupabaseManager.client.auth.currentUser?.id;
    if (currentUserId == null) {
      log('User not logged in, cannot send reply.');
      return;
    }

    try {
      // Fetch chat participants to find the receiver
      final chatData = await SupabaseManager.client
          .from('chats')
          .select('participant_ids')
          .eq('id', chatId)
          .single();
      
      final List<String> participantIds = List<String>.from(chatData['participant_ids'] ?? []);
      final String? receiverId = participantIds.firstWhere((id) => id != currentUserId, orElse: () => '');

      if (receiverId == null || receiverId.isEmpty) {
        log('Could not find receiver ID for chat $chatId');
        return;
      }

      await SupabaseManager.client.from('messages').insert({
        'chat_id': chatId,
        'sender_id': currentUserId,
        'receiver_id': receiverId,
        'content': replyText,
        'reply_to_message_id': replyToMessageId,
        'created_at': DateTime.now().toIso8601String(),
        'timestamp': DateTime.now().toIso8601String(),
        'type': 'text',
        'status': 'sent',
      });
      log('Reply sent successfully!');
    } catch (e) {
      log('Error sending reply: $e');
    }
  }
}

/// A utility class to provide a global key for navigation.
///
/// This is used to access the `BuildContext` for navigation operations
/// from outside of widgets, such as in the notification service.
class NavigationService {
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
}
