import 'package:my_chat_app/model/message.dart';

abstract class ChatView {
  void showLoading();
  void hideLoading();
  void showMessage(String message);
  void displayMessages(List<Message> messages);
  void updateView();
}
