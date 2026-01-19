import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:my_chat_app/data/chat_repository.dart';
import 'package:my_chat_app/model/chat.dart';
import 'package:my_chat_app/model/message.dart';
import 'package:my_chat_app/view/chat_view.dart';
import 'package:my_chat_app/services/media_service.dart';
import 'package:my_chat_app/services/encryption_service.dart';
import 'package:my_chat_app/services/local_storage_service.dart';
import 'package:my_chat_app/data/user_repository.dart';
import 'package:my_chat_app/model/user.dart' as model;
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'package:my_chat_app/services/sound_service.dart';
import 'package:my_chat_app/notification_service.dart';

/// Presenter for the chat screen.
/// Handles all business logic related to a specific chat, including message sending,
/// receiving, media handling, and encryption.
class ChatPresenter {
  final ChatView _view;
  final ChatRepository _chatRepository;
  final MediaService _mediaService;
  final EncryptionService _encryptionService;
  final LocalStorageService _localStorageService = LocalStorageService();
  final UserRepository _userRepository;
  final SupabaseClient _supabase = Supabase.instance.client;
  final Chat _chat;
  final _uuid = const Uuid();
  List<Message> _messages = [];
  List<Message> _optimisticMessages = [];
  Set<String> _seenMessageIds = {};

  Message? _selectedMessageForReply;
  Message? _selectedMessageForEdit;

  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentRecordingPath;
  bool _isRecording = false;
  Timer? _typingTimer;
  Timer? _readTimer;
  StreamSubscription? _otherUserStatusSubscription;
  bool _otherUserInChat = false;
  bool _otherUserInChatPrev = false;
  bool _isLoadingOlder = false;
  bool _hasMoreOlder = true;

  ChatPresenter(this._view, this._chat)
      : _chatRepository = ChatRepository(),
        _mediaService = MediaService(),
        _encryptionService = EncryptionService(),
        _userRepository = UserRepository();

  String? get currentUserId => _supabase.auth.currentUser?.id;

  List<Message> get messages => _messages;
  Message? get selectedMessageForReply => _selectedMessageForReply;
  Message? get selectedMessageForEdit => _selectedMessageForEdit; // Corrected line
  bool get isRecording => _isRecording;
  bool _otherUserTyping = false;
  bool get otherUserTyping => _otherUserTyping;
  bool get otherUserInChat => _otherUserInChat;

  /// Loads messages for the current chat and sets up a real-time listener.
  void loadMessages() {
    // Set active chat ID for the current user
    if (currentUserId != null) {
      _userRepository.updateActiveChatId(currentUserId!, _chat.id);
    }

    _chatRepository.getChatMessages(_chat.id).listen((messages) {
      final previousIds = _messages.map((m) => m.id).toSet();
      _messages = messages.map<Message>((message) {
        // Decrypt text messages before displaying.
        if (message.type == MessageType.text) {
          try {
            final decryptedContent = _encryptionService.decryptText(message.content);
            String? decryptedEditedContent;
            if (message.editedContent != null) {
              decryptedEditedContent = _encryptionService.decryptText(message.editedContent!);
            }
            return message.copyWith(
              content: decryptedContent,
              editedContent: decryptedEditedContent,
            );
          } catch (e) {
            print('ChatPresenter: Decryption failed for message ID: ${message.id}. Error: $e');
            return message.copyWith(content: 'Decryption Error: Invalid or corrupt message content.');
          }
        }
        return message;
      }).toList();

      // Remove optimistic messages that are now confirmed by the stream
      final confirmedIds = _messages.map((m) => m.id).toSet();
      _optimisticMessages.removeWhere((m) => confirmedIds.contains(m.id));

      _markIncomingMessagesAsDelivered(_messages, previousIds);
      final otherId = _chat.getOtherUserId(currentUserId!);
      final hasNewIncoming = _messages.any((m) => m.senderId == otherId && !previousIds.contains(m.id));
      if (NotificationService.currentActiveChatId == _chat.id && hasNewIncoming) {
        // Schedule read marking for new incoming while we are in chat
        scheduleReadMark();
      }
      _updateViewWithCombinedMessages();
    });

    // Subscribe to other user's online status
    final otherUserId = _chat.getOtherUserId(currentUserId!);
    _otherUserStatusSubscription = _userRepository.getCurrentUserStream(otherUserId).listen((otherUser) {
      if (otherUser != null) {
        final wasInChat = _otherUserInChat;
        _chat.isOnline = otherUser.isOnline;
        _chat.lastSeen = otherUser.lastSeen;
        _otherUserInChat = otherUser.activeChatId == _chat.id;
        _otherUserInChatPrev = wasInChat;
        // If we are in this chat, always schedule read marking
        if (NotificationService.currentActiveChatId == _chat.id) {
          scheduleReadMark();
        }
        _view.updateView(); // Notify UI to rebuild with updated status
      }
    });

    // Subscribe to chat document for typing/presence updates
    _chatRepository.getChatDocStream(_chat.id).listen((data) {
      try {
        if (data.isNotEmpty && data['typing_status'] is Map<String, dynamic>) {
          final typingMap = Map<String, dynamic>.from(data['typing_status']);
          final otherId = _chat.getOtherUserId(currentUserId!);
          final isTyping = typingMap[otherId] == true;
          _otherUserTyping = isTyping;
          _view.updateView();
        }
      } catch (e) {
        // ignore parsing errors
      }
    });
  }

  /// Filters incoming messages with status=sent and marks them delivered using a batch update.
  Future<void> _markIncomingMessagesAsDelivered(List<Message> messages, Set<String> previousIds) async {
    if (currentUserId == null) return;
    final otherId = _chat.getOtherUserId(currentUserId!);
    final toDeliver = <String, MessageStatus>{};
    for (final m in messages) {
      if (m.senderId == otherId && m.status == MessageStatus.sent) {
        toDeliver[m.id] = MessageStatus.delivered;
      }
    }
    if (toDeliver.isEmpty) return;
    try {
      await _chatRepository.updateMessagesStatusBatch(_chat.id, toDeliver);
      // Update local state immediately
      _messages = _messages.map((m) {
        if (toDeliver.containsKey(m.id)) {
          return m.copyWith(status: MessageStatus.delivered);
        }
        return m;
      }).toList();
      // Trigger sound if chat is open and any of these were new
      final hadNewDelivered = _messages.any((m) => toDeliver.containsKey(m.id) && !previousIds.contains(m.id));
      if (hadNewDelivered && NotificationService.currentActiveChatId == _chat.id) {
        SoundService.instance.playReceived();
      }
    } catch (e) {
      // If batch fails, fall back to individual updates
      for (final entry in toDeliver.entries) {
        await _chatRepository.updateMessageStatus(_chat.id, entry.key, entry.value);
      }
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
      receiverId: _chat.getOtherUserId(currentUserId!),
      type: MessageType.text,
      content: encryptedContent,
      timestamp: DateTime.now().toUtc(),
      status: MessageStatus.sending, // Set initial status
      replyToMessageId: _selectedMessageForReply?.id,
    );

    // Add to optimistic messages for immediate display
    // We use the unencrypted content for local display in the optimistic message
    final optimisticMessage = message.copyWith(content: content);
    _optimisticMessages.add(optimisticMessage);
    _updateViewWithCombinedMessages();

    // Introduce a delay to visually show "sending" state
    await Future.delayed(const Duration(seconds: 0));
    final error = await _chatRepository.sendMessage(message);
    if (error != null) {
      _optimisticMessages.removeWhere((m) => m.id == messageId);
      _updateViewWithCombinedMessages();
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
    combined.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    _view.displayMessages(combined);
  }

  bool _isTyping = false;

  /// Notify typing status. Debounced to avoid excessive database writes.
  void notifyTyping(bool isTyping) {
    if (currentUserId == null) return;
    
    if (isTyping && !_isTyping) {
      // Started typing
      _isTyping = true;
      _chatRepository.setTypingStatus(_chat.id, currentUserId!, true);
    }

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      if (_isTyping) {
        _isTyping = false;
        _chatRepository.setTypingStatus(_chat.id, currentUserId!, false);
      }
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
            receiverId: _chat.getOtherUserId(currentUserId!),
            type: MessageType.voice,
            content: mediaUrl,
            timestamp: DateTime.now().toUtc(),
            replyToMessageId: _selectedMessageForReply?.id,
          );

          // Add to optimistic messages for immediate display
          _optimisticMessages.add(message);
          _updateViewWithCombinedMessages();

          final error = await _chatRepository.sendMessage(message);
          if (error == null) {
            SoundService.instance.playSent();
          } else {
            _optimisticMessages.removeWhere((m) => m.id == messageId);
            _updateViewWithCombinedMessages();
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
            receiverId: _chat.getOtherUserId(currentUserId!),
            type: MessageType.image,
            content: mediaUrl,
            timestamp: DateTime.now().toUtc(),
            status: MessageStatus.sending, // Set initial status
            replyToMessageId: _selectedMessageForReply?.id,
          );

          // Add to optimistic messages for immediate display
          _optimisticMessages.add(message);
          _updateViewWithCombinedMessages();

          // Introduce a delay to visually show "sending" state
          await Future.delayed(const Duration(seconds: 0));
          final error = await _chatRepository.sendMessage(message);
          if (error == null) {
            SoundService.instance.playSent();
          } else {
            _optimisticMessages.removeWhere((m) => m.id == messageId);
            _updateViewWithCombinedMessages();
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
    await _chatRepository.editTextMessage(_chat.id, _selectedMessageForEdit!.id, encryptedContent);
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
    await _chatRepository.deleteMessage(_chat.id, message.id);
    _view.updateView();
  }

  /// Updates the status of a message.
  Future<void> updateMessageStatus(String messageId, MessageStatus status) async {
    await _chatRepository.updateMessageStatus(_chat.id, messageId, status);
  }

  /// Adds an emoji reaction to a message.
  Future<void> addReaction(String messageId, String emoji) async {
    if (currentUserId == null) return;
    await _chatRepository.addReactionToMessage(_chat.id, messageId, currentUserId!, emoji);
  }

  /// Removes a user's emoji reaction from a message.
  Future<void> removeReaction(String messageId) async {
    if (currentUserId == null) return;
    await _chatRepository.removeReactionFromMessage(_chat.id, messageId, currentUserId!);
  }

  /// Retrieves a message by its ID from the currently loaded messages.
  Message? getMessageById(String messageId) {
    try {
      return _messages.firstWhere((msg) => msg.id == messageId);
    } catch (e) {
      return null;
    }
  }

  Chat get chat => _chat;

  /// Disposes of resources used by the presenter (e.g., audio recorder, player).
  /// Deletes a chat and all its messages.
  Future<void> deleteChat(String chatId) async {
    try {
      await _chatRepository.deleteChat(chatId);
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
      final olderMessages = await _chatRepository.loadOlderMessages(_chat.id, _messages.length);
      
      if (olderMessages.isEmpty) {
        _hasMoreOlder = false;
      } else {
        // Decrypt messages if needed
        final decryptedOlder = olderMessages.map((message) {
          if (message.type == MessageType.text) {
            try {
              final decryptedContent = _encryptionService.decryptText(message.content);
              String? decryptedEditedContent;
              if (message.editedContent != null) {
                decryptedEditedContent = _encryptionService.decryptText(message.editedContent!);
              }
              return message.copyWith(
                content: decryptedContent,
                editedContent: decryptedEditedContent,
              );
            } catch (e) {
              return message.copyWith(content: 'Decryption Error');
            }
          }
          return message;
        }).toList();

        // Add to existing messages and update view
        _messages.addAll(decryptedOlder);
        _updateViewWithCombinedMessages();
      }
    } catch (e) {
      print('ChatPresenter: Error loading older messages: $e');
    } finally {
      _isLoadingOlder = false;
      _view.updateView();
    }
  }

  void dispose() {
    // Clear active chat ID for the current user
    if (currentUserId != null) {
      _userRepository.updateActiveChatId(currentUserId!, null);
    }
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    _otherUserStatusSubscription?.cancel(); // Cancel the status subscription
    _readTimer?.cancel();
  }

  /// Marks all delivered messages from the other user as read.
  void markMessagesAsRead() async {
    if (NotificationService.currentActiveChatId != _chat.id) return;
    if (currentUserId == null) return;
    final otherUserId = _chat.getOtherUserId(currentUserId!);
    final deliveredMessages = _messages.where((message) =>
        message.senderId == otherUserId &&
        (message.status == MessageStatus.delivered || message.status == MessageStatus.sent));

    if (deliveredMessages.isEmpty) return;

    final updates = <String, MessageStatus>{};
    for (var message in deliveredMessages) {
      updates[message.id] = MessageStatus.read;
    }
    
    try {
      await _chatRepository.updateMessagesStatusBatch(_chat.id, updates);
      // Update local state
      _messages = _messages.map((m) {
        if (updates.containsKey(m.id)) {
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
      print('ChatPresenter: Failed to mark messages as read: $e');
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
}
