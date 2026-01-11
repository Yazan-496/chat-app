import 'package:intl/intl.dart'; // New import for DateFormat
import 'package:my_chat_app/main.dart'; // New import for MainAppState
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_chat_app/model/chat.dart';
import 'package:my_chat_app/model/message.dart'; // Import Message and MessageStatus
import 'package:my_chat_app/model/relationship.dart' show RelationshipExtension; // Explicitly import extension
import 'package:my_chat_app/services/encryption_service.dart'; // New import
import 'package:my_chat_app/presenter/home_presenter.dart';
import 'package:my_chat_app/view/chat_screen.dart';
import 'package:my_chat_app/view/home_view.dart';
import 'package:my_chat_app/view/profile_screen.dart';
import 'package:my_chat_app/view/settings_screen.dart'; // New import
import 'package:my_chat_app/view/user_discovery_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> implements HomeView {
  late HomePresenter _presenter;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final EncryptionService _encryptionService = EncryptionService(); // New instance
  List<Chat> _chats = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _presenter = HomePresenter(this);
    _presenter.loadChats();
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
  }

  @override
  void updateView() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const UserDiscoveryScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              final userId = _firebaseAuth.currentUser?.uid;
              if (userId != null) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ProfileScreen(userId: userId),
                  ),
                );
              } else {
                showMessage('Please log in to view your profile.');
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(
                    onThemeChanged: (themeMode) {
                      final mainApp = context.findAncestorStateOfType<MainAppState>();
                      mainApp?.setThemeMode(themeMode);
                    },
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final confirmLogout = await showDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Confirm Logout'),
                    content: const Text('Are you sure you want to log out?'),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('No'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Yes'),
                      ),
                    ],
                  );
                },
              );
              if (confirmLogout == true) {
                await _firebaseAuth.signOut();
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _chats.isEmpty
              ? const Center(child: Text('No chats yet. Start by searching for users!'))
              : ListView.builder(
                  itemCount: _chats.length,
                  itemBuilder: (context, index) {
                    final chat = _chats[index];
                    return GestureDetector(
                      onLongPress: () => _showDeleteChatConfirmation(chat),
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0), // Smaller margins
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor, // Use card color from theme for consistency
                          borderRadius: BorderRadius.circular(12.0), // Rounded corners for chat items
                          boxShadow: [ // Subtle shadow for depth
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0), // Adjusted padding
                          leading: CircleAvatar(
                            radius: 24, // Slightly larger avatar
                            backgroundColor: Colors.blue.shade300, // Distinct, consistent background color
                            backgroundImage: chat.otherUserProfilePictureUrl != null
                                ? NetworkImage(chat.otherUserProfilePictureUrl!)
                                : null,
                            child: chat.otherUserProfilePictureUrl == null
                                ? Text(
                                    chat.otherUserName.isNotEmpty ? chat.otherUserName[0].toUpperCase() : '',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                                  )
                                : null,
                          ),
                          title: Text(
                            chat.otherUserName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), // Prominent name
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0), // Padding above subtitle
                            child: Row(
                              children: [
                                if (chat.lastMessageSenderId != null &&
                                    chat.lastMessageSenderId == _firebaseAuth.currentUser?.uid)
                                  _buildMessageStatusIcon(chat.lastMessageStatus, chat), // Status icon
                                Expanded(
                                  child: Text(
                                    (() {
                                      String displayContent;
                                      if (chat.lastMessageContent == null) {
                                        displayContent = '[No message]';
                                      } else {
                                        try {
                                          displayContent = _encryptionService.decryptText(chat.lastMessageContent!);
                                        } catch (e) {
                                          print('HomeScreen: Decryption failed for chat ${chat.id}, lastMessageContent: ${chat.lastMessageContent}. Error: $e');
                                          displayContent = '[Encrypted Message Error]';
                                        }
                                      }
                                      return chat.lastMessageSenderId == _firebaseAuth.currentUser?.uid
                                          ? 'You: $displayContent'
                                          : '${chat.otherUserName}: $displayContent';
                                    })(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 14, color: Colors.grey), // Soft gray for message preview
                                  ),
                                ),
                              ],
                            ),
                          ),
                          trailing: Text(
                            _formatMessageTimestamp(chat.lastMessageTime),
                            style: const TextStyle(fontSize: 12, color: Colors.grey), // Soft gray for timestamp
                          ),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => ChatScreen(chat: chat),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
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

  String _formatMessageTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final messageDate = DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (messageDate.isAtSameMomentAs(today)) {
      return '${timestamp.toLocal().hour.toString().padLeft(2, '0')}:${timestamp.toLocal().minute.toString().padLeft(2, '0')}';
    } else if (messageDate.isAtSameMomentAs(yesterday)) {
      return 'Yesterday';
    } else if (now.difference(messageDate).inDays < 7) {
      // Within the last 7 days, show weekday
      return DateFormat('EEE').format(timestamp.toLocal()); // E.g., 'Mon'
    } else {
      return DateFormat('dd/MM/yyyy').format(timestamp.toLocal()); // E.g., '01/01/2026'
    }
  }
}
