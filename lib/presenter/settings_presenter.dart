import 'package:my_chat_app/utils/app_theme.dart';
import 'package:my_chat_app/view/settings_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPresenter {
  final SettingsView _view;
  ThemeModeType _currentThemeMode = ThemeModeType.system; // Default
  String? _notificationSoundPath; // Path to custom notification sound

  SettingsPresenter(this._view);

  ThemeModeType get currentThemeMode => _currentThemeMode;
  String? get notificationSoundPath => _notificationSoundPath;

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeIndex = prefs.getInt('themeMode') ?? ThemeModeType.system.index;
    _currentThemeMode = ThemeModeType.values[themeModeIndex];
    _notificationSoundPath = prefs.getString('notificationSoundPath');

    _view.updateThemeMode(_currentThemeMode);
    _view.updateView(); // To update the notification sound display
  }

  Future<void> updateThemeMode(ThemeModeType newThemeMode) async {
    _currentThemeMode = newThemeMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', newThemeMode.index);
    _view.updateThemeMode(newThemeMode);
  }

  Future<void> updateNotificationSound(String? path) async {
    _notificationSoundPath = path;
    final prefs = await SharedPreferences.getInstance();
    if (path == null) {
      await prefs.remove('notificationSoundPath');
    } else {
      await prefs.setString('notificationSoundPath', path);
    }
    _view.updateView();
  }

  void updateView() {
    _view.updateView();
  }
}
