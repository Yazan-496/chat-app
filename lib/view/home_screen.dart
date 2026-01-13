import 'package:intl/intl.dart'; // New import for DateFormat
import 'package:my_chat_app/main.dart'; // New import for MainAppState
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_chat_app/model/chat.dart';
import 'package:my_chat_app/model/message.dart'; // Import Message and MessageStatus
import 'package:my_chat_app/model/relationship.dart'; // Import RelationshipExtension
import 'package:my_chat_app/services/encryption_service.dart'; // New import
import 'package:my_chat_app/services/local_storage_service.dart'; // New import
import 'package:my_chat_app/presenter/home_presenter.dart';
import 'package:my_chat_app/view/chat_screen.dart';
import 'package:my_chat_app/view/home_view.dart';
import 'package:my_chat_app/view/profile_screen.dart';
import 'package:my_chat_app/view/settings_screen.dart'; // New import
import 'package:my_chat_app/view/user_discovery_screen.dart';
import 'package:my_chat_app/services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  final String? initialChatId;
  const HomeScreen({super.key, this.initialChatId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> implements HomeView {
  late HomePresenter _presenter;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final EncryptionService _encryptionService = EncryptionService(); // New instance
  final LocalStorageService _localStorageService = LocalStorageService(); // New instance
  List<Chat> _chats = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _presenter = HomePresenter(this);
    _presenter.loadChats();
    NotificationService().getToken().then((token) {
      if (token != null) {
        debugPrint('FCM_TOKEN=$token');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // ScaffoldMessenger.of(context).showSnackBar(
            // SnackBar(content: Text('FCM: $token')),
          // );
        });
      }
    });
  }

  @override
  void showLoading() {
    setState(() {
      _isLoading = true;
    });
  }

  @override
  void hideLoading() {
    setState(() {
      _isLoading = false;
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
  void displayChats(List<Chat> chats) {
    setState(() {
      _chats = chats;
    });
    final mainApp = context.findAncestorStateOfType<MainAppState>();
    final pendingId = mainApp?.consumePendingChatId() ?? widget.initialChatId;
    if (pendingId != null) {
      Chat? target;
      for (final c in _chats) {
        if (c.id == pendingId) {
          target = c;
          break;
        }
      }
      if (target != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ChatScreen(chat: target!),
            ),
          );
        });
      }
    }
  }

  @override
  void updateView() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
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
            );
          }
        },
      ),
      body: SafeArea(
        child: Column(
          children: [
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
                          icon: const Icon(Icons.camera_alt, color: Colors.white),
                          onPressed: () {}, // Camera action
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade900,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.edit, color: Colors.white),
                          onPressed: () {
                             Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const UserDiscoveryScreen(),
                                ),
                              );
                          }, // New chat action
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
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      'Search',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

            // Stories Section
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: _chats.length + 1, // +1 for "Create Story"
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildCreateStoryItem();
                  }
                  // Mock stories using chat users
                  final chat = _chats[index - 1];
                  return _buildStoryItem(chat);
                },
              ),
            ),

            // Chat List
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await _presenter.refreshChats();
                },
                child: _isLoading
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

  Widget _buildCreateStoryItem() {
    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: Column(
        children: [
          Stack(
            children: [
              const CircleAvatar(
                radius: 30,
                backgroundColor: Colors.grey,
                child: Icon(Icons.person, color: Colors.white, size: 30),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                  child: const CircleAvatar(
                    radius: 10,
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.add, size: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Your Story',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryItem(Chat chat) {
    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.blueAccent, width: 2),
            ),
            child: CircleAvatar(
              radius: 28,
              backgroundImage: chat.otherUserProfilePictureUrl != null
                  ? NetworkImage(chat.otherUserProfilePictureUrl!)
                  : null,
              child: chat.otherUserProfilePictureUrl == null
                  ? Text(chat.otherUserName.isNotEmpty ? chat.otherUserName[0].toUpperCase() : '')
                  : null,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            chat.otherUserName.split(' ')[0], // First name only
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
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
                 FutureBuilder<int?>(
                    future: _localStorageService.getAvatarColor(_firebaseAuth.currentUser!.uid),
                    builder: (context, snapshot) {
                      Color avatarColor = Colors.blue.shade300;
                      if (snapshot.hasData && snapshot.data != null) {
                        avatarColor = Color(snapshot.data!);
                      }
                      return CircleAvatar(
                        radius: 28,
                        backgroundColor: avatarColor,
                        backgroundImage: chat.otherUserProfilePictureUrl != null
                            ? NetworkImage(chat.otherUserProfilePictureUrl!)
                            : null,
                        child: chat.otherUserProfilePictureUrl == null
                            ? Text(
                                chat.otherUserName.isNotEmpty ? chat.otherUserName[0].toUpperCase() : '',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                              )
                            : null,
                      );
                    },
                  ),
                if (chat.otherUserIsOnline)
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
                  ),
              ],
            ),
            const SizedBox(width: 12),
            // Name and Message
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chat.otherUserName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          (() {
                              String displayContent;
                              if (chat.lastMessageContent == null) {
                                displayContent = 'Sent an attachment';
                              } else {
                                final raw = chat.lastMessageContent!;
                                final looksLikeAttachment = raw.trim().startsWith('[') && raw.trim().endsWith(']');
                                if (looksLikeAttachment) {
                                  final isMe = chat.lastMessageSenderId == _firebaseAuth.currentUser?.uid;
                                  displayContent = isMe
                                      ? 'Sent an attachment'
                                      : '${chat.otherUserName.split(' ').first} sent an attachment';
                                } else {
                                  try {
                                    displayContent = _encryptionService.decryptText(raw);
                                  } catch (e) {
                                    displayContent = 'Encrypted message';
                                  }
                                }
                              }
                              final isMe = chat.lastMessageSenderId == _firebaseAuth.currentUser?.uid;
                              final senderLabel = isMe
                                  ? 'You: '
                                  : (displayContent.contains('sent an attachment') ? '' : '${chat.otherUserName.split(' ').first}: ');
                              final prefix = senderLabel;
                              return '$prefix$displayContent';
                            })(),
                          style: TextStyle(
                            color: chat.lastMessageStatus == MessageStatus.read ? Colors.grey : Colors.white70,
                            fontSize: 14,
                            fontWeight: chat.lastMessageStatus == MessageStatus.read ? FontWeight.normal : FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '· ${_formatMessageTimestamp(chat.lastMessageTime)}',
                         style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Read Status Indicator (Optional)
            if (chat.lastMessageSenderId == _firebaseAuth.currentUser?.uid)
              (chat.lastMessageStatus == MessageStatus.read
                  ? _buildReadReceiptAvatar(chat)
                  : _buildMessageStatusIcon(chat.lastMessageStatus, chat)),
          ],
        ),
      ),
    );
  }

  void _showDeleteChatConfirmation(Chat chat) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Chat'),
          content: Text('Are you sure you want to delete your chat with ${chat.otherUserName}? This action cannot be undone.'),
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
      _presenter.deleteChat(chat.id);
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
                  await NotificationService.showBubble(
                    chatId: chat.id,
                    title: chat.otherUserName,
                    body: 'Open conversation',
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
          backgroundImage: chat.otherUserProfilePictureUrl != null
              ? NetworkImage(chat.otherUserProfilePictureUrl!)
              : null,
          backgroundColor: Colors.grey.shade700,
          child: chat.otherUserProfilePictureUrl == null
              ? Text(
                  chat.otherUserName.isNotEmpty ? chat.otherUserName[0].toUpperCase() : '?',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                )
              : null,
        ),
      ),
    );
  }
String _formatLastSeen(DateTime lastSeen) {
  final now = DateTime.now();
  final difference = now.difference(lastSeen);

  if (difference.inMinutes < 1) {
    return 'Active now';
  } else if (difference.inMinutes < 60) {
    return 'Active ${difference.inMinutes}m ago';
  } else if (difference.inHours < 24) {
    return 'Active ${difference.inHours}h ago';
  } else if (difference.inDays == 1) {
    return 'Active yesterday';
  } else if (difference.inDays < 7) {
    return 'Active on ${DateFormat('EEE').format(lastSeen.toLocal())}';
  } else {
    return 'Active on ${DateFormat('dd/MM/yyyy').format(lastSeen.toLocal())}';
  }
}

Color _getLastSeenColor(DateTime lastSeen) {
  final now = DateTime.now();
  final difference = now.difference(lastSeen);

  if (difference.inSeconds < 30) {
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
