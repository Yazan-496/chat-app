import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../model/message.dart';
import '../model/user.dart';
import '../model/chat.dart';

class DatabaseService {
  static late Isar isar;

  static Future<void> initialize() async {
    final dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open(
      [MessageSchema, UserSchema, ChatSchema],
      directory: dir.path,
    );
  }

  // Helper methods for Chats
  Future<void> saveChats(List<Chat> chats) async {
    await isar.writeTxn(() async {
      await isar.chats.putAll(chats);
    });
  }

  Future<List<Chat>> getAllChats() async {
    return await isar.chats.where().sortByLastMessageTimeDesc().findAll();
  }

  Future<Chat?> getChat(String chatId) async {
    return await isar.chats.filter().idEqualTo(chatId).findFirst();
  }

  Future<void> deleteChat(String chatId) async {
    await isar.writeTxn(() async {
      await isar.chats.filter().idEqualTo(chatId).deleteAll();
    });
  }

  // Helper methods for Messages
  Future<void> saveMessages(List<Message> messages) async {
    await isar.writeTxn(() async {
      await isar.messages.putAll(messages);
    });
  }

  Future<List<Message>> getMessages(String chatId, {int limit = 100, int offset = 0}) async {
    return await isar.messages
        .filter()
        .chatIdEqualTo(chatId)
        .sortByTimestampDesc()
        .offset(offset)
        .limit(limit)
        .findAll();
  }

  Future<Message?> getLastMessage(String chatId) async {
    return await isar.messages
        .filter()
        .chatIdEqualTo(chatId)
        .sortByTimestampDesc()
        .findFirst();
  }

  Future<Message?> getMessage(String messageId) async {
    return await isar.messages.filter().idEqualTo(messageId).findFirst();
  }

  Future<List<Message>> getMessagesByIds(List<String> messageIds) async {
    return await isar.messages
        .filter()
        .anyOf(messageIds, (q, String id) => q.idEqualTo(id))
        .findAll();
  }

  // Helper methods for Users
  Future<void> saveUser(User user) async {
    await isar.writeTxn(() async {
      await isar.users.put(user);
    });
  }

  Future<User?> getUser(String uid) async {
    return await isar.users.filter().uidEqualTo(uid).findFirst();
  }

  Future<void> saveUsers(List<User> users) async {
    await isar.writeTxn(() async {
      await isar.users.putAll(users);
    });
  }
}
