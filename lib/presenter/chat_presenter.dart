import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:my_chat_app/data/message_repository.dart';
import 'package:my_chat_app/model/message.dart';
import 'package:my_chat_app/model/message_reaction.dart';
import 'package:my_chat_app/model/private_chat.dart';
import 'package:my_chat_app/model/profile.dart';
import 'package:my_chat_app/model/chat_participant.dart';
import 'package:my_chat_app/data/chat_repository.dart';
import 'package:my_chat_app/view/chat_view.dart';
import 'package:my_chat_app/services/media_service.dart';
import 'package:my_chat_app/services/encryption_service.dart';
import 'package:my_chat_app/data/user_repository.dart';
import 'package:my_chat_app/services/database_service.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'package:my_chat_app/services/sound_service.dart';
import 'package:my_chat_app/notification_service.dart';
import 'package:flutter/foundation.dart';

/// Presenter for the chat screen.
/// Handles all business logic related to a specific chat, including message sending,
/// receiving, media handling, and encryption.
class ActiveChatState extends ChangeNotifier {
  String? _activeChatId;

  String? get activeChatId => _activeChatId;

  void openChat(String chatId) {
    _activeChatId = chatId;
    notifyListeners();
  }

  void closeChat() {
    _activeChatId = null;
    notifyListeners();
  }
}

class ChatPresenter {
  final ChatView _view;
  final ChatRepository _chatRepository;
  final MessageRepository _messageRepository;
  final MediaService _mediaService;
  final EncryptionService _encryptionService;
  final UserRepository _userRepository;
  final ActiveChatState _activeChatState;
  final SupabaseClient _supabase = Supabase.instance.client;
  final String? _cachedUserId;
  final PrivateChat _chat;
  Profile _otherProfile;
  final _uuid = const Uuid();
  List<Message> _messages = [];
  final List<Message> _optimisticMessages = [];

  Message? _selectedMessageForReply;
  Message? _selectedMessageForEdit;

  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentRecordingPath;
  bool _isRecording = false;
  Timer? _typingTimer;
  Timer? _readTimer;
  StreamSubscription? _otherUserStatusSubscription;
  StreamSubscription<List<ChatParticipant>>? _participantsSubscription;
  bool _isLoadingOlder = false;
  bool _hasMoreOlder = true;
  ChatParticipant? _otherParticipant;

  ChatPresenter(this._view, this._chat, this._otherProfile)
      : _cachedUserId = Supabase.instance.client.auth.currentUser?.id,
        _chatRepository = ChatRepository(),
        _messageRepository = MessageRepository(),
        _mediaService = MediaService(),
        _encryptionService = EncryptionService(),
        _userRepository = UserRepository(),
        _activeChatState = ActiveChatState();

  String? get currentUserId => _supabase.auth.currentUser?.id ?? _cachedUserId;

  List<Message> get messages => _messages;
  Message? get selectedMessageForReply => _selectedMessageForReply;
  Message? get selectedMessageForEdit => _selectedMessageForEdit; // Corrected line
  bool get isRecording => _isRecording;
  bool _otherUserTyping = false;
  bool get otherUserTyping => _otherUserTyping;
  Profile get otherProfile => _otherProfile;
  ActiveChatState get activeChatState => _activeChatState;

  /// Loads messages for the current chat and sets up a real-time listener.
  void loadMessages() {
    _activeChatState.openChat(_chat.id);

    DatabaseService.getMessages(_chat.id).then((cached) {
      _messages = _decryptMessages(cached);
      _updateViewWithCombinedMessages();
    });

    _messageRepository.streamByChat(_chat.id).listen((messages) async {
      final previousIds = _messages.map((m) => m.id).toSet();
      _messages = _decryptMessages(messages);
      final confirmedIds = _messages.map((m) => m.id).toSet();
      _optimisticMessages.removeWhere((m) => confirmedIds.contains(m.id));
      _markIncomingMessagesAsDelivered(_messages, previousIds);
      if (_otherParticipant != null) {
        await _applyOutgoingStatus(_otherParticipant!);
      }
      final otherId = _getOtherUserId(currentUserId);
      final hasNewIncoming =
          _messages.any((m) => m.senderId == otherId && !previousIds.contains(m.id));
      if (NotificationService.currentActiveChatId == _chat.id && hasNewIncoming) {
        scheduleReadMark();
      }
      _updateViewWithCombinedMessages();
    });

    final otherUserId = _getOtherUserId(currentUserId);
    if (otherUserId != null) {
      _otherUserStatusSubscription =
          _userRepository.getCurrentUserStream(otherUserId).listen((otherUser) {
        if (otherUser != null) {
          _otherProfile = otherUser;
          if (NotificationService.currentActiveChatId == _chat.id) {
            scheduleReadMark();
          }
          _view.updateView();
        }
      });
    }

    _participantsSubscription?.cancel();
    final participantOtherId = _getOtherUserId(currentUserId);
    if (participantOtherId.isNotEmpty) {
      _participantsSubscription =
          _chatRepository.streamParticipants(_chat.id).listen((participants) async {
        ChatParticipant? otherParticipant;
        for (final participant in participants) {
          if (participant.userId == participantOtherId) {
            otherParticipant = participant;
            break;
          }
        }
        if (otherParticipant == null) return;
        _otherParticipant = otherParticipant;
        await _applyOutgoingStatus(otherParticipant);
      });
    }
    _loadParticipantsOnce();
  }

  Future<void> _markIncomingMessagesAsDelivered(
    List<Message> messages,
    Set<String> previousIds,
  ) async {
    if (currentUserId == null) return;
    final otherId = _getOtherUserId(currentUserId);
    final toDeliver = messages
        .where((m) => m.senderId == otherId && !previousIds.contains(m.id))
        .toList();
    if (toDeliver.isEmpty) return;
    for (final message in toDeliver) {
      try {
        await _chatRepository.markMessageDelivered(_chat.id, message.id);
      } catch (e) {}
    }
    final updated = _messages.map((message) {
      if (toDeliver.any((m) => m.id == message.id)) {
        return message.copyWith(status: MessageStatus.delivered);
      }
      return message;
    }).toList();
    if (updated.isNotEmpty) {
      _messages = updated;
      _updateViewWithCombinedMessages();
      await DatabaseService.saveMessages(_messages);
    }
    if (NotificationService.currentActiveChatId == _chat.id) {
      SoundService.instance.playReceived();
    }
  }

  /// Sends a text message. Encrypts the content before sending.
  Future<void> sendTextMessage(String content) async {
    if (currentUserId == null) {
      _view.showMessage('User not authenticated.');
      return;
    }

    if (content.trim().isEmpty) {
      _view.showMessage('Message cannot be empty.');
      return;
    }

    final encryptedContent = _encryptionService.encryptText(content);

    final messageId = _uuid.v4();
    final message = Message(
      id: messageId,
      chatId: _chat.id,
      senderId: currentUserId!,
      type: MessageType.text,
      content: encryptedContent,
      replyToMessageId: _selectedMessageForReply?.id,
      status: MessageStatus.sending,
      createdAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
    );

    // Add to optimistic messages for immediate display
    // We use the unencrypted content for local display in the optimistic message
    final optimisticMessage = message.copyWith(content: content);
    _optimisticMessages.add(optimisticMessage);
    _updateViewWithCombinedMessages();

    // Introduce a delay to visually show "sending" state
    await Future.delayed(const Duration(seconds: 0));
    final success = await _sendMessage(message, plainTextPreview: content);
    if (!success) {
      _handleSendFailure(messageId);
    } else {
      // Play sound only after successful send (one check)
      SoundService.instance.playSent();
    }
    _selectedMessageForReply = null;
    _view.updateView();
  }

  /// Updates the view with a combination of real messages and optimistic (unsent) messages.
  void _updateViewWithCombinedMessages() {
    final combined = [..._messages, ..._optimisticMessages];
    // Sort by timestamp descending (newest first)
    // Since ListView is reversed (reverse: true), index 0 (newest) will be at the bottom.
    final epoch = DateTime.fromMillisecondsSinceEpoch(0);
    combined.sort((a, b) {
      final aTime = a.createdAt ?? a.updatedAt ?? epoch;
      final bTime = b.createdAt ?? b.updatedAt ?? epoch;
      final timeCompare = bTime.compareTo(aTime);
      if (timeCompare != 0) {
        return timeCompare;
      }
      return b.id.compareTo(a.id);
    });
    _view.displayMessages(combined);
  }

  String _getOtherUserId(String? userId) {
    if (userId == _chat.userOneId) {
      return _chat.userTwoId;
    }
    if (userId == _chat.userTwoId) {
      return _chat.userOneId;
    }
    return _chat.userTwoId;
  }

  Future<bool> _sendMessage(
    Message message, {
    String? plainTextPreview,
  }) async {
    await DatabaseService.saveMessages([message], pendingSync: true);
    final changeId =
        await DatabaseService.enqueueMessageChange(message, action: 'create');
    try {
      final created = await _messageRepository.create(message);
      await DatabaseService.saveMessages([created]);
      await DatabaseService.removePendingChange(changeId);
      await _sendPushForMessage(created, plainTextPreview: plainTextPreview);
      return true;
    } on PostgrestException catch (e) {
      _view.showMessage('Send failed: ${e.message}');
      return false;
    } catch (e) {
      _view.showMessage('Send failed: $e');
      return false;
    }
  }

  Future<void> _sendPushForMessage(
    Message message, {
    String? plainTextPreview,
  }) async {
    try {
      final senderId = currentUserId;
      if (senderId == null) return;
      final recipientId = _getOtherUserId(senderId);
      if (recipientId.isEmpty) return;

      final body = NotificationService.buildNotificationBody(
        message,
        plainText: plainTextPreview,
      );

      Map<String, dynamic>? senderProfile;
      try {
        senderProfile = await _supabase
            .from('profiles')
            .select('display_name, avatar_url, avatar_color')
            .eq('id', senderId)
            .maybeSingle();
      } catch (_) {}

      final userMetadata = _supabase.auth.currentUser?.userMetadata ?? {};
      final displayName = senderProfile?['display_name'] ??
          userMetadata['display_name'] ??
          userMetadata['displayName'] ??
          userMetadata['username'] ??
          userMetadata['full_name'];
      final avatarUrl = senderProfile?['avatar_url'] ??
          userMetadata['avatar_url'] ??
          userMetadata['avatarUrl'] ??
          userMetadata['picture'];
      final avatarColor = senderProfile?['avatar_color'] ??
          userMetadata['avatar_color'] ??
          userMetadata['avatarColor'];

      final data = <String, dynamic>{
        'chat_id': message.chatId,
        'message_id': message.id,
        'sender_id': senderId,
        'recipient_id': recipientId,
        'message_body': body,
      };

      if (displayName is String && displayName.isNotEmpty) {
        data['sender_name'] = displayName;
      }
      if (avatarUrl is String && avatarUrl.isNotEmpty) {
        data['sender_profile_url'] = avatarUrl;
      }
      if (avatarColor is int) {
        data['sender_avatar_color'] = avatarColor;
      } else if (avatarColor is String) {
        final parsed = int.tryParse(avatarColor);
        if (parsed != null) {
          data['sender_avatar_color'] = parsed;
        }
      }

      final title =
          displayName is String && displayName.isNotEmpty
              ? displayName
              : 'New message';

      await NotificationService.sendPushNotification(
        recipientIds: [recipientId],
        title: title,
        body: body,
        data: data,
      );
    } catch (_) {}
  }

  void _handleSendFailure(String messageId) {
    final isConnected = _supabase.realtime.isConnected;
    final nextStatus = isConnected ? MessageStatus.failed : MessageStatus.sending;
    for (var i = 0; i < _optimisticMessages.length; i++) {
      final message = _optimisticMessages[i];
      if (message.id == messageId) {
        _optimisticMessages[i] = message.copyWith(status: nextStatus);
        break;
      }
    }
    _updateViewWithCombinedMessages();
    if (isConnected) {
      // _view.showMessage('Failed to send message.');
    }
  }

  Future<void> _updateMessage(Message message) async {
    await DatabaseService.saveMessages([message], pendingSync: true);
    final changeId =
        await DatabaseService.enqueueMessageChange(message, action: 'update');
    try {
      await _messageRepository.update(message);
      await DatabaseService.removePendingChange(changeId);
    } catch (e) {}
  }

  Future<void> _updateMessageStatus(
    String messageId,
    MessageStatus status,
  ) async {
    final message = getMessageById(messageId);
    if (message == null) return;
    final updated = message.copyWith(
      status: status,
      updatedAt: DateTime.now().toUtc(),
    );
    _messages = _messages.map((m) => m.id == messageId ? updated : m).toList();
    _view.displayMessages(_messages);
    _view.updateView();
    await _updateMessage(updated);
  }

  List<Message> _decryptMessages(List<Message> messages) {
    return messages.map((message) {
      if (message.type != MessageType.text) {
        return message;
      }
      if (message.content == null) {
        return message;
      }
      try {
        final decryptedContent = _encryptionService.decryptText(message.content!);
        return message.copyWith(
          content: decryptedContent,
        );
      } catch (e) {
        return message.copyWith(content: 'Decryption Error');
      }
    }).toList();
  }

  bool _isTyping = false;

  /// Notify typing status. Debounced to avoid excessive database writes.
  void notifyTyping(bool isTyping) {
    if (currentUserId == null) return;
    _isTyping = isTyping;
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      _isTyping = false;
    });
  }

  /// Starts recording a voice message.
  Future<void> startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final directory = await getApplicationDocumentsDirectory();
        _currentRecordingPath = '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _audioRecorder.start(const RecordConfig(), path: _currentRecordingPath!); // Added config
        _isRecording = true;
        _view.updateView();
      }
    } catch (e) {
      _view.showMessage('Failed to start recording: $e');
    }
  }

  /// Stops recording and discards the voice message.
  Future<void> stopRecordingAndCancel() async {
    try {
      await _audioRecorder.stop();
      _isRecording = false;
      _view.updateView();
    } catch (e) {
      _view.showMessage('Failed to cancel recording: $e');
    }
  }

  /// Stops recording and sends the voice message. Uploads to Supabase Storage via MediaService.
  Future<void> stopRecordingAndSend() async {
    try {
      final path = await _audioRecorder.stop();
      _isRecording = false;
      _view.updateView();

      if (path != null && currentUserId != null) {
        final storagePath = 'chat_media/${_chat.id}/voice/${DateTime.now().millisecondsSinceEpoch}.m4a';
        final mediaUrl = await _mediaService.uploadFile(path, storagePath);
        if (mediaUrl != null) {
          final messageId = _uuid.v4();
          final message = Message(
            id: messageId,
            chatId: _chat.id,
            senderId: currentUserId!,
            type: MessageType.audio,
            content: mediaUrl,
            status: MessageStatus.sending,
            replyToMessageId: _selectedMessageForReply?.id,
            createdAt: DateTime.now().toUtc(),
            updatedAt: DateTime.now().toUtc(),
          );

          // Add to optimistic messages for immediate display
          _optimisticMessages.add(message);
          _updateViewWithCombinedMessages();

          final success = await _sendMessage(message);
          if (success) {
            SoundService.instance.playSent();
          } else {
            _handleSendFailure(messageId);
          }
          _selectedMessageForReply = null;
          _view.updateView();
        } else {
          _view.showMessage('Failed to upload voice message.');
        }
      }
    } catch (e) {
      _view.showMessage('Failed to stop recording: $e');
    }
  }

  /// Plays a voice message from a given URL.
  Future<void> playVoiceMessage(String url) async {
    try {
      await _audioPlayer.play(UrlSource(url));
    } catch (e) {
      _view.showMessage('Failed to play voice message: $e');
    }
  }

  /// Pauses the currently playing voice message.
  Future<void> pauseVoiceMessage() async {
    await _audioPlayer.pause();
  }

  /// Stops the currently playing voice message.
  Future<void> stopVoiceMessage() async {
    await _audioPlayer.stop();
  }

  /// Sends an image message. Allows picking from gallery or camera and uploads via MediaService.
  Future<void> sendImageMessage(ImageSource source) async {
    if (currentUserId == null) {
      _view.showMessage('User not authenticated.');
      return;
    }

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source);

      if (image != null) {
        // TODO: Implement image editing (crop, rotate, preview) before sending
        // For now, directly upload the selected image.

        final storagePath = 'chat_media/${_chat.id}/image/${DateTime.now().millisecondsSinceEpoch}.jpg';
        final mediaUrl = await _mediaService.uploadFile(image.path, storagePath);
        if (mediaUrl != null) {
          final messageId = _uuid.v4();
          final message = Message(
            id: messageId,
            chatId: _chat.id,
            senderId: currentUserId!,
            type: MessageType.image,
            content: mediaUrl,
            status: MessageStatus.sending, // Set initial status
            replyToMessageId: _selectedMessageForReply?.id,
            createdAt: DateTime.now().toUtc(),
            updatedAt: DateTime.now().toUtc(),
          );

          // Add to optimistic messages for immediate display
          _optimisticMessages.add(message);
          _updateViewWithCombinedMessages();

          // Introduce a delay to visually show "sending" state
          await Future.delayed(const Duration(seconds: 0));
          final success = await _sendMessage(message);
          if (success) {
            SoundService.instance.playSent();
          } else {
            _handleSendFailure(messageId);
          }
          _selectedMessageForReply = null;
          _view.updateView();
        } else {
          _view.showMessage('Failed to upload image message.');
        }
      }
    } catch (e) {
    }
  }

  /// Sets a message as the target for a reply.
  void selectMessageForReply(Message message) {
    _selectedMessageForReply = message;
    _view.updateView();
  }

  /// Clears the reply state.
  void cancelReply() {
    _selectedMessageForReply = null;
    _view.updateView();
  }

  /// Sets a message as the target for editing.
  void selectMessageForEdit(Message message) {
    _selectedMessageForEdit = message;
    _view.updateView();
  }

  /// Clears the edit state.
  void cancelEdit() {
    _selectedMessageForEdit = null;
    _view.updateView();
  }

  /// Confirms and sends an edited text message. Encrypts the new content.
  Future<void> confirmEditMessage(String newContent) async {
    if (_selectedMessageForEdit == null || currentUserId == null) return;

    if (newContent.trim().isEmpty) {
      _view.showMessage('Edited message cannot be empty.');
      return;
    }

    final encryptedContent = _encryptionService.encryptText(newContent);
    final now = DateTime.now().toUtc();
    final updated = _selectedMessageForEdit!.copyWith(
      content: encryptedContent,
      isEdited: true,
      updatedAt: now,
    );
    await _updateMessage(updated);
    _messages = _messages.map((m) => m.id == updated.id ? updated : m).toList();
    _selectedMessageForEdit = null;
    _view.updateView();
  }

  /// Deletes a message after confirmation by user.
  Future<void> deleteMessage(Message message) async {
    if (currentUserId == null) return;
    if (message.senderId != currentUserId) {
      _view.showMessage('You can only delete your own messages.');
      return;
    }
    final now = DateTime.now().toUtc();
    final updated = message.copyWith(
      isDeleted: true,
      updatedAt: now,
    );
    await _updateMessage(updated);
    _messages = _messages.map((m) => m.id == updated.id ? updated : m).toList();
    _view.updateView();
  }

  /// Updates the status of a message.
  Future<void> updateMessageStatus(String messageId, MessageStatus status) async {
    await _updateMessageStatus(messageId, status);
  }

  /// Adds an emoji reaction to a message.
  Future<void> addReaction(String messageId, String emoji) async {
    if (currentUserId == null) return;
    final reaction = MessageReaction(
      id: _uuid.v4(),
      messageId: messageId,
      userId: currentUserId!,
      emoji: emoji,
      createdAt: DateTime.now().toUtc(),
    );
    await _messageRepository.addReaction(reaction);
  }

  /// Removes a user's emoji reaction from a message.
  Future<void> removeReaction(String messageId) async {
    if (currentUserId == null) return;
    final message = getMessageById(messageId);
    if (message == null) return;
    final emoji = message.reactions[currentUserId!];
    if (emoji == null || emoji.isEmpty) return;
    await _messageRepository.removeReaction(
      messageId: messageId,
      userId: currentUserId!,
      emoji: emoji,
    );
  }

  /// Retrieves a message by its ID from the currently loaded messages.
  Message? getMessageById(String messageId) {
    try {
      return _messages.firstWhere((msg) => msg.id == messageId);
    } catch (e) {
      return null;
    }
  }

  PrivateChat get chat => _chat;

  /// Disposes of resources used by the presenter (e.g., audio recorder, player).
  /// Deletes a chat and all its messages.
  Future<void> deleteChat(String chatId) async {
    try {
      await _chatRepository.delete(chatId);
      _view.showMessage('Chat deleted successfully.');
    } catch (e) {
      _view.showMessage('Failed to delete chat: $e');
    }
  }

  /// Loads older messages for pagination.
  Future<void> loadOlderMessages() async {
    if (_isLoadingOlder || !_hasMoreOlder) return;

    _isLoadingOlder = true;
    _view.updateView();

    try {
      final oldest = _messages
          .map((m) => m.createdAt ?? m.updatedAt)
          .whereType<DateTime>()
          .fold<DateTime?>(null, (prev, current) {
        if (prev == null) return current;
        return current.isBefore(prev) ? current : prev;
      });
      final olderMessages = await _messageRepository.fetchByChat(
        _chat.id,
        limit: 50,
        before: oldest,
      );
      
      if (olderMessages.isEmpty) {
        _hasMoreOlder = false;
      } else {
        final decryptedOlder = _decryptMessages(olderMessages);

        // Add to existing messages and update view
        final existingIds = _messages.map((m) => m.id).toSet();
        final newItems =
            decryptedOlder.where((m) => !existingIds.contains(m.id)).toList();
        _messages.addAll(newItems);
        _updateViewWithCombinedMessages();
      }
    } catch (e) {
      debugPrint('ChatPresenter: Error loading older messages: $e');
    } finally {
      _isLoadingOlder = false;
      _view.updateView();
    }
  }

  void dispose() {
    // Clear active chat ID for the current user
    _activeChatState.closeChat();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    _otherUserStatusSubscription?.cancel(); // Cancel the status subscription
    _participantsSubscription?.cancel();
    _readTimer?.cancel();
  }

  /// Marks all delivered messages from the other user as read.
  void markMessagesAsRead() async {
    if (NotificationService.currentActiveChatId != _chat.id) return;
    if (currentUserId == null) return;
    final otherUserId = _getOtherUserId(currentUserId);
    final deliveredMessages = _messages.where((message) =>
        message.senderId == otherUserId &&
        (message.status == MessageStatus.delivered || message.status == MessageStatus.sent));

    if (deliveredMessages.isEmpty) return;

    try {
      await _chatRepository.markChatRead(_chat.id);
      // Update local state
      _messages = _messages.map((m) {
        if (m.senderId == otherUserId) {
          return m.copyWith(status: MessageStatus.read);
        }
        return m;
      }).toList();
      _view.displayMessages(_messages);
      _view.updateView();
      // Clear notifications for this chat after marking as read
      NotificationService.flutterLocalNotificationsPlugin.cancel(_chat.id.hashCode);
      NotificationService.flutterLocalNotificationsPlugin.cancel(_chat.id.hashCode + 1);
    } catch (e) {
      debugPrint('ChatPresenter: Failed to mark messages as read: $e');
    }
  }

  /// Schedules marking messages as read after a short dwell to avoid accidental flicker.
  void scheduleReadMark({Duration dwell = const Duration(milliseconds: 800)}) {
    _readTimer?.cancel();
    _readTimer = Timer(dwell, () {
      // If we are in this chat, always mark messages as read
      if (NotificationService.currentActiveChatId == _chat.id) {
        markMessagesAsRead();
      }
    });
  }

  Future<void> _loadParticipantsOnce() async {
    final participantOtherId = _getOtherUserId(currentUserId);
    if (participantOtherId.isEmpty) return;
    try {
      final participants = await _chatRepository.fetchParticipants(_chat.id);
      ChatParticipant? otherParticipant;
      for (final participant in participants) {
        if (participant.userId == participantOtherId) {
          otherParticipant = participant;
          break;
        }
      }
      if (otherParticipant == null) return;
      _otherParticipant = otherParticipant;
      await _applyOutgoingStatus(otherParticipant);
    } catch (e) {}
  }

  DateTime? _messageTimeForId(String? messageId) {
    if (messageId == null || messageId.isEmpty) return null;
    final message = getMessageById(messageId);
    return message?.createdAt ?? message?.updatedAt;
  }

  Future<void> _applyOutgoingStatus(ChatParticipant participant) async {
    if (currentUserId == null) return;
    if (_messages.isEmpty) return;
    final deliveredTime = _messageTimeForId(participant.lastDeliveredMessageId);
    final readTime = _messageTimeForId(participant.lastReadMessageId);
    var changed = false;
    _messages = _messages.map((message) {
      if (message.senderId != currentUserId) return message;
      if (message.status == MessageStatus.sending) return message;
      final time = message.createdAt ?? message.updatedAt;
      if (time == null) return message;
      var nextStatus = message.status;
      if (readTime != null && !time.isAfter(readTime)) {
        nextStatus = MessageStatus.read;
      } else if (deliveredTime != null && !time.isAfter(deliveredTime)) {
        nextStatus = MessageStatus.delivered;
      } else {
        nextStatus = MessageStatus.sent;
      }
      if (nextStatus != message.status) {
        changed = true;
        return message.copyWith(status: nextStatus);
      }
      return message;
    }).toList();
    if (changed) {
      _view.displayMessages(_messages);
      _updateViewWithCombinedMessages();
      await DatabaseService.saveMessages(_messages);
    }
  }
}
