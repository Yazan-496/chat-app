import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_chat_app/view/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:my_chat_app/presenter/app_presenter.dart';
import 'package:my_chat_app/notification_service.dart';
import 'package:my_chat_app/utils/app_theme.dart';
import 'package:my_chat_app/view/app_view.dart';
import 'package:my_chat_app/view/auth_screen.dart';
import 'package:my_chat_app/view/splash_screen.dart';
import 'package:my_chat_app/services/presence_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:my_chat_app/l10n/app_localizations.dart';
import 'package:my_chat_app/services/database_service.dart';
import 'package:my_chat_app/supabase_client.dart';
import 'package:my_chat_app/services/background_service.dart' as shim;
import 'package:flutter_background_service/flutter_background_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: shim.onStart,
      autoStart: true,
      isForegroundMode: true, // Required to keep service alive
      notificationChannelId: 'my_chat_app_background',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: shim.onStart,
      onBackground: (ServiceInstance service) {
          return true;
      }, 
    ),
  );
  
  await service.startService();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final void Function(ServiceInstance) _ = shim.onStart;

  await SupabaseManager.initialize();
  await DatabaseService.initialize();
  
  // Initialize notification service
  await NotificationService.initNotifications();
  final notificationsGranted =
      await NotificationService.ensureAndroidNotificationsPermission();
  
  // Initialize background service
  if (notificationsGranted) {
    await initializeBackgroundService();
  }
  
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
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _presenter = AppPresenter(this);
    _presenter.onInit();

    // Proactively set user online if already logged in
    final currentUser = _supabase.auth.currentUser;
    if (currentUser != null) {
      _presenceService.setUserOnline(currentUser.id);
      NotificationService.startGlobalMessageListener(currentUser.id);
    }

    // Ensure splash screen shows for at least 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showSplash = false;
        });
      }
    });

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
      
      // Tell background service we are in foreground, so it can stop listening
      FlutterBackgroundService().invoke('app_in_foreground');
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive || state == AppLifecycleState.detached) {
      if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
        _presenceService.setUserOffline(user.id);
        NotificationService.stopGlobalMessageListener();
        
        // Tell background service we are in background, so it can start listening
        FlutterBackgroundService().invoke('app_in_background');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'LoZo',
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
          if (_showSplash || snapshot.connectionState == ConnectionState.waiting) {
            return SplashScreen(message: 'LoZo');
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

