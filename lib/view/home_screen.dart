import 'dart:async';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:my_chat_app/main.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_chat_app/model/chat.dart';
import 'package:my_chat_app/model/message.dart';
import 'package:my_chat_app/model/relationship.dart';
import 'package:my_chat_app/services/encryption_service.dart';
import 'package:my_chat_app/services/local_storage_service.dart';
import 'package:my_chat_app/presenter/home_presenter.dart';
import 'package:my_chat_app/chat_screen.dart';
import 'package:my_chat_app/view/home_view.dart';
import 'package:my_chat_app/view/profile_screen.dart';
import 'package:my_chat_app/view/settings_screen.dart';
import 'package:my_chat_app/view/user_discovery_screen.dart';
import 'package:my_chat_app/view/auth_screen.dart';
import 'package:my_chat_app/view/splash_screen.dart';
import 'package:my_chat_app/presenter/user_discovery_presenter.dart';
import 'package:my_chat_app/view/user_discovery_view.dart';
import 'package:my_chat_app/view/relationship_selection_dialog.dart';
import 'package:my_chat_app/notification_service.dart';
import 'package:my_chat_app/services/bubble_service.dart';
import 'package:my_chat_app/services/presence_service.dart';
import 'package:my_chat_app/data/user_repository.dart';
import 'package:my_chat_app/model/user.dart' as app_user;
import 'package:flutter/services.dart';
import 'package:my_chat_app/utils/toast_utils.dart';

class HomeScreen extends StatefulWidget {
  final String? initialChatId;
  const HomeScreen({super.key, this.initialChatId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver implements HomeView, UserDiscoveryView {
  HomePresenter? _presenter;
  UserDiscoveryPresenter? _discoveryPresenter;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final SupabaseClient _supabase = Supabase.instance.client;
  final EncryptionService _encryptionService = EncryptionService();
  final LocalStorageService _localStorageService = LocalStorageService();
  List<Chat> _chats = [];
  List<app_user.User> _discoveredUsers = [];
  bool _isLoading = false;
  bool _isSearching = false;
  bool _isDiscoveryLoading = false;
  app_user.User? _currentUserProfile;
  StreamSubscription<String>? _navigationSubscription;
  StreamSubscription<String>? _bubbleNavigationSubscription;
  RealtimeChannel? _statusChannel;
  String? _initialChatId;
  Timer? _statusUpdateTimer;
  Timer? _connectionDebounceTimer;
  bool _isConnected = true;
  bool _showRestoredMessage = false;
  Timer? _restoredMessageTimer;

  @override
  void initState() {
    super.initState();
    _discoveryPresenter = UserDiscoveryPresenter(this);
    _presenter = HomePresenter(this);
    _initialChatId = widget.initialChatId;
    WidgetsBinding.instance.addObserver(this);
    _presenter?.loadChats();
    _loadCurrentUserProfile();
    _checkNotificationLaunch();
    
    // Listen to Supabase connection status using a channel
    _statusChannel = _supabase.channel('home_conn_tracker').subscribe((status, error) {
      if (mounted) {
        final newConnected = status == RealtimeSubscribeStatus.subscribed;
        
        if (newConnected) {
          _connectionDebounceTimer?.cancel();
          if (!_isConnected) {
            // Connection restored
            setState(() {
              _isConnected = true;
              _showRestoredMessage = true;
            });
            _restoredMessageTimer?.cancel();
            _restoredMessageTimer = Timer(const Duration(seconds: 3), () {
              if (mounted) {
                setState(() => _showRestoredMessage = false);
              }
            });
          }
        } else {
          // Debounce connection loss to avoid flickering on minor blips
          _connectionDebounceTimer?.cancel();
          _connectionDebounceTimer = Timer(const Duration(seconds: 10), () {
            if (mounted) {
              setState(() {
                _isConnected = false;
                _showRestoredMessage = false;
              });
            }
          });
        }
      }
    });

    // Listen for notification taps while the app is in foreground
    _navigationSubscription = NotificationService.navigationStream.listen((chatId) {
      NotificationService.setPendingNavigationChatId(chatId);
      _checkAndNavigate();
    });

    // Listen for bubble taps while the app is in foreground
    _bubbleNavigationSubscription = BubbleService.navigationStream.listen((chatId) {
      NotificationService.setPendingNavigationChatId(chatId);
      _checkAndNavigate();
    });

    // Periodic timer to refresh "last seen" labels (e.g., from "1s ago" to "2s ago")
    _statusUpdateTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        setState(() {
          // Just trigger rebuild to update relative time strings
        });
      }
    });
  }

  @override
  void dispose() {
    _navigationSubscription?.cancel();
    _bubbleNavigationSubscription?.cancel();
    if (_statusChannel != null) {
      _supabase.removeChannel(_statusChannel!);
    }
    _statusUpdateTimer?.cancel();
    _restoredMessageTimer?.cancel();
    _connectionDebounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Shared View implementation
  @override
  void showLoading() {
    setState(() {
      if (_isSearching) {
        _isDiscoveryLoading = true;
      } else {
        _isLoading = true;
      }
    });
  }

  @override
  void hideLoading() {
    setState(() {
      _isDiscoveryLoading = false;
      _isLoading = false;
    });
  }

  @override
  void showMessage(String message) {
    if (mounted) {
      ToastUtils.showCustomToast(context, message);
    }
  }

  @override
  void displaySearchResults(List<app_user.User> users) {
    setState(() {
      _discoveredUsers = users;
    });
  }

  @override
  void updateView() {
    if (mounted) setState(() {});
  }

  @override
  void updateUserStatus(String userId, bool isOnline, DateTime? lastSeen) {
    if (mounted) {
      setState(() {
        for (int i = 0; i < _chats.length; i++) {
          if (_chats[i].participantIds.contains(userId)) {
            _chats[i] = _chats[i].copyWith(
              isOnline: isOnline,
              lastSeen: lastSeen,
            );
          }
        }
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Check for pending navigation when app comes back to foreground
      _checkAndNavigate();
    }
  }

  Future<void> _loadCurrentUserProfile() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId != null) {
      final userRepository = UserRepository();
      final profile = await userRepository.getUser(userId);
      if (mounted) {
        setState(() {
          _currentUserProfile = profile;
        });
      }
    }
  }

  Future<void> _checkNotificationLaunch() async {
    // 1. Check local notifications launch
    final details = await NotificationService.flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
    if (details != null && details.didNotificationLaunchApp && details.notificationResponse?.payload != null) {
      try {
        final payload = jsonDecode(details.notificationResponse!.payload!);
        final chatId = (payload['chat_id'] ?? payload['chatid']) as String?;
        if (chatId != null) {
          NotificationService.setPendingNavigationChatId(chatId);
          _checkAndNavigate();
        }
      } catch (e) {
        print('Error checking notification launch: $e');
      }
    }

    // 2. Check bubble launch (via native MethodChannel)
    try {
      const platform = MethodChannel('com.example.my_chat_app/bubbles');
      final String? chatId = await platform.invokeMethod('getLaunchChatId');
      if (chatId != null && chatId.isNotEmpty) {
        NotificationService.setPendingNavigationChatId(chatId);
        _checkAndNavigate();
      }
    } catch (_) {}
  }

  @override
  void displayChats(List<Chat> chats) {
    setState(() {
      _chats = chats;
    });
    _checkAndNavigate();
  }

  Future<void> _checkAndNavigate() async {
    if (!mounted) return;

    final mainApp = context.findAncestorStateOfType<MainAppState>();
    final pendingId = mainApp?.consumePendingChatId() ?? 
                     _consumeInitialChatId() ?? 
                     NotificationService.consumePendingNavigationChatId();
    
    if (pendingId == null) return;

    debugPrint('HomeScreen: Found pending chatId to navigate: $pendingId');
    
    Chat? target;
    for (final c in _chats) {
      if (c.id == pendingId) {
        target = c;
        break;
      }
    }

    if (target != null) {
      _navigateToChat(target);
    } else {
      debugPrint('HomeScreen: Target chat $pendingId not found in loaded chats. Fetching directly.');
      showLoading();
      final fetchedChat = await _presenter?.getChat(pendingId);
      hideLoading();
      
      if (fetchedChat != null && mounted) {
        _navigateToChat(fetchedChat);
      } else {
        debugPrint('HomeScreen: Error - Could not fetch chat $pendingId');
      }
    }
  }

  void _navigateToChat(Chat chat) {
    debugPrint('HomeScreen: Navigating to chat: ${chat.id}');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ChatScreen(chat: chat),
        ),
      );
    });
  }

  bool _isNavigationPending() {
    final mainApp = context.findAncestorStateOfType<MainAppState>();
    return mainApp?.hasPendingChatId() == true || 
           _initialChatId != null || 
           NotificationService.hasPendingNavigationChatId();
  }

  String? _consumeInitialChatId() {
    final id = _initialChatId;
    _initialChatId = null;
    return id;
  }

  @override
  void navigateToLogin() {
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  Future<void> _refreshConnectionStatus() async {
    // 1. Check current realtime connection status
    final isActuallyConnected = _supabase.realtime.isConnected;
    
    if (mounted) {
      setState(() {
        _isConnected = isActuallyConnected;
        if (isActuallyConnected && !_isConnected) {
          _showRestoredMessage = true;
          _restoredMessageTimer?.cancel();
          _restoredMessageTimer = Timer(const Duration(seconds: 3), () {
            if (mounted) setState(() => _showRestoredMessage = false);
          });
        }
      });
    }

    // 2. Force reconnect if disconnected
    if (!isActuallyConnected) {
      _supabase.realtime.connect();
    }

    // 3. Refresh Presence
    final userId = _supabase.auth.currentUser?.id;
    if (userId != null) {
      PresenceService().setUserOnline(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    if ((_isLoading && !_isSearching && _chats.isEmpty) || _isNavigationPending()) {
      final message = 'LoZo';
      return SplashScreen(message: message);
    }

    return Scaffold(
      backgroundColor: Colors.black, // Dark background like Messenger
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        currentIndex: 0, // Default to Chats
        showSelectedLabels: true,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.amp_stories),
            label: 'Stories',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications), // Or people
            label: 'Notifications',
          ),
           BottomNavigationBarItem(
            icon: Icon(Icons.menu),
            label: 'Menu',
          ),
        ],
        onTap: (index) {
          // Placeholder for navigation
          if (index == 3) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => SettingsScreen(
                  onThemeChanged: (mode) {
                    final mainApp = context.findAncestorStateOfType<MainAppState>();
                    if (mainApp != null) {
                      mainApp.setThemeMode(mode);
                    }
                  },
                ),
              ),
            ).then((_) => _loadCurrentUserProfile());
          }
        },
      ),
      body: SafeArea(
        child: Column(
          children: [
            // No Internet Connection Banner
            if (!_isConnected)
              Container(
                width: double.infinity,
                color: Colors.redAccent.withOpacity(0.9),
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.wifi_off, color: Colors.white, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'No internet connection',
                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

            // Connection Restored Banner
            if (_showRestoredMessage)
              Container(
                width: double.infinity,
                color: Colors.green.withOpacity(0.9),
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.white, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Connection restored',
                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

            // Custom Messenger Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Chats',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade900,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.settings, color: Colors.white),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => SettingsScreen(
                                  onThemeChanged: (mode) {
                                    final mainApp = context.findAncestorStateOfType<MainAppState>();
                                    if (mainApp != null) {
                                      mainApp.setThemeMode(mode);
                                    }
                                  },
                                ),
                              ),
                            ).then((_) => _loadCurrentUserProfile());
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                height: 45,
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(24.0),
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  style: const TextStyle(color: Colors.white),
                  onChanged: (value) {
                    final trimmedValue = value.trim();
                    setState(() {
                      _isSearching = trimmedValue.isNotEmpty;
                      if (!_isSearching) {
                        _discoveredUsers = [];
                      }
                    });
                    if (_isSearching) {
                      _discoveryPresenter?.searchUsers(trimmedValue);
                    }
                  },
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Search chats or discover users...',
                    hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                    icon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: _isSearching 
                        ? IconButton(
                            icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _isSearching = false;
                                _discoveredUsers = [];
                              });
                            },
                          )
                        : null,
                  ),
                ),
              ),
            ),

            // Stories Section
            SizedBox(
              height: 100,
              child: Builder(
                builder: (context) {
                  final activeChats = _chats.where((chat) {
                    if (chat.isActuallyOnline) return true;
                    if (chat.lastSeen == null) return false;
                    final difference = DateTime.now().difference(chat.lastSeen!);
                    return difference.inMinutes < 1;
                  }).toList();

                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: activeChats.length + 1, // +1 for "Your Profile"
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _buildUserProfileItem();
                      }
                      // Show users from active chats
                      final chat = activeChats[index - 1];
                      return _buildStoryItem(chat);
                    },
                  );
                },
              ),
            ),

            // Background Loading Indicator (non-intrusive)
            if (_isLoading && _chats.isNotEmpty && !_isSearching)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: LinearProgressIndicator(
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                  minHeight: 1,
                ),
              ),

            // Chat List
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await Future.wait([
                    _presenter?.refreshChats() ?? Future.value(),
                    _refreshConnectionStatus(),
                  ]);
                },
                child: _isSearching 
                    ? _buildSearchResults()
                    : (_isLoading && _chats.isEmpty)
                        ? const Center(child: CircularProgressIndicator())
                        : _chats.isEmpty
                            ? const Center(child: Text('No chats yet.', style: TextStyle(color: Colors.grey)))
                            : ListView.builder(
                                itemCount: _chats.length,
                                itemBuilder: (context, index) {
                                  final chat = _chats[index];
                                  return _buildChatItem(chat);
                                },
                              ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserProfileItem() {
    return GestureDetector(
      onTap: () {
        final userId = _supabase.auth.currentUser?.id;
        if (userId != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ProfileScreen(userId: userId),
            ),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.only(right: 16.0),
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: _currentUserProfile?.avatarColor != null 
                      ? Color(_currentUserProfile!.avatarColor!) 
                      : Colors.grey,
                  backgroundImage: _currentUserProfile?.profilePictureUrl != null
                      ? NetworkImage(_currentUserProfile!.profilePictureUrl!)
                      : null,
                  child: _currentUserProfile?.profilePictureUrl == null
                      ? Text(
                          _currentUserProfile?.displayName.isNotEmpty == true 
                              ? _currentUserProfile!.displayName[0].toUpperCase() 
                              : '',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
                        )
                      : null,
                ),
                if (_isConnected)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.greenAccent,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 2.5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 80,
              child: Text(
                'You (${_currentUserProfile?.displayName ?? 'User'})',
                style: const TextStyle(color: Colors.white, fontSize: 11),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    final query = _searchController.text.toLowerCase();
    final filteredChats = _chats.where((chat) => 
      chat.displayName.toLowerCase().contains(query)
    ).toList();

    final discoveryResults = _discoveredUsers.where((user) => 
      !_chats.any((chat) => chat.participantIds.contains(user.id))
    ).toList();

    return ListView(
      children: [
        if (filteredChats.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Your Chats', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.2)),
          ),
          ...filteredChats.map((chat) => _buildChatItem(chat)),
        ],
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text('Discover New Users', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.2)),
        ),
        if (_isDiscoveryLoading)
          const Center(child: Padding(
            padding: EdgeInsets.all(24.0),
            child: CircularProgressIndicator(strokeWidth: 2),
          ))
        else if (discoveryResults.isEmpty && query.length > 0)
          Center(child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              children: [
                Icon(Icons.search_off, color: Colors.grey.shade700, size: 48),
                const SizedBox(height: 16),
                Text(
                  _discoveredUsers.any((u) => _chats.any((c) => c.participantIds.contains(u.id)))
                      ? 'User is already in your chats'
                      : 'No new users found for "$query"',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                ),
              ],
            ),
          ))
        else if (discoveryResults.isEmpty)
          Center(child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Text('Type a username or display name to find users', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
          ))
        else
          ...discoveryResults.map((user) => ListTile(
            leading: CircleAvatar(
              backgroundColor: user.avatarColor != null ? Color(user.avatarColor!) : Colors.blue.shade300,
              backgroundImage: user.profilePictureUrl != null ? NetworkImage(user.profilePictureUrl!) : null,
              child: user.profilePictureUrl == null ? Text(user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '') : null,
            ),
            title: Text(user.displayName, style: const TextStyle(color: Colors.white)),
            subtitle: Text('@${user.username}', style: TextStyle(color: Colors.grey.shade500)),
            trailing: IconButton(
              icon: const Icon(Icons.person_add, color: Colors.blueAccent),
              onPressed: () async {
                final relationshipType = await showDialog<RelationshipType>(
                  context: context,
                  builder: (BuildContext context) => const RelationshipSelectionDialog(),
                );
                if (relationshipType != null) {
                  _discoveryPresenter?.addUserToChatList(user, relationshipType);
                }
              },
            ),
          )),
      ],
    );
  }

  Widget _buildStoryItem(Chat chat) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ChatScreen(chat: chat),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(right: 16.0),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.blueAccent.withOpacity(0.5), width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: chat.avatarColor != null 
                        ? Color(chat.avatarColor!) 
                        : Colors.blue.shade300,
                    backgroundImage: chat.profilePictureUrl != null
                        ? NetworkImage(chat.profilePictureUrl!)
                        : null,
                    child: chat.profilePictureUrl == null
                        ? Text(
                            chat.displayName.isNotEmpty ? chat.displayName[0].toUpperCase() : '',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                ),
                if (chat.isActuallyOnline && _isConnected)
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.greenAccent,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                    ),
                  )
                else if (chat.lastSeen != null && _isConnected)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.black, width: 1.5),
                      ),
                      child: Text(
                        _formatCompactDuration(chat.lastSeen),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 60,
              child: Text(
                chat.displayName.split(' ').first,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatItem(Chat chat) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ChatScreen(chat: chat),
          ),
        );
      },
      onLongPress: () => _showChatOptions(chat),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        color: Colors.black, // Transparent/Black
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: chat.avatarColor != null 
                      ? Color(chat.avatarColor!) 
                      : Colors.blue.shade300,
                  backgroundImage: chat.profilePictureUrl != null
                      ? NetworkImage(chat.profilePictureUrl!)
                      : null,
                  child: chat.profilePictureUrl == null
                      ? Text(
                          chat.displayName.isNotEmpty ? chat.displayName[0] : '',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                        )
                      : null,
                ),
                if (chat.isActuallyOnline && _isConnected)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.greenAccent,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                    ),
                  )
                else if (chat.lastSeen != null && _isConnected)
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.black, width: 1.5),
                      ),
                      child: Text(
                        _formatCompactDuration(chat.lastSeen),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            // Name and Message
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        chat.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 6),
                      // if (_isConnected)
                      //   Text(
                      //     chat.isActuallyOnline ? 'Online' : _formatLastSeenShort(chat.lastSeen),
                      //     style: TextStyle(
                      //       color: chat.isActuallyOnline ? Colors.greenAccent : Colors.grey.shade500,
                      //       fontSize: 11,
                      //       fontWeight: chat.isActuallyOnline ? FontWeight.bold : FontWeight.normal,
                      //     ),
                      //   ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          (() {
                              String displayContent;
                              if (chat.lastMessageContent == null) {
                                displayContent = 'No Messages';
                              } else {
                                final raw = chat.lastMessageContent!;
                                final looksLikeAttachment = raw.trim().startsWith('[') && raw.trim().endsWith(']');
                                if (looksLikeAttachment) {
                                  final isMe = chat.lastMessageSenderId == _supabase.auth.currentUser?.id;
                                  displayContent = isMe
                                      ? 'Sent an attachment'
                                      : '${chat.displayName} sent an attachment';
                                } else {
                                  try {
                                    displayContent = _encryptionService.decryptText(raw);
                                  } catch (e) {
                                    displayContent = 'Encrypted message';
                                  }
                                }
                              }
                              final isMe = chat.lastMessageSenderId == _supabase.auth.currentUser?.id;
                              final senderLabel = chat.lastMessageContent != null ? isMe
                                  ? 'You: '
                                  : (displayContent.contains('sent an attachment') ? '' : '${chat.displayName.split(' ').first}: ') : "";
                              final prefix = senderLabel;
                              return '$prefix$displayContent';
                            })(),
                          style: TextStyle(
                            color: chat.unreadCount > 0 ? Colors.white : Colors.grey,
                            fontSize: 14,
                            fontWeight: chat.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '· ${_formatMessageTimestamp(chat.lastMessageTime)}',
                         style: TextStyle(
                           color: chat.unreadCount > 0 ? Colors.blueAccent : Colors.grey, 
                           fontSize: 12,
                           fontWeight: chat.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                         ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Read Status Indicator (Optional)
            if (chat.lastMessageSenderId == _supabase.auth.currentUser?.id)
              (chat.lastMessageStatus == MessageStatus.read
                  ? _buildReadReceiptAvatar(chat)
                  : _buildMessageStatusIcon(chat.lastMessageStatus, chat)),
            
            // Unread count badge for incoming messages
            if (chat.unreadCount > 0)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${chat.unreadCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatCompactDuration(DateTime? lastSeen) {
    if (lastSeen == null) return '';
    final now = DateTime.now().toUtc();
    final lastSeenUtc = lastSeen.toUtc();
    final difference = now.difference(lastSeenUtc);
    
    if (difference.isNegative || difference.inSeconds < 30) return 'now';
    if (difference.inSeconds < 60) return '${difference.inSeconds}s';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m';
    if (difference.inHours < 24) return '${difference.inHours}h';
    return '${difference.inDays}d';
  }

  String _formatLastSeenShort(DateTime? lastSeen) {
    if (lastSeen == null) return '';
    
    final now = DateTime.now().toUtc();
    final lastSeenUtc = lastSeen.toUtc();
    final difference = now.difference(lastSeenUtc);

    if (difference.inSeconds < 30) {
      return 'just now'; 
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return DateFormat('MMM d').format(lastSeenUtc.toLocal());
    }
  }

  void _showDeleteChatConfirmation(Chat chat) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Chat'),
          content: Text('Are you sure you want to delete your chat with ${chat.displayName}? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      _presenter?.deleteChat(chat.id);
    }
  }

  void _showChatOptions(Chat chat) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.bubble_chart, color: Colors.white),
                title: const Text('Show as Bubble', style: TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(context);
                  await BubbleService.instance.start(
                    chatId: chat.id,
                    title: chat.displayName,
                    body: 'Tap to chat',
                  );
                  try {
                    const platform = MethodChannel('com.example.my_chat_app/bubbles');
                    await platform.invokeMethod('moveTaskToBack');
                  } catch (_) {}
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.redAccent),
                title: const Text('Delete Chat', style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteChatConfirmation(chat);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessageStatusIcon(MessageStatus? status, Chat chat) {
    if (status == null) return const SizedBox.shrink();

    IconData iconData;
    Color iconColor = chat.relationshipType.textColor.withOpacity(0.7); // Use chat's text color for consistency

    switch (status) {
      case MessageStatus.sending:
        iconData = Icons.access_time; // Clock icon for sending
        break;
      case MessageStatus.sent:
        iconData = Icons.check; // Single check for sent
        break;
      case MessageStatus.delivered:
        iconData = Icons.done_all; // Double check for delivered
        break;
      case MessageStatus.read:
        iconData = Icons.done_all; // Double check for read
        iconColor = chat.relationshipType.primaryColor; // Use chat's primary color for read
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Icon(
        iconData,
        size: 14,
        color: iconColor,
      ),
    );
  }

  Widget _buildReadReceiptAvatar(Chat chat) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, right: 6.0),
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24, width: 2),
        ),
        child: CircleAvatar(
          radius: 10,
          backgroundImage: chat.profilePictureUrl != null
              ? NetworkImage(chat.profilePictureUrl!)
              : null,
          backgroundColor: Colors.grey.shade700,
          child: chat.profilePictureUrl == null
              ? Text(
                  chat.displayName.isNotEmpty ? chat.displayName[0] : '?',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                )
              : null,
        ),
      ),
    );
  }
  String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now().toUtc();
    final lastSeenUtc = lastSeen.toUtc();
    final difference = now.difference(lastSeenUtc);

    if (difference.inSeconds < 30) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes < 1 ? 1 : difference.inMinutes;
      return 'Active ${minutes}m ago';
    } else if (difference.inHours < 24) {
      return 'Active ${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return 'Active ${difference.inDays}d ago';
    } else {
      return 'Active on ${DateFormat('MMM d').format(lastSeenUtc.toLocal())}';
    }
  }

  Color _getLastSeenColor(DateTime lastSeen) {
    final now = DateTime.now().toUtc();
    final lastSeenUtc = lastSeen.toUtc();
    final difference = now.difference(lastSeenUtc);

    if (difference.isNegative || difference.inSeconds < 30) {
      return Colors.greenAccent;
    } else {
      return Colors.grey;
    }
  }

  String _formatMessageTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final messageDate = DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (messageDate.isAtSameMomentAs(today)) {
      return DateFormat('h:mm a').format(timestamp.toLocal());
    } else if (messageDate.isAtSameMomentAs(yesterday)) {
      return 'Yesterday';
    } else if (now.difference(messageDate).inDays < 7) {
      return DateFormat('EEE').format(timestamp.toLocal());
    } else {
      return DateFormat('dd/MM/yyyy').format(timestamp.toLocal());
    }
  }
}
