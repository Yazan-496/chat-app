import 'package:my_chat_app/model/chat.dart';

abstract class HomeView {
  void showLoading();
  void hideLoading();
  void showMessage(String message);
  void displayChats(List<Chat> chats);
  void updateView();
  void updateUserStatus(String userId, bool isOnline, DateTime? lastSeen);
  void navigateToLogin();
}
