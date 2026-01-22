import 'package:my_chat_app/model/profile.dart';
import 'package:my_chat_app/model/user_relationship.dart';

abstract class ProfileView {
  void showLoading();
  void hideLoading();
  void showMessage(String message);
  void displayUserProfile(Profile user);
  void displayRelationship(UserRelationship? relationship); // New method
  void navigateBack();
  void navigateToSignIn();
  void updateView();
}
