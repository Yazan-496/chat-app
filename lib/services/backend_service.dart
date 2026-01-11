abstract class BackendService {
  Future<void> initialize();
  Future<String?> registerUser(String username, String password);
  Future<String?> loginUser(String username, String password);
  Future<void> updateDisplayName(String userId, String newDisplayName);
  Future<String?> uploadProfilePicture(String userId, String filePath);
  Future<String?> uploadVoiceMessage(String chatId, String filePath);
  // TODO: Add methods for chat, messages, user discovery, etc.
}
