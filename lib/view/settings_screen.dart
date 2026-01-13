import 'package:flutter/material.dart';
import 'package:my_chat_app/presenter/settings_presenter.dart';
import 'package:my_chat_app/utils/app_theme.dart';
import 'package:my_chat_app/main.dart';
import 'package:my_chat_app/view/settings_view.dart';
import 'package:file_picker/file_picker.dart'; // New import
import 'package:flutter_colorpicker/flutter_colorpicker.dart'; // New import
import 'package:firebase_auth/firebase_auth.dart'; // New import
import 'package:my_chat_app/services/local_storage_service.dart'; // New import
import 'package:flutter/services.dart';
import 'package:my_chat_app/services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  final Function(ThemeModeType) onThemeChanged;

  const SettingsScreen({super.key, required this.onThemeChanged});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> implements SettingsView {
  late SettingsPresenter _presenter;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance; // New instance
  final LocalStorageService _localStorageService = LocalStorageService(); // New instance
  ThemeModeType _selectedThemeMode = ThemeModeType.system;
  String _selectedLanguageCode = 'en';
  Color _currentAvatarColor = Colors.blue.shade300; // Default avatar color
  String? _fcmToken;

  @override
  void initState() {
    super.initState();
    _presenter = SettingsPresenter(this);
    _presenter.loadSettings();
    _loadAvatarColor();
    _loadLanguageCode();
    NotificationService().getToken().then((token) {
      if (mounted) {
        setState(() {
          _fcmToken = token;
        });
      }
      if (token != null) {
        debugPrint('FCM Token: $token');
      }
    });
  }

  Future<void> _loadLanguageCode() async {
    final languageCode = await _localStorageService.getLanguageCode();
    if (languageCode != null && mounted) {
      setState(() {
        _selectedLanguageCode = languageCode;
      });
      // Find MainAppState and set locale
      final mainApp = context.findAncestorStateOfType<MainAppState>();
      if (mainApp != null) {
        mainApp.setLocale(Locale(languageCode));
      }
    }
  }

  Future<void> _loadAvatarColor() async {
    final userId = _firebaseAuth.currentUser?.uid;
    if (userId != null) {
      final storedColor = await _localStorageService.getAvatarColor(userId);
      if (storedColor != null) {
        setState(() {
          _currentAvatarColor = Color(storedColor);
        });
      }
    }
  }

  @override
  void updateThemeMode(ThemeModeType themeMode) {
    setState(() {
      _selectedThemeMode = themeMode;
    });
  }

  @override
  void updateNotificationSoundPath(String? path) {
    // The presenter exposes the current notificationSoundPath; just refresh the view
    setState(() {});
  }

  @override
  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  void updateView() {
    setState(() {});
  }

  Future<void> _pickNotificationSound() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      _presenter.updateNotificationSound(result.files.single.path);
    } else {
      // User canceled the picker or no file selected
      _presenter.updateNotificationSound(null); // Reset to default
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Theme Mode'),
            trailing: DropdownButton<ThemeModeType>(
              value: _selectedThemeMode,
              onChanged: (ThemeModeType? newValue) {
                if (newValue != null) {
                  _presenter.updateThemeMode(newValue);
                  widget.onThemeChanged(newValue);
                }
              },
              items: ThemeModeType.values.map<DropdownMenuItem<ThemeModeType>>((ThemeModeType value) {
                return DropdownMenuItem<ThemeModeType>(
                  value: value,
                  child: Text(value.toString().split('.').last.toUpperCase()),
                );
              }).toList(),
            ),
          ),
          ListTile(
            title: const Text('Language'),
            trailing: DropdownButton<String>(
              value: _selectedLanguageCode,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedLanguageCode = newValue;
                  });
                  // Save language preference
                  _localStorageService.saveLanguageCode(newValue);
                  // Find MainAppState and set locale
                  final mainApp = context.findAncestorStateOfType<MainAppState>();
                  if (mainApp != null) {
                    mainApp.setLocale(Locale(newValue));
                  }
                }
              },
              items: const [
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'ar', child: Text('العربية')),
              ],
            ),
          ),
          ListTile(
            title: const Text('Notification Sound'),
            subtitle: Text(
              _presenter.notificationSoundPath != null
                  ? _presenter.notificationSoundPath!.split('/').last
                  : 'Default',
            ),
            onTap: _pickNotificationSound,
            trailing: _presenter.notificationSoundPath != null
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => _presenter.updateNotificationSound(null),
                  )
                : null,
          ),
          ListTile(
            title: const Text('Avatar Background Color'),
            trailing: GestureDetector(
              onTap: _showColorPicker,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: _currentAvatarColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade400),
                ),
              ),
            ),
          ),
          ListTile(
            title: const Text('FCM Token'),
            subtitle: Text(
              _fcmToken ?? 'Fetching…',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: IconButton(
              icon: const Icon(Icons.copy),
              onPressed: _fcmToken == null
                  ? null
                  : () async {
                      await Clipboard.setData(ClipboardData(text: _fcmToken!));
                      showMessage('FCM token copied to clipboard');
                    },
            ),
          ),
        ],
      ),
    );
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick a color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: _currentAvatarColor,
            onColorChanged: (color) {
              setState(() {
                _currentAvatarColor = color;
              });
            },
            enableAlpha: false,
            labelTypes: const [],
            pickerAreaHeightPercent: 0.8,
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Got it'),
            onPressed: () async {
              Navigator.of(context).pop();
              final userId = _firebaseAuth.currentUser?.uid;
              if (userId != null) {
                await _localStorageService.saveAvatarColor(userId, _currentAvatarColor.value);
                _presenter.updateView(); // Notify presenter to refresh any dependent views
              }
            },
          ),
        ],
      ),
    );
  }
}
