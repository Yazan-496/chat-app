import 'package:my_chat_app/model/user.dart';
import 'package:my_chat_app/model/relationship.dart';

abstract class ProfileView {
  void showLoading();
  void hideLoading();
  void showMessage(String message);
  void displayUserProfile(User user);
  void displayRelationship(Relationship? relationship); // New method
  void navigateBack();
  void updateView();
}
