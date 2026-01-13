import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_chat_app/data/chat_repository.dart';
import 'package:my_chat_app/model/chat.dart';
import 'package:my_chat_app/model/message.dart';
import 'package:my_chat_app/view/chat_view.dart';
import 'package:my_chat_app/services/media_service.dart';
import 'package:my_chat_app/services/encryption_service.dart';
import 'package:my_chat_app/services/local_storage_service.dart';
import 'package:my_chat_app/data/user_repository.dart'; // New import
import 'package:my_chat_app/model/user.dart' as model; // New import
import 'package:record/record.dart'; // Keep for recording state
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'package:my_chat_app/services/sound_service.dart';
import 'package:my_chat_app/services/notification_service.dart';

/// Presenter for the chat screen.
/// Handles all business logic related to a specific chat, including message sending,
/// receiving, media handling, and encryption.
class ChatPresenter {
  final ChatView _view;
  final ChatRepository _chatRepository;
  final MediaService _mediaService;
  final EncryptionService _encryptionService;
  final LocalStorageService _localStorageService = LocalStorageService();
  final UserRepository _userRepository; // New instance
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final Chat _chat;
  List<Message> _messages = [];
  Set<String> _seenMessageIds = {};

  Message? _selectedMessageForReply;
  Message? _selectedMessageForEdit;

  final AudioRecorder _audioRecorder = AudioRecorder(); // Correct instantiation
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentRecordingPath;
  bool _isRecording = false;
  Timer? _typingTimer;
  Timer? _readTimer;
  StreamSubscription? _otherUserStatusSubscription; // New subscription for other user status
  bool _otherUserInChat = false;
  bool _otherUserInChatPrev = false;

  ChatPresenter(this._view, this._chat)
      : _chatRepository = ChatRepository(),
        _mediaService = MediaService(),
        _encryptionService = EncryptionService(),
        _userRepository = UserRepository();

  String? get currentUserId => _firebaseAuth.currentUser?.uid;

  List<Message> get messages => _messages;
  Message? get selectedMessageForReply => _selectedMessageForReply;
  Message? get selectedMessageForEdit => _selectedMessageForEdit; // Corrected line
  bool get isRecording => _isRecording;
  bool _otherUserTyping = false;
  bool get otherUserTyping => _otherUserTyping;
  bool get otherUserInChat => _otherUserInChat;

  /// Loads messages for the current chat and sets up a real-time listener.
  void loadMessages() {
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
      _markIncomingMessagesAsDelivered(_messages, previousIds);
      final otherId = _chat.getOtherUserId(currentUserId!);
      final hasNewIncoming = _messages.any((m) => m.senderId == otherId && !previousIds.contains(m.id));
      if (NotificationService.currentActiveChatId == _chat.id && hasNewIncoming) {
        // Schedule read marking for new incoming while we are in chat
        scheduleReadMark();
      }
      _view.displayMessages(_messages);
      _view.updateView();
    });

    // Subscribe to other user's online status
    final otherUserId = _chat.getOtherUserId(currentUserId!);
    _otherUserStatusSubscription = _userRepository.streamUserStatus(otherUserId).listen((otherUser) {
      if (otherUser != null) {
        final wasInChat = _otherUserInChat;
        _chat.otherUserIsOnline = otherUser.isOnline;
        _chat.otherUserLastSeen = otherUser.lastSeen;
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
    _chatRepository.getChatDocStream(_chat.id).listen((doc) {
      try {
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null && data['typing'] is Map<String, dynamic>) {
          final typingMap = Map<String, dynamic>.from(data['typing']);
          final otherId = _chat.getOtherUserId(currentUserId!);
          final isTyping = typingMap[otherId] == true;
          _otherUserTyping = isTyping;
          if (NotificationService.currentActiveChatId == _chat.id) {
            if (isTyping) {
              SoundService.instance.startTypingLoop();
            } else {
              SoundService.instance.stopTypingLoop();
            }
          } else {
            SoundService.instance.stopTypingLoop();
          }
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

    SoundService.instance.playSent();
    final encryptedContent = _encryptionService.encryptText(content);

    final message = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      chatId: _chat.id,
      senderId: currentUserId!,
      receiverId: _chat.getOtherUserId(currentUserId!),
      type: MessageType.text,
      content: encryptedContent,
      timestamp: DateTime.now(),
      status: MessageStatus.sending, // Set initial status
      replyToMessageId: _selectedMessageForReply?.id,
    );
    // Introduce a delay to visually show "sending" state
    await Future.delayed(const Duration(seconds: 0));
    await _chatRepository.sendMessage(message);
    _selectedMessageForReply = null;
    _view.updateView();
  }

  /// Notify typing status. Sets typing=true and schedules a debounce to set
  /// typing=false after 2 seconds of inactivity.
  void notifyTyping(bool isTyping) {
    if (currentUserId == null) return;
    _chatRepository.setTypingStatus(_chat.id, currentUserId!, isTyping);
    _typingTimer?.cancel();
    if (isTyping) {
      _typingTimer = Timer(const Duration(seconds: 2), () {
        _chatRepository.setTypingStatus(_chat.id, currentUserId!, false);
      });
    }
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

  /// Stops recording and sends the voice message. Uploads to Firebase Storage via MediaService.
  Future<void> stopRecordingAndSend() async {
    try {
      final path = await _audioRecorder.stop();
      _isRecording = false;
      _view.updateView();

      if (path != null && currentUserId != null) {
        final storagePath = 'chat_media/${_chat.id}/voice/${DateTime.now().millisecondsSinceEpoch}.m4a';
        final mediaUrl = await _mediaService.uploadFile(path, storagePath);
        if (mediaUrl != null) {
          SoundService.instance.playSent();
          final message = Message(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            chatId: _chat.id,
            senderId: currentUserId!,
            receiverId: _chat.getOtherUserId(currentUserId!),
            type: MessageType.voice,
            content: mediaUrl,
            timestamp: DateTime.now(),
            replyToMessageId: _selectedMessageForReply?.id,
          );
          await _chatRepository.sendMessage(message);
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
          final message = Message(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            chatId: _chat.id,
            senderId: currentUserId!,
            receiverId: _chat.getOtherUserId(currentUserId!),
            type: MessageType.image,
            content: mediaUrl,
            timestamp: DateTime.now(),
            status: MessageStatus.sending, // Set initial status
            replyToMessageId: _selectedMessageForReply?.id,
          );
          // Introduce a delay to visually show "sending" state
          await Future.delayed(const Duration(seconds: 1));
          SoundService.instance.playSent();
          await _chatRepository.sendMessage(message);
          _selectedMessageForReply = null;
          _view.updateView();
        } else {
          _view.showMessage('Failed to upload image message.');
        }
      }
    } catch (e) {
      _view.showMessage('Failed to send image message: $e');
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

  void dispose() {
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    _otherUserStatusSubscription?.cancel(); // Cancel the status subscription
    _readTimer?.cancel();
    SoundService.instance.stopTypingLoop();
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
      flutterLocalNotificationsPlugin.cancel(_chat.id.hashCode);
      flutterLocalNotificationsPlugin.cancel(_chat.id.hashCode + 1);
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
