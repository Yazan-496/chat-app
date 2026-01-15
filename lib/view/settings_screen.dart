import 'package:flutter/material.dart';
import 'package:my_chat_app/presenter/settings_presenter.dart';
import 'package:my_chat_app/utils/app_theme.dart';
import 'package:my_chat_app/main.dart';
import 'package:my_chat_app/view/settings_view.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_chat_app/services/local_storage_service.dart';
import 'package:flutter/services.dart';
import 'package:my_chat_app/notification_service.dart';
import 'package:my_chat_app/data/user_repository.dart';

class SettingsScreen extends StatefulWidget {
  final Function(ThemeModeType) onThemeChanged;

  const SettingsScreen({super.key, required this.onThemeChanged});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> implements SettingsView {
  late SettingsPresenter _presenter;
  final SupabaseClient _supabase = Supabase.instance.client;
  final LocalStorageService _localStorageService = LocalStorageService();
  final UserRepository _userRepository = UserRepository();
  ThemeModeType _selectedThemeMode = ThemeModeType.system;
  String _selectedLanguageCode = 'en';
  Color _currentAvatarColor = Colors.blue.shade300;

  @override
  void initState() {
    super.initState();
    _presenter = SettingsPresenter(this);
    _presenter.loadSettings();
    _loadAvatarColor();
    _loadLanguageCode();
  }

  Future<void> _loadLanguageCode() async {
    final languageCode = await _localStorageService.getLanguageCode();
    if (languageCode != null && mounted) {
      setState(() {
        _selectedLanguageCode = languageCode;
      });
      final mainApp = context.findAncestorStateOfType<MainAppState>();
      if (mainApp != null) {
        mainApp.setLocale(Locale(languageCode));
      }
    }
  }

  Future<void> _loadAvatarColor() async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      // First try to load from UserRepository (Supabase)
      final profile = await _userRepository.getUser(user.id);
      if (profile != null && profile.avatarColor != null) {
        if (mounted) {
          setState(() {
            _currentAvatarColor = Color(profile.avatarColor!);
          });
        }
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
        ],
      ),
    );
  }

  void _showColorPicker() {
    Color tempColor = _currentAvatarColor;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Pick a color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: tempColor,
              onColorChanged: (color) {
                setDialogState(() {
                  tempColor = color;
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
                final userId = _supabase.auth.currentUser?.id;
                if (userId != null) {
                  setState(() {
                    _currentAvatarColor = tempColor;
                  });
                  // Save to Supabase - ensure alpha is 255
                  final colorToSave = tempColor.withAlpha(255).value;
                  await _userRepository.updateAvatarColor(userId, colorToSave);
                  // Notify presenter to refresh any dependent views
                  _presenter.updateView(); 
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
