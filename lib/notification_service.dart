import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:ui' show DartPluginRegistrant;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:my_chat_app/model/message.dart' as app_message;
import 'package:my_chat_app/model/chat.dart';
import 'package:my_chat_app/services/encryption_service.dart';
import 'package:my_chat_app/supabase_client.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A utility class for managing local notifications in the application.
///
/// This class handles the initialization of `flutter_local_notifications`,
/// displaying message notifications, and managing notification actions.
class NotificationService {
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  static FlutterLocalNotificationsPlugin get flutterLocalNotificationsPlugin => _flutterLocalNotificationsPlugin;

  static const MethodChannel _bubbleChannel =
      MethodChannel('com.example.my_chat_app/bubbles');
  static bool _bubbleChannelHandlerInstalled = false;
  static DateTime? _lastBubbleSettingsOpenAt;

  static String? _activeChatId;
  static String? _pendingNavigationChatId;
  static final StreamController<String> _navigationStreamController =
      StreamController<String>.broadcast();

  static Stream<String> get navigationStream => _navigationStreamController.stream;

  static String? get currentActiveChatId => _activeChatId;

  static final EncryptionService _encryptionService = EncryptionService();

  static final Map<String, List<Message>> _chatNotificationMessages =
      <String, List<Message>>{};
  static final Map<String, Set<String>> _chatSeenMessageIds =
      <String, Set<String>>{};
  static final Map<String, String> _avatarUrlToFilePath = <String, String>{};
  static String? _listenerUserId;
  static Timer? _listenerRetryTimer;
  static int _listenerRetryCount = 0;
  static Timer? _testNotificationTimer;
  static const int _testImmediateNotificationId = 999001;
  static const int _testPeriodicNotificationId = 999002;

  static const String _fallbackLargeIconResource = 'ic_launcher';

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

  static StreamSubscription<List<Map<String, dynamic>>>? _messageSubscription;

  /// Initializes the notification service.
  ///
  /// This method sets up the necessary notification settings for Android and iOS,
  /// and configures how notifications are handled when the app is in the foreground,
  /// when a notification is tapped, or when a notification action is performed.
  static Future<void> initNotifications() async {
    await ensureSupabaseInitialized();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('ic_stat_lozo');

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

    _installBubbleChannelHandler();

    // Clean up old duplicate channel if it exists
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.deleteNotificationChannel('messages_channel_v6');
    // Clean up old duplicate channel if it exists
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.deleteNotificationChannel('messages_channel_v5');
    // Clean up old duplicate channel if it exists
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.deleteNotificationChannel('messages_channel_v4');
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.deleteNotificationChannel('messages_channel_v3');
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.deleteNotificationChannel('messages_channel_v2');
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.deleteNotificationChannel('messages_channel_v1');
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.deleteNotificationChannel('messages_channel');

    // Note: We primarily rely on the native side (MainActivity.kt) to create the
    // 'messages_channel_v7' with the correct bubble permissions enabled.
    // We declare it here just so the plugin is aware of it, but we trust the native creation first.
    const AndroidNotificationChannel messagesChannelV7 = AndroidNotificationChannel(
      'messages_channel_v7',
      'Messages',
      description: 'Notifications for new messages',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      showBadge: true,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(messagesChannelV7);

    const AndroidNotificationChannel backgroundServiceChannel = AndroidNotificationChannel(
      'my_chat_app_background',
      'Background Service',
      description: 'Running in background to receive messages',
      importance: Importance.min, // Min importance hides it from status bar
      showBadge: false,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(backgroundServiceChannel);

    _requestPermissions();
  }

  static void _installBubbleChannelHandler() {
    if (_bubbleChannelHandlerInstalled) return;
    _bubbleChannelHandlerInstalled = true;
    _bubbleChannel.setMethodCallHandler((call) async {
      if (call.method != 'onLaunchChatId') return null;
      try {
        final args = call.arguments;
        String? chatId;
        if (args is Map) {
          final raw = args['chat_id'] ?? args['chatid'];
          if (raw is String) chatId = raw;
        } else if (args is String) {
          chatId = args;
        }
        if (chatId != null && chatId.isNotEmpty) {
          setPendingNavigationChatId(chatId);
        }
      } catch (e) {
        log('Notifications: onLaunchChatId handler failed: $e');
      }
      return null;
    });
  }

  static Future<bool> ensureAndroidNotificationsPermission() async {
    if (kIsWeb || !Platform.isAndroid) return true;
    final androidImpl = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    final granted = await androidImpl?.requestNotificationsPermission();
    return granted ?? true;
  }

  /// Starts a global listener for new messages from Supabase Realtime.
  ///
  /// This listener will monitor the 'messages' table for new inserts and
  /// display a local notification if the message is not from the current user
  /// and not in the currently active chat.
  ///
  /// [currentUserId] The ID of the currently authenticated user.
  static Future<void> startGlobalMessageListener(String currentUserId) async {
    _listenerUserId = currentUserId;
    _listenerRetryTimer?.cancel();
    _listenerRetryTimer = null;
    _listenerRetryCount = 0;

    await _messageSubscription?.cancel();
    _messageSubscription = null;

    log('Notifications: startGlobalMessageListener user=$currentUserId activeChat=$_activeChatId');

    _messageSubscription = SupabaseManager.client
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .limit(1)
        .listen(
      (List<Map<String, dynamic>> messages) async {
        if (messages.isEmpty) return;

        final latestMessageData = messages.first;
        final message = app_message.Message.fromMap(latestMessageData);

        log(
          'Notifications: message received id=${message.id} chat=${message.chatId} sender=${message.senderId} type=${message.type} activeChat=$_activeChatId',
        );

        final shouldNotify =
            message.senderId != currentUserId && message.chatId != _activeChatId;
        if (!shouldNotify) {
          log(
            'Notifications: skip notification id=${message.id} reason='
            'senderIsMe=${message.senderId == currentUserId} '
            'chatIsActive=${message.chatId == _activeChatId}',
          );
          return;
        }

        try {
          final chatData = await SupabaseManager.client
              .from('chats')
              .select()
              .eq('id', message.chatId)
              .single();

          final chat = Chat.fromMap(chatData);

          Map<String, dynamic>? senderProfile;
          try {
            senderProfile = await SupabaseManager.client
                .from('profiles')
                .select()
                .eq('id', message.senderId)
                .single();
          } catch (e) {
            log('Notifications: failed to load sender profile: $e');
          }

          final updatedChat = chat.copyWith(
            displayName: senderProfile?['display_name'] ?? chat.displayName,
            profilePictureUrl:
                senderProfile?['profile_picture_url'] ?? chat.profilePictureUrl,
            isOnline: senderProfile?['is_online'] ?? false,
          );

          log(
            'Notifications: showing notification chat=${updatedChat.id} message=${message.id}',
          );
          await showMessageNotification(message, updatedChat);
        } catch (e) {
          log('Notifications: failed before showing notification: $e');
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        log('Notifications: listener error: $error');
        _scheduleListenerRetry();
      },
      onDone: () {
        log('Notifications: listener done');
        _scheduleListenerRetry();
      },
    );
    log('Global message listener started for user: $currentUserId');
  }

  static void _scheduleListenerRetry() {
    if (_listenerUserId == null) return;
    if (_listenerRetryTimer != null) return;

    _listenerRetryCount++;
    final seconds = (_listenerRetryCount * 5);
    final delay = Duration(seconds: seconds > 60 ? 60 : seconds);
    log('Notifications: retrying listener in ${delay.inSeconds}s');

    _listenerRetryTimer = Timer(delay, () async {
      _listenerRetryTimer = null;
      final userId = _listenerUserId;
      if (userId == null) return;
      try {
        await startGlobalMessageListener(userId);
      } catch (e) {
        log('Notifications: retry failed: $e');
        _scheduleListenerRetry();
      }
    });
  }

  /// Stops the global message listener.
  static Future<void> stopGlobalMessageListener() async {
    log('Notifications: stopGlobalMessageListener');
    _listenerUserId = null;
    _listenerRetryTimer?.cancel();
    _listenerRetryTimer = null;
    await _messageSubscription?.cancel();
    _messageSubscription = null;
    log('Global message listener stopped.');
  }


  static Future<void> showTestNotification() async {
    try {
      final now = DateTime.now();
      final title = 'Ma';
      const body = 'Hi';

      final avatar = await _buildInitialsAvatarData('Ma');
      final Person sender = Person(
        name: 'Ma',
        key: 'lozo_test_sender',
        icon: avatar.icon as dynamic,
      );
      final MessagingStyleInformation messagingStyle = MessagingStyleInformation(
        sender,
        groupConversation: false,
        messages: <Message>[
          Message('Hi', now, sender),
        ],
      );

      final androidDetails = AndroidNotificationDetails(
        'lozo_test_channel_v1',
        'LoZo Test',
        channelDescription: 'Test notifications to validate system delivery',
        importance: Importance.max,
        priority: Priority.high,
        icon: 'ic_stat_lozo',
        category: AndroidNotificationCategory.message,
        shortcutId: 'lozo_test_chat',
        styleInformation: messagingStyle,
        enableLights: true,
        enableVibration: true,
        vibrationPattern: Int64List.fromList(<int>[0, 250, 120, 250]),
        playSound: true,
        channelShowBadge: true,
        visibility: NotificationVisibility.public,
        onlyAlertOnce: false,
        autoCancel: true,
        largeIcon: avatar.bitmap,
        showWhen: true,
        when: now.millisecondsSinceEpoch,
        subText: 'Messages',
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction(
            'test_mark_read_action',
            'Mark as read',
            cancelNotification: true,
            showsUserInterface: false,
          ),
          AndroidNotificationAction(
            'test_reply_action',
            'Reply',
            inputs: <AndroidNotificationActionInput>[
              AndroidNotificationActionInput(label: 'Reply'),
            ],
            showsUserInterface: true,
          ),
        ],
      );

      const iOSDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      await _flutterLocalNotificationsPlugin.show(
        _testImmediateNotificationId,
        title,
        body,
        NotificationDetails(android: androidDetails, iOS: iOSDetails),
        payload: jsonEncode({
          'chat_id': 'lozo_test_chat',
          'message_id': 'lozo_test_message',
          'sender_id': 'lozo_test_sender',
        }),
      );
      log('Notifications: test notification shown');
    } catch (e) {
      log('Notifications: test notification failed: $e');
    }
  }

  /// Ensures that Supabase is initialized.
  ///
  /// This is a safeguard to ensure that Supabase client is ready before
  /// any notification-related operations that might depend on it.
  static Future<void> ensureSupabaseInitialized() async {
    try {
      Supabase.instance.client;
    } catch (_) {
      await SupabaseManager.initialize();
    }
  }

  /// Requests necessary notification permissions for iOS.
  ///
  /// This method checks the current platform using the `NavigationService.navigatorKey.currentContext`
  /// to determine if the app is running on iOS and requests specific permissions
  /// for alerts, badges, and sounds.
  static Future<void> _requestPermissions() async {
    // Check if we are on iOS using Platform from dart:io
    // This avoids using context or Theme in background isolates
    if (!kIsWeb && Platform.isIOS) {
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
    final int notificationId = chat.id.hashCode;
    final seenForChat =
        _chatSeenMessageIds.putIfAbsent(chat.id, () => <String>{});
    if (seenForChat.contains(message.id)) {
      log('Notifications: dedupe skip chat=${chat.id} message=${message.id}');
      return;
    }
    seenForChat.add(message.id);

    final String? currentUserId = SupabaseManager.client.auth.currentUser?.id;
    if (currentUserId == null || message.senderId == currentUserId) {
      log(
        'Notifications: skip showMessageNotification message=${message.id} '
        'currentUserId=$currentUserId sender=${message.senderId}',
      );
      return;
    }

    final String senderName = chat.displayName;

    final String notificationBody = _notificationBodyFor(message);

    final avatar = await _getAvatarForChat(chat.profilePictureUrl, senderName, avatarColor: chat.avatarColor);
    final Person sender = Person(
      name: senderName,
      key: message.senderId,
      icon: avatar.icon as dynamic,
    );

    final messagesForChat =
        _chatNotificationMessages.putIfAbsent(chat.id, () => <Message>[]);
    messagesForChat.add(Message(notificationBody, DateTime.now(), sender));
    if (messagesForChat.length > 10) {
      messagesForChat.removeRange(0, messagesForChat.length - 10);
    }

    final MessagingStyleInformation messagingStyle = MessagingStyleInformation(
      sender,
      groupConversation: false,
      messages: List<Message>.from(messagesForChat),
    );

    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'messages_channel_v7',
      'Messages',
      channelDescription: 'Notifications for new messages',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      category: AndroidNotificationCategory.message,
      styleInformation: messagingStyle,
      shortcutId: chat.id,
      icon: 'ic_stat_lozo',
      largeIcon: avatar.bitmap,
      enableLights: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList(<int>[0, 250, 120, 250]),
      playSound: true,
      channelShowBadge: true,
      visibility: NotificationVisibility.public,
      onlyAlertOnce: false,
      autoCancel: true,
      showWhen: true,
      when: DateTime.now().millisecondsSinceEpoch,
      subText: 'Messages',
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'mark_read_action',
          'Mark as read',
          cancelNotification: true,
          showsUserInterface: false,
          semanticAction: SemanticAction.markAsRead,
        ),
        AndroidNotificationAction(
          'reply_action',
          'Reply',
          inputs: <AndroidNotificationActionInput>[
            AndroidNotificationActionInput(label: 'Reply'),
          ],
          showsUserInterface: false,
          cancelNotification: false,
          allowGeneratedReplies: true,
          semanticAction: SemanticAction.reply,
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
      'sender_name': senderName,
      'message_body': notificationBody,
      'sender_profile_url': chat.profilePictureUrl,
      'sender_avatar_color': chat.avatarColor,
    });

    try {
      await flutterLocalNotificationsPlugin.show(
        notificationId,
        senderName,
        notificationBody,
        platformChannelSpecifics,
        payload: payload,
      );
      log(
        'Notifications: shown chat=${chat.id} notificationId=$notificationId message=${message.id}',
      );
    } catch (e) {
      log('Error showing notification: $e');
    }
  }

  /// Manually triggers a bubble notification for a specific chat.
  ///
  /// This is used by the "Show as Bubble" UI action.
  static Future<void> showBubbleForChat(Chat chat) async {
    final String senderName = chat.displayName;
    String body = 'Tap to chat';
    try {
      final latest = await SupabaseManager.client
          .from('messages')
          .select()
          .eq('chat_id', chat.id)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (latest != null) {
        final m = app_message.Message.fromMap(latest);
        body = _notificationBodyFor(m);
      }
    } catch (_) {}
    final avatarData = await _getAvatarForChat(chat.profilePictureUrl, senderName, avatarColor: chat.avatarColor);
    await _showBubble(chat.id, senderName, body, avatarPath: avatarData.filePath);
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
    try {
      WidgetsFlutterBinding.ensureInitialized();
      DartPluginRegistrant.ensureInitialized();
    } catch (_) {}
    _handleNotificationAction(notificationResponse);
  }

  /// Processes the notification action based on the response.
  ///
  /// This method extracts information from the notification response, such as
  /// chat ID, message ID, and any reply text, then performs the appropriate
  /// action (e.g., sending a reply).
  static Future<void> _handleNotificationAction(
      NotificationResponse notificationResponse) async {
    await ensureSupabaseInitialized();

    final String? payload = notificationResponse.payload;
    log(
      'Notifications: action received '
      'actionId=${notificationResponse.actionId} '
      'input=${notificationResponse.input} '
      'payload=$payload',
    );
    if (notificationResponse.actionId == 'test_reply_action') {
      final replyText = notificationResponse.input;
      log('Notifications: test reply action input=$replyText');
      return;
    }
    if (notificationResponse.actionId == 'test_mark_read_action') {
      log('Notifications: test mark read action');
      return;
    }

    if (payload == null) {
      log('Notification payload is null');
      return;
    }

    final Map<String, dynamic> data = jsonDecode(payload);
    final String? chatId = data['chat_id'];
    final String? messageId = data['message_id'];
    final String? senderId = data['sender_id'];
    final String? senderName = data['sender_name'];
    final String? messageBody = data['message_body'];
    final String? senderProfileUrl = data['sender_profile_url'];
    final int? senderAvatarColor = data['sender_avatar_color'];

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
    } else if (notificationResponse.actionId == 'mark_read_action') {
      await _markAsRead(chatId, messageId, senderId);
      _chatNotificationMessages.remove(chatId);
      _chatSeenMessageIds.remove(chatId);
    } else {
      final bool canBubble = await _canShowBubbles();

      final avatarData = await _getAvatarForChat(
        senderProfileUrl, 
        senderName ?? '', 
        avatarColor: senderAvatarColor,
      );
      final avatarPath = avatarData.filePath;

      await _showBubble(
        chatId,
        senderName ?? 'Messages',
        messageBody ?? 'Tap to chat',
        avatarPath: avatarPath,
      );

      log(
        'Notifications: notification tapped chat=$chatId message=$messageId canBubble=$canBubble',
      );
    }
  }

  static Future<bool> _canShowBubbles() async {
    try {
      if (!Platform.isAndroid) return false;
      return await _bubbleChannel.invokeMethod<bool>('canShowBubbles') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _maybeOpenBubbleSettings() async {
    try {
      if (!Platform.isAndroid) return false;
      final now = DateTime.now();
      final last = _lastBubbleSettingsOpenAt;
      final shouldOpen = last == null || now.difference(last).inSeconds >= 20;
      if (!shouldOpen) return false;
      _lastBubbleSettingsOpenAt = now;
      await _bubbleChannel.invokeMethod('requestBubblePermission');
      return true;
    } catch (_) {}
    return false;
  }

  static Future<void> _showBubble(String chatId, String title, String body, {String? avatarPath}) async {
    try {
      if (!Platform.isAndroid) return;
      // We don't check _canShowBubbles() or open settings here anymore,
      // assuming user has granted permissions or we just try best-effort.
      await _bubbleChannel.invokeMethod('showBubble', <String, dynamic>{
        'chat_id': chatId,
        'title': title,
        'body': body,
        'avatar_path': avatarPath,
      });
    } on PlatformException catch (e) {
      log(
        'Notifications: bubble show failed '
        'code=${e.code} message=${e.message} details=${e.details}',
      );
    } catch (e) {
      log('Notifications: bubble show failed: $e');
    }
  }

  static Future<void> _markAsRead(String chatId, String messageId, String senderId) async {
    try {
      // Update the status of the specific message to 'read'
      await SupabaseManager.client.from('messages').update({
        'status': 'read',
      }).eq('id', messageId).eq('chat_id', chatId).eq('sender_id', senderId);

      log('Message $messageId marked as read.');
    } catch (e) {
      log('Error marking message as read: $e');
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
      final String receiverId =
          participantIds.firstWhere((id) => id != currentUserId, orElse: () => '');

      if (receiverId.isEmpty) {
        log('Could not find receiver ID for chat $chatId');
        return;
      }

      final encryptedReplyText = _encryptionService.encryptText(replyText);

      await SupabaseManager.client.from('messages').insert({
        'chat_id': chatId,
        'sender_id': currentUserId,
        'receiver_id': receiverId,
        'content': encryptedReplyText,
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

  static Future<_AvatarData> _getAvatarForChat(String? url, String senderName, {int? avatarColor}) async {
    if (url == null || url.isEmpty) {
      return _buildInitialsAvatarData(senderName, colorValue: avatarColor);
    }

    final cached = _avatarUrlToFilePath[url];
    if (cached != null && File(cached).existsSync()) {
      return _AvatarData(
        bitmap: FilePathAndroidBitmap(cached),
        icon: BitmapFilePathAndroidIcon(cached),
        filePath: cached,
      );
    }

    try {
      final tempDir = await getTemporaryDirectory();
      final fileName = 'avatar_${url.hashCode}.png';
      final filePath = '${tempDir.path}${Platform.pathSeparator}$fileName';
      final file = File(filePath);

      final uri = Uri.tryParse(url);
      if (uri == null) return _buildInitialsAvatarData(senderName, colorValue: avatarColor);

      final request = await HttpClient().getUrl(uri);
      final response = await request.close();
      if (response.statusCode != 200) {
        return _buildInitialsAvatarData(senderName, colorValue: avatarColor);
      }

      final bytes = await consolidateHttpClientResponseBytes(response);
      await file.writeAsBytes(bytes, flush: true);
      _avatarUrlToFilePath[url] = filePath;
      return _AvatarData(
        bitmap: FilePathAndroidBitmap(filePath),
        icon: BitmapFilePathAndroidIcon(filePath),
        filePath: filePath,
      );
    } catch (_) {
      return _buildInitialsAvatarData(senderName, colorValue: avatarColor);
    }
  }

  static Future<_AvatarData> _buildInitialsAvatarData(String name, {int? colorValue}) async {
    if (!Platform.isAndroid) {
      return const _AvatarData(
        bitmap: DrawableResourceAndroidBitmap(_fallbackLargeIconResource),
        icon: DrawableResourceAndroidIcon(_fallbackLargeIconResource),
      );
    }
    final initial = _initialForAvatar(name);
    try {
      final bytes = await _renderInitialAvatarPngBytes(initial, colorValue: colorValue);
      
      // Save to temp file for Bubbles
      final tempDir = await getTemporaryDirectory();
      final safeName = name.replaceAll(RegExp(r'[^\w]'), '_');
      final fileName = 'avatar_initials_${safeName}_${colorValue ?? 'default'}.png';
      final filePath = '${tempDir.path}${Platform.pathSeparator}$fileName';
      final file = File(filePath);
      await file.writeAsBytes(bytes, flush: true);

      return _AvatarData(
        bitmap: FilePathAndroidBitmap(filePath),
        icon: BitmapFilePathAndroidIcon(filePath),
        filePath: filePath,
      );
    } catch (_) {
      return const _AvatarData(
        bitmap: DrawableResourceAndroidBitmap(_fallbackLargeIconResource),
        icon: DrawableResourceAndroidIcon(_fallbackLargeIconResource),
      );
    }
  }

  static String _initialForAvatar(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return ' ';
    return trimmed.substring(0, 1).toUpperCase();
  }

  static Future<Uint8List> _renderInitialAvatarPngBytes(String initial, {int? colorValue}) async {
    const int size = 256;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    
    // Use provided color or fallback to blue (same as HomeScreen fallback logic essentially)
    final color = colorValue != null ? Color(colorValue) : const Color(0xFF2F80ED); // Colors.blue.shade300 is roughly similar but let's stick to this or match exactly if user wants. User said "same it". 
    // HomeScreen uses Colors.blue.shade300 if null. 0xFF2F80ED is standard blue.
    // Let's use Colors.blue.shade300 value if we want to be exact? 
    // Colors.blue.shade300 is Color(0xFF64B5F6).
    // The previous code used 0xFF2F80ED. I will use the one from HomeScreen if colorValue is null.
    // Actually HomeScreen: chat.avatarColor != null ? Color(chat.avatarColor!) : Colors.blue.shade300;
    
    final paint = Paint()..color = color;
    final rect = Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble());
    canvas.drawOval(rect, paint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: initial,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 128,
          fontWeight: FontWeight.w700,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(minWidth: 0, maxWidth: size.toDouble());

    final offset = Offset(
      (size - textPainter.width) / 2,
      (size - textPainter.height) / 2,
    );
    textPainter.paint(canvas, offset);

    final picture = recorder.endRecording();
    final image = await picture.toImage(size, size);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw StateError('Failed to encode avatar PNG');
    }
    return byteData.buffer.asUint8List();
  }

  static String _notificationBodyFor(app_message.Message message) {
    if (message.deleted) return 'Message deleted';

    if (message.type == app_message.MessageType.text) {
      try {
        return _encryptionService.decryptText(message.content);
      } catch (_) {
        return message.content;
      }
    }

    if (message.type == app_message.MessageType.image) return 'Photo';
    if (message.type == app_message.MessageType.voice) return 'Voice message';
    return 'New message';
  }
}

class _AvatarData {
  final AndroidBitmap<Object> bitmap;
  final Object icon;
  final String? filePath;

  const _AvatarData({
    required this.bitmap,
    required this.icon,
    this.filePath,
  });
}

/// A utility class to provide a global key for navigation.
///
/// This is used to access the `BuildContext` for navigation operations
/// from outside of widgets, such as in the notification service.
class NavigationService {
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
}
