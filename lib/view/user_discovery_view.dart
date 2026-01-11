import 'package:my_chat_app/model/user.dart';

abstract class UserDiscoveryView {
  void showLoading();
  void hideLoading();
  void showMessage(String message);
  void displaySearchResults(List<User> users);
  void updateView();
}
