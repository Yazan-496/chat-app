import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_chat_app/view/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:my_chat_app/presenter/app_presenter.dart';
import 'package:my_chat_app/notification_service.dart';
import 'package:my_chat_app/utils/app_theme.dart';
import 'package:my_chat_app/view/app_view.dart';
import 'package:my_chat_app/view/auth_screen.dart';
import 'package:my_chat_app/services/presence_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:my_chat_app/l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:my_chat_app/supabase_client.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await SupabaseManager.initialize();
  
  // Initialize notification service
  await NotificationService.initNotifications();
  
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => MainAppState();
}

class MainAppState extends State<MainApp> with WidgetsBindingObserver implements AppView {
  late AppPresenter _presenter;
  ThemeModeType _themeMode = ThemeModeType.system;
  Locale _locale = const Locale('en');
  final PresenceService _presenceService = PresenceService();
  final SupabaseClient _supabase = SupabaseManager.client;
  String? _pendingChatId;
  StreamSubscription<AuthState>? _authStateSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _presenter = AppPresenter(this);
    _presenter.onInit();

    // Listen to auth state changes to start/stop global listener
    _authStateSubscription = _supabase.auth.onAuthStateChange.listen((data) async {
      final user = data.session?.user;
      if (user != null) {
        await NotificationService.startGlobalMessageListener(user.id);
        _presenceService.setUserOnline(user.id);
      } else {
        NotificationService.stopGlobalMessageListener();
        _presenceService.setUserOffline(_supabase.auth.currentUser?.id ?? '');
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
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    if (state == AppLifecycleState.resumed) {
      _presenceService.setUserOnline(user.id);
      NotificationService.startGlobalMessageListener(user.id);
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _presenceService.setUserOffline(user.id);
      // We don't stop the global listener here to allow it to run in background as long as possible
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
      home: StreamBuilder<AuthState>(
        stream: _supabase.auth.onAuthStateChange,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData && snapshot.data?.session != null) {
            return HomeScreen(initialChatId: _pendingChatId);
          } else {
            return const AuthScreen();
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

  String? consumePendingChatId() {
    final id = _pendingChatId;
    _pendingChatId = null;
    return id;
  }

  bool hasPendingChatId() {
    return _pendingChatId != null;
  }
}

