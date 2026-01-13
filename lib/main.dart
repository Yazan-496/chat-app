import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_chat_app/view/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:my_chat_app/presenter/app_presenter.dart';
import 'package:my_chat_app/services/notification_service.dart';
import 'package:my_chat_app/utils/app_theme.dart';
import 'package:my_chat_app/view/app_view.dart';
import 'package:my_chat_app/view/auth_screen.dart';
import 'package:my_chat_app/services/presence_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:my_chat_app/l10n/app_localizations.dart';
import 'package:flutter/services.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Register background message handler - must be top-level function
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  
  // Initialize notification service
  await NotificationService().initialize();
  await NotificationService.ensureBubblePermission();
  
  runApp(const MainApp());
}

@pragma('vm:entry-point')
void overlayMain() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Material(
      child: Center(
        child: Text(
          'Chat Bubble',
          style: TextStyle(fontSize: 18),
        ),
      ),
    ),
  ));
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => MainAppState();
}

class MainAppState extends State<MainApp> with WidgetsBindingObserver implements AppView {
  late AppPresenter _presenter;
  ThemeModeType _themeMode = ThemeModeType.system; // Default to system theme
  Locale _locale = const Locale('en');
  final PresenceService _presenceService = PresenceService();
  String? _pendingChatId;
  StreamSubscription<User?>? _authStateSubscription;
  static const MethodChannel _bubbleChannel = MethodChannel('com.example.my_chat_app/bubbles');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _presenter = AppPresenter(this);
    _presenter.onInit();
    _setupBubbleIntentListener();

    // Listen to auth state changes to start/stop global listener
    _authStateSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        NotificationService().startGlobalMessageListener(user.uid);
      } else {
        NotificationService().stopGlobalMessageListener();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authStateSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (state == AppLifecycleState.resumed) {
      _presenceService.setUserOnline(user.uid);
      NotificationService().startGlobalMessageListener(user.uid);
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _presenceService.setUserOffline(user.uid);
      NotificationService().stopGlobalMessageListener();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'My Chat App',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _getThemeMode(_themeMode),
      locale: _locale,
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData) {
            return HomeScreen(initialChatId: _pendingChatId); // User is logged in
          } else {
            return const AuthScreen(); // User is not logged in
          }
        },
      ),
    );
  }

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
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

  void _setupBubbleIntentListener() async {
    try {
      final chatId = await _bubbleChannel.invokeMethod<String>('getLaunchChatId');
      if (chatId != null && chatId.isNotEmpty) {
        setState(() {
          _pendingChatId = chatId;
        });
      }
    } catch (_) {}
    _bubbleChannel.setMethodCallHandler((call) async {
      if (call.method == 'onLaunchChatId') {
        final chatId = (call.arguments as Map)['chatId'] as String?;
        if (chatId != null && chatId.isNotEmpty) {
          setState(() {
            _pendingChatId = chatId;
          });
        }
      }
    });
  }

  String? consumePendingChatId() {
    final id = _pendingChatId;
    _pendingChatId = null;
    return id;
  }
}

