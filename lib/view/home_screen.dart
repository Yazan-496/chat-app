import 'dart:async';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:my_chat_app/main.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_chat_app/model/chat_summary.dart';
import 'package:my_chat_app/model/message.dart';
import 'package:my_chat_app/model/user_relationship.dart';
import 'package:my_chat_app/model/profile.dart';
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
import 'package:my_chat_app/services/presence_service.dart';
import 'package:my_chat_app/data/user_repository.dart';
import 'package:my_chat_app/model/profile.dart' as app_user;
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
  List<ChatSummary> _chats = [];
  List<app_user.Profile> _discoveredUsers = [];
  bool _isLoading = false;
  bool _isSearching = false;
  bool _isDiscoveryLoading = false;
  app_user.Profile? _currentUserProfile;
  StreamSubscription<String>? _navigationSubscription;
  RealtimeChannel? _statusChannel;
  Timer? _statusUpdateTimer;
  Timer? _connectionDebounceTimer;
  bool _isConnected = true;
  bool _showRestoredMessage = false;
  Timer? _restoredMessageTimer;
  bool _isProcessingInitialChat = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialChatId != null) {
      _isProcessingInitialChat = true;
    }
    _discoveryPresenter = UserDiscoveryPresenter(this);
    _presenter = HomePresenter(this);
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
            
            // Sync pending messages that were sent while offline
            _presenter?.syncPendingMessages();

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
      if (!mounted) return;
      _checkAndNavigateWithId(chatId);
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
  void displaySearchResults(List<app_user.Profile> users) {
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
          if (_chats[i].otherProfile.id == userId) {
            _chats[i] = _chats[i].copyWith(
              otherProfile: _chats[i].otherProfile.copyWith(
                status: isOnline ? UserStatus.online : UserStatus.offline,
                lastSeen: lastSeen,
              ),
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
        debugPrint('Error checking notification launch: $e');
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
  void displayChats(List<ChatSummary> chats) {
    setState(() {
      _chats = chats;
    });
    _checkAndNavigate();
  }
Future<void> _checkAndNavigate() async {
    if (!mounted) return;

    final mainApp = context.findAncestorStateOfType<MainAppState>();
    final pendingId = mainApp?.consumePendingChatId();

    if (pendingId != null) {
      if (mounted) setState(() => _isProcessingInitialChat = true);
      _checkAndNavigateWithId(pendingId);
    } else if (widget.initialChatId != null && _isProcessingInitialChat) {
        // Fallback: If widget.initialChatId was passed but pendingId was already consumed or null
        // We still need to process it if we haven't yet.
        _checkAndNavigateWithId(widget.initialChatId!);
    }
  }


  Future<void> _checkAndNavigateWithId(String pendingId) async {
    debugPrint('HomeScreen: Found pending chatId to navigate: $pendingId');
    
    ChatSummary? target;
    for (final c in _chats) {
      if (c.chat.id == pendingId) {
        target = c;
        break;
      }
    }

    if (target != null) {
      _navigateToChat(target);
    } else {
      debugPrint('HomeScreen: Target chat $pendingId not found in loaded chats. Fetching directly.');
      // Keep loading indicator
      final fetchedChat = await _presenter?.getChat(pendingId);
      
      if (fetchedChat != null && mounted) {
        _navigateToChat(fetchedChat);
      } else {
        debugPrint('HomeScreen: Error - Could not fetch chat $pendingId');
        if (mounted) setState(() => _isProcessingInitialChat = false);
      }
    }
  }

  void _navigateToChat(ChatSummary chat) {
    debugPrint('HomeScreen: Navigating to chat: ${chat.chat.id}');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            chat: chat.chat,
            otherProfile: chat.otherProfile,
          ),
        ),
      );
    });
  }

  bool _isNavigationPending() {
    final mainApp = context.findAncestorStateOfType<MainAppState>();
    return mainApp?.hasPendingChatId() == true;
  }


  List<String> _participantIds(ChatSummary chat) {
    return [chat.chat.userOneId, chat.chat.userTwoId];
  }

  String _displayName(ChatSummary chat) {
    return chat.otherProfile.displayName;
  }

  String _shortDisplayName(ChatSummary chat) {
    return chat.otherProfile.displayName.split(' ').first;
  }

  String? _avatarUrl(ChatSummary chat) {
    return chat.otherProfile.avatarUrl;
  }

  int? _avatarColor(ChatSummary chat) {
    return chat.otherProfile.avatarColor;
  }

  bool _isActuallyOnline(ChatSummary chat) {
    return chat.otherProfile.status == UserStatus.online;
  }

  DateTime? _lastSeen(ChatSummary chat) {
    return chat.otherProfile.lastSeen;
  }

  String? _lastMessageContent(ChatSummary chat) {
    return chat.lastMessage?.content;
  }

  String? _lastMessageSenderId(ChatSummary chat) {
    return chat.lastMessage?.senderId;
  }

  DateTime? _lastMessageTime(ChatSummary chat) {
    return chat.lastMessage?.createdAt;
  }

  MessageStatus? _lastMessageStatus(ChatSummary chat) {
    final lastMessage = chat.lastMessage;
    if (lastMessage == null) return null;
    if (chat.deliveredStatus.lastReadMessageId == lastMessage.id) {
      return MessageStatus.read;
    }
    if (chat.deliveredStatus.lastDeliveredMessageId == lastMessage.id) {
      return MessageStatus.delivered;
    }
    return lastMessage.status;
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

    // 2. Refresh Presence
    final userId = _supabase.auth.currentUser?.id;
    if (userId != null) {
      PresenceService().setUserOnline(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isNavigationPending() || _isProcessingInitialChat) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_isLoading && !_isSearching && _chats.isEmpty) {
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
                color: Colors.redAccent.withValues(alpha: 230),
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
                color: Colors.green.withValues(alpha: 230),
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
                    if (_isActuallyOnline(chat)) return true;
                    final lastSeen = _lastSeen(chat);
                    if (lastSeen == null) return false;
                    final difference = DateTime.now().difference(lastSeen);
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
                  backgroundImage: _currentUserProfile?.avatarUrl != null
                      ? CachedNetworkImageProvider(_currentUserProfile!.avatarUrl!)
                      : null,
                  child: _currentUserProfile?.avatarUrl == null
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
      _displayName(chat).toLowerCase().contains(query)
    ).toList();

    final discoveryResults = _discoveredUsers.where((user) => 
      !_chats.any((chat) => _participantIds(chat).contains(user.id))
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
                  _discoveredUsers.any((u) => _chats.any((c) => _participantIds(c).contains(u.id)))
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
              backgroundImage: user.avatarUrl != null ? CachedNetworkImageProvider(user.avatarUrl!) : null,
              child: user.avatarUrl == null ? Text(user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '') : null,
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

  Widget _buildStoryItem(ChatSummary chat) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              chat: chat.chat,
              otherProfile: chat.otherProfile,
            ),
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
                    border: Border.all(color: Colors.blueAccent.withValues(alpha: 128), width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: _avatarColor(chat) != null 
                        ? Color(_avatarColor(chat)!) 
                        : Colors.blue.shade300,
                    backgroundImage: _avatarUrl(chat) != null
                        ? CachedNetworkImageProvider(_avatarUrl(chat)!)
                        : null,
                    child: _avatarUrl(chat) == null
                        ? Text(
                            _displayName(chat).isNotEmpty ? _displayName(chat)[0].toUpperCase() : '',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                ),
                if (_isActuallyOnline(chat) && _isConnected)
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
                else if (_lastSeen(chat) != null && _isConnected)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800.withValues(alpha: 230),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.black, width: 1.5),
                      ),
                      child: Text(
                        _formatCompactDuration(_lastSeen(chat)),
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
                _shortDisplayName(chat),
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

  Widget _buildChatItem(ChatSummary chat) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              chat: chat.chat,
              otherProfile: chat.otherProfile,
            ),
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
                  backgroundColor: _avatarColor(chat) != null 
                      ? Color(_avatarColor(chat)!) 
                      : Colors.blue.shade300,
                  backgroundImage: _avatarUrl(chat) != null
                      ? CachedNetworkImageProvider(_avatarUrl(chat)!)
                      : null,
                  child: _avatarUrl(chat) == null
                      ? Text(
                          _displayName(chat).isNotEmpty ? _displayName(chat)[0].toUpperCase() : '',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                        )
                      : null,
                ),
                if (_isActuallyOnline(chat) && _isConnected)
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
                else if (_lastSeen(chat) != null && _isConnected)
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800.withValues(alpha: 230),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.black, width: 1.5),
                      ),
                      child: Text(
                        _formatCompactDuration(_lastSeen(chat)),
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
                        _displayName(chat),
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
                      Flexible(
                        child: Text(
                          (() {
                              String displayContent;
                              if (_lastMessageContent(chat) == null) {
                                displayContent = 'No Messages';
                              } else {
                                final raw = _lastMessageContent(chat)!;
                                final looksLikeAttachment = raw.trim().startsWith('[') && raw.trim().endsWith(']');
                                if (looksLikeAttachment) {
                                  final isMe = _lastMessageSenderId(chat) == _supabase.auth.currentUser?.id;
                                  displayContent = isMe
                                      ? 'Sent an attachment'
                                      : '${_displayName(chat)} sent an attachment';
                                } else {
                                  try {
                                    displayContent = _encryptionService.decryptText(raw);
                                  } catch (e) {
                                    displayContent = 'Encrypted message';
                                  }
                                }
                              }
                              final isMe = _lastMessageSenderId(chat) == _supabase.auth.currentUser?.id;
                              final senderLabel = _lastMessageContent(chat) != null ? isMe
                                  ? 'You: '
                                  : (displayContent.contains('sent an attachment') ? '' : '${_shortDisplayName(chat)}: ') : "";
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
                        '· ${_formatMessageTimestamp(_lastMessageTime(chat) ?? DateTime.now())}',
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
              // Push status indicator to the far right
                      if (_lastMessageSenderId(chat) == _supabase.auth.currentUser?.id)
                        // const Spacer(),
                        // const Spacer(),
                      // Status indicator in the same row as message and time with constant width
                      if (_lastMessageSenderId(chat) == _supabase.auth.currentUser?.id)
                        SizedBox(
                          width: 55,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: _lastMessageStatus(chat) == MessageStatus.read
                                ? _buildReadReceiptAvatar(chat)
                                : _buildMessageStatusIcon(_lastMessageStatus(chat), chat),
                          ),
                        ),
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

  void _showDeleteChatConfirmation(ChatSummary chat) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Chat'),
          content: Text('Are you sure you want to delete your chat with ${_displayName(chat)}? This action cannot be undone.'),
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
      _presenter?.deleteChat(chat.chat.id);
    }
  }

  void _showChatOptions(ChatSummary chat) {
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
                  await NotificationService.showBubbleForChat(
                    NotificationChat(
                      id: chat.chat.id,
                      displayName: _displayName(chat),
                      avatarUrl: _avatarUrl(chat),
                      avatarColor: _avatarColor(chat),
                    ),
                  );
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

  Widget _buildMessageStatusIcon(MessageStatus? status, ChatSummary chat) {
    if (status == null) return const SizedBox.shrink();

    if (status == MessageStatus.read) {
      return _buildReadReceiptAvatar(chat);
    }

    String statusText;
    Color textColor = Colors.grey;

    switch (status) {
      case MessageStatus.sending:
        statusText = 'sending';
        break;
      case MessageStatus.sent:
        statusText = 'sent';
        break;
      case MessageStatus.delivered:
        statusText = 'delivered';
        break;
      case MessageStatus.failed:
        statusText = 'failed';
        textColor = Colors.redAccent;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Text(
        statusText,
        style: TextStyle(
          fontSize: 10,
          color: textColor,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildReadReceiptAvatar(ChatSummary chat) {
    return Padding(
      padding: const EdgeInsets.only(left: 1.0),
      child: CircleAvatar(
        radius: 10,
        backgroundColor: _avatarColor(chat) != null 
            ? Color(_avatarColor(chat)!) 
            : Colors.blue.shade300,
        backgroundImage: _avatarUrl(chat) != null
            ? CachedNetworkImageProvider(_avatarUrl(chat)!)
            : null,
        child: _avatarUrl(chat) == null
            ? Text(
                _displayName(chat).isNotEmpty ? _displayName(chat)[0].toUpperCase() : '',
                style: const TextStyle(
                  color: Colors.white, 
                  fontWeight: FontWeight.bold, 
                  fontSize: 8,
                ),
              )
            : null,
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
