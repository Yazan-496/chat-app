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
import 'package:my_chat_app/view/auth_screen.dart';
import 'package:my_chat_app/services/presence_service.dart';

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
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header matching HomeScreen
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade900,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                children: [
                  const SizedBox(height: 16),
                  // Profile Section
                  Center(
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: _currentAvatarColor,
                              child: Text(
                                _supabase.auth.currentUser?.email?[0].toUpperCase() ?? 'U',
                                style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.blueAccent,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.black, width: 2),
                                ),
                                child: IconButton(
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.all(8),
                                  icon: const Icon(Icons.colorize, color: Colors.white, size: 20),
                                  onPressed: _showColorPicker,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _supabase.auth.currentUser?.email ?? 'User',
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),

                  _buildSettingItem(
                    title: 'Theme Mode',
                    subtitle: _selectedThemeMode.toString().split('.').last.toUpperCase(),
                    icon: Icons.brightness_6,
                    trailing: DropdownButton<ThemeModeType>(
                      value: _selectedThemeMode,
                      dropdownColor: Colors.grey.shade900,
                      underline: const SizedBox(),
                      onChanged: (ThemeModeType? newValue) {
                        if (newValue != null) {
                          _presenter.updateThemeMode(newValue);
                          widget.onThemeChanged(newValue);
                        }
                      },
                      items: ThemeModeType.values.map<DropdownMenuItem<ThemeModeType>>((ThemeModeType value) {
                        return DropdownMenuItem<ThemeModeType>(
                          value: value,
                          child: Text(value.toString().split('.').last.toUpperCase(), style: const TextStyle(color: Colors.white)),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSettingItem(
                    title: 'Language',
                    subtitle: _selectedLanguageCode == 'en' ? 'English' : 'العربية',
                    icon: Icons.language,
                    trailing: DropdownButton<String>(
                      value: _selectedLanguageCode,
                      dropdownColor: Colors.grey.shade900,
                      underline: const SizedBox(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedLanguageCode = newValue;
                          });
                          _localStorageService.saveLanguageCode(newValue);
                          final mainApp = context.findAncestorStateOfType<MainAppState>();
                          if (mainApp != null) {
                            mainApp.setLocale(Locale(newValue));
                          }
                        }
                      },
                      items: const [
                        DropdownMenuItem(value: 'en', child: Text('English', style: TextStyle(color: Colors.white))),
                        DropdownMenuItem(value: 'ar', child: Text('العربية', style: TextStyle(color: Colors.white))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSettingItem(
                    title: 'Notification Sound',
                    subtitle: _presenter.notificationSoundPath != null
                        ? _presenter.notificationSoundPath!.split('/').last
                        : 'Default',
                    icon: Icons.notifications_active,
                    onTap: _pickNotificationSound,
                    trailing: _presenter.notificationSoundPath != null
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () => _presenter.updateNotificationSound(null),
                          )
                        : const Icon(Icons.chevron_right, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  const Divider(color: Colors.grey, thickness: 0.5),
                  const SizedBox(height: 12),
                  _buildSettingItem(
                    title: 'Logout',
                    subtitle: 'Sign out of your account',
                    icon: Icons.logout,
                    iconColor: Colors.redAccent,
                    onTap: _showLogoutConfirmation,
                    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required String title,
    required String subtitle,
    required IconData icon,
    Widget? trailing,
    VoidCallback? onTap,
    Color? iconColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (iconColor ?? Colors.blueAccent).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor ?? Colors.blueAccent, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
        ),
        trailing: trailing,
      ),
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              final userId = _supabase.auth.currentUser?.id;
              if (userId != null) {
                final presenceService = PresenceService();
                await presenceService.setUserOffline(userId);
              }
              await _supabase.auth.signOut();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('Logout', style: TextStyle(color: Colors.redAccent)),
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
