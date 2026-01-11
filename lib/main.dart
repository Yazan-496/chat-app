import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_chat_app/view/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:my_chat_app/presenter/app_presenter.dart';
import 'package:my_chat_app/services/notification_service.dart'; // New import
import 'package:my_chat_app/utils/app_theme.dart'; // New import
import 'package:my_chat_app/view/app_view.dart';
import 'package:my_chat_app/view/auth_screen.dart'; // New import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService().initialize(); // Initialize NotificationService
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => MainAppState();
}

class MainAppState extends State<MainApp> implements AppView {
  late AppPresenter _presenter;
  ThemeModeType _themeMode = ThemeModeType.system; // Default to system theme

  @override
  void initState() {
    super.initState();
    _presenter = AppPresenter(this);
    _presenter.onInit();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Chat App',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _getThemeMode(_themeMode),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData) {
            return const HomeScreen(); // User is logged in
          } else {
            return const AuthScreen(); // User is not logged in
          }
        },
      ),
    );
  }

  @override
  void updateView() {
    setState(() {});
  }

  ThemeMode _getThemeMode(ThemeModeType type) {
    switch (type) {
      case ThemeModeType.system: return ThemeMode.system;
      case ThemeModeType.light: return ThemeMode.light;
      case ThemeModeType.dark: return ThemeMode.dark;
    }
  }

  void setThemeMode(ThemeModeType themeMode) {
    setState(() {
      _themeMode = themeMode;
    });
  }
}

