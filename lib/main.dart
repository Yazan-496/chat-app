import 'dart:convert';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_chat_app/view/home_screen.dart';
import 'package:my_chat_app/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:my_chat_app/data/chat_repository.dart';
import 'package:my_chat_app/data/user_repository.dart';
import 'package:my_chat_app/model/private_chat.dart';
import 'package:my_chat_app/model/profile.dart';

import 'package:my_chat_app/services/local_storage_service.dart';

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
  
  await NotificationService.initNotifications();
  await NotificationService.ensureAndroidNotificationsPermission();
  await initializeBackgroundService();
  await NotificationService.initOneSignal();
  final currentUser = SupabaseManager.client.auth.currentUser;
  if (currentUser != null) {
    NotificationService.loginToOneSignal(currentUser.id);
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
  static const MethodChannel _bubbleChannel =
      MethodChannel('com.example.my_chat_app/bubbles');
  String? _pendingChatId;
  StreamSubscription<AuthState>? _authStateSubscription;
  StreamSubscription<String>? _notificationNavSubscription;
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _presenter = AppPresenter(this);
    _presenter.onInit();

    _bubbleChannel.setMethodCallHandler((call) async {
      final args = call.arguments;
      String? chatId;
      if (args is Map) {
        final raw = args['chat_id'] ?? args['chatid'];
        if (raw is String) chatId = raw;
      } else if (args is String) {
        chatId = args;
      }
      if (call.method == 'bubbleChat') {
        if (chatId != null && chatId.isNotEmpty) {
          // If we receive bubbleChat, it means we are launched inside a bubble.
          // We should prioritize this chatId and update the state.
          if (mounted) {
            setState(() {
              _pendingChatId = chatId;
              _showSplash = false;
            });
          }
        }
      } else if (call.method == 'onLaunchChatId') {
        if (chatId != null && chatId.isNotEmpty && mounted) {
          setState(() {
            _pendingChatId = chatId;
            _showSplash = false;
          });
        }
      }
      return null;
    });

    _checkBubbleLaunch();

    final initialPending = NotificationService.consumePendingNavigationChatId();
    if (initialPending != null) {
      _pendingChatId = initialPending;
      _showSplash = false;
    }
    _notificationNavSubscription = NotificationService.navigationStream.listen((chatId) {
      if (!mounted) return;
      setState(() {
        _pendingChatId = chatId;
        _showSplash = false;
      });
    });

    // Proactively set user online if already logged in
    final currentUser = _supabase.auth.currentUser;
    if (currentUser != null) {
      _presenceService.setUserOnline(currentUser.id);
      NotificationService.loginToOneSignal(currentUser.id);
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
      if (data.session != null) {
        // Persist session for background service
        await LocalStorageService().saveSession(jsonEncode(data.session!.toJson()));
      }
      
      if (user != null) {
        _presenceService.setUserOnline(user.id);
        NotificationService.loginToOneSignal(user.id);
      } else {
        _presenceService.setUserOffline(_supabase.auth.currentUser?.id ?? '');
        NotificationService.logoutFromOneSignal();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authStateSubscription?.cancel();
    _notificationNavSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    if (state == AppLifecycleState.resumed) {
      _presenceService.setUserOnline(user.id);
      
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive || state == AppLifecycleState.detached) {
      if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
        _presenceService.setUserOffline(user.id);
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
        home: _buildRoot(),
      );

  }

  Widget _buildRoot() {
    return StreamBuilder<AuthState>(
      stream: _supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final currentUser = _supabase.auth.currentUser;
        final effectiveChatId = _pendingChatId;
        final canBypassWait = currentUser != null && effectiveChatId != null;
        if (_showSplash || (snapshot.connectionState == ConnectionState.waiting && !canBypassWait)) {
          return SplashScreen(message: 'LoZo');
        }
        if ((snapshot.hasData && snapshot.data?.session != null) || currentUser != null) {
          return HomeScreen(initialChatId: effectiveChatId);
        } else {
          return const AuthScreen();
        }
      },
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

  Future<void> _checkBubbleLaunch() async {
    try {
      final isBubble = await _bubbleChannel.invokeMethod<bool>('isBubble') ?? false;
      if (isBubble) {
        final chatId = await _bubbleChannel.invokeMethod<String>('getLaunchChatId');
        if (chatId != null && chatId.isNotEmpty && mounted) {
           setState(() {
             _pendingChatId = chatId;
             _showSplash = false;
           });
        }
      }
    } catch (_) {
    }
  }
}


