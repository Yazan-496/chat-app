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
import 'package:system_alert_window/system_alert_window.dart';

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
    home: BubbleOverlay(),
  ));
}

class BubbleOverlay extends StatefulWidget {
  const BubbleOverlay({super.key});

  @override
  State<BubbleOverlay> createState() => _BubbleOverlayState();
}

class _BubbleOverlayState extends State<BubbleOverlay> {
  String _title = 'New Message';
  String _body = 'Tap to open chat';
  String? _chatId;
  String? _profilePicUrl;

  @override
  void initState() {
    super.initState();
    SystemAlertWindow.overlayListener.listen((event) {
      if (event is Map) {
        setState(() {
          _title = event['title'] ?? _title;
          _body = event['body'] ?? _body;
          _chatId = event['chatId'];
          _profilePicUrl = event['profilePicUrl'];
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
            border: Border.all(color: Colors.blueAccent.withOpacity(0.5), width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.blueAccent,
                    backgroundImage: _profilePicUrl != null && _profilePicUrl!.isNotEmpty
                        ? NetworkImage(_profilePicUrl!)
                        : null,
                    child: _profilePicUrl == null || _profilePicUrl!.isEmpty
                        ? const Icon(Icons.person, color: Colors.white, size: 24)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _body,
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                    onPressed: () => SystemAlertWindow.closeSystemWindow(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_chatId != null) {
                      // We can't navigate directly from here, so we tell the main isolate
                      // However, SystemAlertWindow 2.0.7 doesn't have a direct way back
                      // So we use the MethodChannel if possible, or just close and let user tap notification
                      SystemAlertWindow.closeSystemWindow();
                    } else {
                      SystemAlertWindow.closeSystemWindow();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleAtMost(20),
                  ),
                  child: const Text('Open Chat'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper for RoundedRectangleBorder
class RoundedRectangleAtMost extends RoundedRectangleBorder {
  RoundedRectangleAtMost(double radius) : super(borderRadius: BorderRadius.circular(radius));
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

  bool hasPendingChatId() {
    return _pendingChatId != null;
  }
}

