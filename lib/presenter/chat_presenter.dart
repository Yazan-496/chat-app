import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_chat_app/data/chat_repository.dart';
import 'package:my_chat_app/model/chat.dart';
import 'package:my_chat_app/model/message.dart';
import 'package:my_chat_app/view/chat_view.dart';
import 'package:my_chat_app/services/media_service.dart';
import 'package:my_chat_app/services/encryption_service.dart';
import 'package:record/record.dart'; // Keep for recording state
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

/// Presenter for the chat screen.
/// Handles all business logic related to a specific chat, including message sending,
/// receiving, media handling, and encryption.
class ChatPresenter {
  final ChatView _view;
  final ChatRepository _chatRepository;
  final MediaService _mediaService;
  final EncryptionService _encryptionService;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final Chat _chat;
  List<Message> _messages = [];

  Message? _selectedMessageForReply;
  Message? _selectedMessageForEdit;

  final AudioRecorder _audioRecorder = AudioRecorder(); // Correct instantiation
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentRecordingPath;
  bool _isRecording = false;

  ChatPresenter(this._view, this._chat)
      : _chatRepository = ChatRepository(),
        _mediaService = MediaService(),
        _encryptionService = EncryptionService();

  String? get currentUserId => _firebaseAuth.currentUser?.uid;

  List<Message> get messages => _messages;
  Message? get selectedMessageForReply => _selectedMessageForReply;
  Message? get selectedMessageForEdit => _selectedMessageForEdit; // Corrected line
  bool get isRecording => _isRecording;

  /// Loads messages for the current chat and sets up a real-time listener.
  void loadMessages() {
    _chatRepository.getChatMessages(_chat.id).listen((messages) {
      _messages = messages.map<Message>((message) {
        // Handle incoming messages status updates
        if (message.senderId == _chat.getOtherUserId(currentUserId!)) {
          if (message.status == MessageStatus.sending || message.status == MessageStatus.sent) {
            _chatRepository.updateMessageStatus(_chat.id, message.id, MessageStatus.delivered);
            // Update the local message object to reflect the delivered status immediately
            message = message.copyWith(status: MessageStatus.delivered);
          } else if (message.status == MessageStatus.delivered) {
            _chatRepository.updateMessageStatus(_chat.id, message.id, MessageStatus.read);
            // Update the local message object to reflect the read status immediately
            message = message.copyWith(status: MessageStatus.read);
          }
        }

        // Decrypt text messages before displaying
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
            print('ChatPresenter: Decryption failed for message ID: ${message.id}. Encrypted content: ${message.content}. Error: $e');
            return message.copyWith(content: 'Decryption Error: Invalid or corrupt message content.');
          }
        }
        return message;
      }).toList();
      _view.displayMessages(_messages);
      _view.updateView();
    });
  }

  /// Sends a text message. Encrypts the content before sending.
  Future<void> sendTextMessage(String content) async {
    if (currentUserId == null) {
      _view.showMessage('User not authenticated.');
      return;
    }
    if (content.trim().isEmpty) {
      return;
    }

    final encryptedContent = _encryptionService.encryptText(content.trim());

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
    final encryptedContent = _encryptionService.encryptText(newContent.trim());
    await _chatRepository.editTextMessage(_chat.id, _selectedMessageForEdit!.id, encryptedContent);
    _selectedMessageForEdit = null;
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
  }
}
