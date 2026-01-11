import 'package:flutter/material.dart';
import 'package:my_chat_app/presenter/settings_presenter.dart';
import 'package:my_chat_app/utils/app_theme.dart';
import 'package:my_chat_app/view/settings_view.dart';
import 'package:file_picker/file_picker.dart'; // New import

class SettingsScreen extends StatefulWidget {
  final Function(ThemeModeType) onThemeChanged;

  const SettingsScreen({super.key, required this.onThemeChanged});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> implements SettingsView {
  late SettingsPresenter _presenter;
  ThemeModeType _selectedThemeMode = ThemeModeType.system;
  String? _selectedNotificationSoundPath; // New state variable

  @override
  void initState() {
    super.initState();
    _presenter = SettingsPresenter(this);
    _presenter.loadSettings();
  }

  @override
  void updateThemeMode(ThemeModeType themeMode) {
    setState(() {
      _selectedThemeMode = themeMode;
    });
  }

  @override
  void updateNotificationSoundPath(String? path) {
    setState(() {
      _selectedNotificationSoundPath = path;
    });
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
        ],
      ),
    );
  }
}
