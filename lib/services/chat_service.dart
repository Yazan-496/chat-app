import 'package:uuid/uuid.dart';
import 'package:my_chat_app/data/chat_repository.dart';
import 'package:my_chat_app/data/message_repository.dart';
import 'package:my_chat_app/model/message.dart';
import 'package:my_chat_app/services/database_service.dart';

class ChatService {
  final ChatRepository _chatRepository;
  final MessageRepository _messageRepository;
  final Uuid _uuid;

  ChatService({
    ChatRepository? chatRepository,
    MessageRepository? messageRepository,
    Uuid? uuid,
  })  : _chatRepository = chatRepository ?? ChatRepository(),
        _messageRepository = messageRepository ?? MessageRepository(),
        _uuid = uuid ?? const Uuid();

  Stream<List<Message>> streamMessages(String chatId) {
    return _messageRepository.streamByChat(chatId);
  }

  Future<List<Message>> fetchMessages(
    String chatId, {
    int limit = 50,
    DateTime? before,
  }) {
    return _messageRepository.fetchByChat(
      chatId,
      limit: limit,
      before: before,
    );
  }

  Future<Message> sendMessage({
    required String chatId,
    required String senderId,
    String? content,
    MessageType type = MessageType.text,
    String? replyToMessageId,
  }) async {
    final now = DateTime.now().toUtc();
    final message = Message(
      id: _uuid.v4(),
      chatId: chatId,
      senderId: senderId,
      content: content,
      type: type,
      replyToMessageId: replyToMessageId,
      createdAt: now,
      updatedAt: now,
    );
    await DatabaseService.saveMessages([message], pendingSync: true);
    final changeId =
        await DatabaseService.enqueueMessageChange(message, action: 'create');
    try {
      final created = await _messageRepository.create(message);
      await DatabaseService.saveMessages([created]);
      await DatabaseService.removePendingChange(changeId);
      return created;
    } catch (_) {
      return message;
    }
  }

  Future<void> markDelivered(String chatId, String messageId) {
    return _chatRepository.markMessageDelivered(chatId, messageId);
  }

  Future<void> markRead(String chatId) {
    return _chatRepository.markChatRead(chatId);
  }
}
