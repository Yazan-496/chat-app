import 'package:my_chat_app/model/user.dart';

abstract class ProfileView {
  void showLoading();
  void hideLoading();
  void showMessage(String message);
  void displayUserProfile(User user);
  void navigateBack();
  void updateView();
}
