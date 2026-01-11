import 'package:my_chat_app/utils/app_theme.dart';

abstract class SettingsView {
  void updateThemeMode(ThemeModeType themeMode);
  void updateNotificationSoundPath(String? path);
  void showMessage(String message);
  void updateView();
}
