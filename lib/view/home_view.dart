import 'package:my_chat_app/utils/app_theme.dart';
import 'package:my_chat_app/model/chat.dart';

abstract class HomeView {
  void showLoading();
  void hideLoading();
  void showMessage(String message);
  void displayChats(List<Chat> chats);
  void updateView();
}
