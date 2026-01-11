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
                      child: Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage: chat.otherUserProfilePictureUrl != null
                                ? NetworkImage(chat.otherUserProfilePictureUrl!)
                                : null,
                            child: chat.otherUserProfilePictureUrl == null
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          title: Text(chat.relationshipType.name),
                          subtitle: Row(
                            children: [
                              // Show status icon only for current user's last message
                              if (chat.lastMessageSenderId != null &&
                                  chat.lastMessageSenderId == _firebaseAuth.currentUser?.uid)
                                  _buildMessageStatusIcon(chat.lastMessageStatus, chat),
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
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 14, color: chat.relationshipType.textColor.withOpacity(0.9)),
                                ),
                              ),
                            ],
                          ),
                          trailing: Text(
                            '${chat.lastMessageTime.toLocal().hour.toString().padLeft(2, '0')}:' +
                                '${chat.lastMessageTime.toLocal().minute.toString().padLeft(2, '0')}',
                            style: TextStyle(fontSize: 12, color: chat.relationshipType.textColor.withOpacity(0.7)),
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
}
