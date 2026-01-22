import 'package:my_chat_app/model/profile.dart';

abstract class UserDiscoveryView {
  void showLoading();
  void hideLoading();
  void showMessage(String message);
  void displaySearchResults(List<Profile> users);
  void updateView();
}
