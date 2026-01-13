import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:my_chat_app/model/chat.dart';
import 'package:my_chat_app/model/message.dart';
import 'package:my_chat_app/presenter/chat_presenter.dart';
import 'package:my_chat_app/view/chat_view.dart';
import 'package:my_chat_app/view/voice_message_player.dart';
import 'package:my_chat_app/l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_chat_app/view/profile_screen.dart';
import 'package:my_chat_app/view/widgets/message_item.dart';
import 'package:my_chat_app/services/local_storage_service.dart';
import 'package:my_chat_app/services/notification_service.dart';
import 'package:flutter/services.dart';
import 'package:my_chat_app/services/sound_service.dart';

class ChatScreen extends StatefulWidget {
  final Chat chat;

  const ChatScreen({super.key, required this.chat});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> implements ChatView {
  late ChatPresenter _presenter;
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  List<Message> _messages = [];
  bool _isLoading = false;
  final LocalStorageService _localStorageService = LocalStorageService(); // New instance

  // New emoji reactions list
  final List<String> _emojiReactions = [
    '🫂', // Hug
    '💋', // Kiss
    '❤️', // Heart
    '😡', // Angry
    '😂', // Laugh
    '🌝', // Moon
    '😀', // Generic emoji
    '😒', // Unamused (added from previous session, ensure consistency)
  ];

  @override
  void initState() {
    super.initState();
    _presenter = ChatPresenter(this, widget.chat);
    _presenter.loadMessages();
    _presenter.markMessagesAsRead();
    NotificationService.setActiveChatId(widget.chat.id);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _inputFocusNode.dispose();
    _presenter.dispose(); // Dispose the presenter
    NotificationService.setActiveChatId(null);
    super.dispose();
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
  void displayMessages(List<Message> messages) {
    setState(() {
      _messages = messages;
    });
  }

  @override
  void updateView() {
    setState(() {});
  }

  void _sendMessage() {
    if (_presenter.selectedMessageForEdit != null) {
      _presenter.confirmEditMessage(_messageController.text);
    } else {
      _presenter.sendTextMessage(_messageController.text);
    }
    _messageController.clear();
    _presenter.cancelReply(); // Clear reply state after sending
    _presenter.cancelEdit(); // Clear edit state after sending
    _presenter.notifyTyping(false);
  }

  void _toggleRecording() async {
    if (_presenter.isRecording) {
      await _presenter.stopRecordingAndSend();
    } else {
      await _presenter.startRecording();
    }
  }

  void _showImageSourceSelection() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Photo Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _presenter.sendImageMessage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _presenter.sendImageMessage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  bool _isOnlyEmojis(String text) {
    if (text.isEmpty) return false;
    
    // Check for Latin letters and numbers first (fast path)
    if (RegExp(r'[a-zA-Z0-9]').hasMatch(text)) return false;

    // Explicitly check for Arabic characters
    if (RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]').hasMatch(text)) return false;
    
    // General Unicode Letter/Number check
    try {
      if (RegExp(r'[\p{L}\p{N}]', unicode: true).hasMatch(text)) return false;
    } catch (e) {
      // Fallback if unicode property is not supported
    }

    // Only treat as emoji if short and no text detected
    return text.runes.length <= 5; 
  }

  void _showReactionPicker(Message message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _emojiReactions.map((emoji) {
              return GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  _presenter.addReaction(message.id, emoji);
                },
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 32),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCurrentUser = (senderId) => senderId == _presenter.currentUserId;
    final replyingTo = _presenter.selectedMessageForReply;
    final editingMessage = _presenter.selectedMessageForEdit;

    return Scaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent, // Transparent for gradient background
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ProfileScreen(userId: widget.chat.getOtherUserId(_presenter.currentUserId!)),
              ),
            );
          },
          child: Row(
            children: [
              FutureBuilder<int?>(
                future: _localStorageService.getAvatarColor(widget.chat.getOtherUserId(_presenter.currentUserId!)),
                builder: (context, snapshot) {
                  Color avatarColor = Colors.blue.shade300;
                  if (snapshot.hasData && snapshot.data != null) {
                    avatarColor = Color(snapshot.data!);
                  }
                  return Stack(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: avatarColor,
                        backgroundImage: widget.chat.otherUserProfilePictureUrl != null
                            ? NetworkImage(widget.chat.otherUserProfilePictureUrl!)
                            : null,
                        child: widget.chat.otherUserProfilePictureUrl == null
                            ? Text(
                                widget.chat.otherUserName.isNotEmpty ? widget.chat.otherUserName[0].toUpperCase() : '',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                              )
                            : null,
                      ),
                      if (widget.chat.otherUserIsOnline)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.greenAccent,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.black, width: 2),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.chat.otherUserName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  if (_presenter.otherUserTyping)
                    Text(
                      AppLocalizations.of(context).translate('typing'),
                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                    )
                  else
                    Text(
                      widget.chat.otherUserIsOnline ? 'Active Now' : _formatLastSeen(widget.chat.otherUserLastSeen ?? DateTime.now()),
                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call, color: Colors.purpleAccent),
            onPressed: () {}, // Implement call action
          ),
          IconButton(
            icon: const Icon(Icons.videocam, color: Colors.purpleAccent),
            onPressed: () {}, // Implement video call action
          ),
          IconButton(
            icon: const Icon(Icons.info, color: Colors.purpleAccent),
            onPressed: () {}, // Implement chat info
          ),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
          SystemChannels.textInput.invokeMethod('TextInput.hide');
        },
        child: Container(
        color: const Color(0xFF121212), // Solid dark background
        child: Column(
          children: [
            // Spacer for AppBar since extendBodyBehindAppBar is true
            SizedBox(height: kToolbarHeight + MediaQuery.of(context).padding.top),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : ListView.separated(
                      reverse: true,
                      itemCount: _messages.length,
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                      // Optimization: Use a separate widget for items to prevent full list rebuilds
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        final bool isMe = isCurrentUser(message.senderId);
                        final bool showAvatar = !isMe && (index == 0 || _messages[index - 1].senderId != message.senderId);

                        return MessageItem(
                          key: ValueKey(message.id), // Key helps flutter reuse widgets efficiently
                          message: message,
                          isMe: isMe,
                          showAvatar: showAvatar,
                          otherUserProfilePictureUrl: widget.chat.otherUserProfilePictureUrl,
                          otherUserName: widget.chat.otherUserName,
                          isOnlyEmojis: _isOnlyEmojis(message.content) && message.type == MessageType.text,
                          onLongPress: _showReactionPicker,
                          buildReplyPreview: _buildReplyPreview,
                          buildReactions: _buildReactions,
                          buildMessageStatus: _buildMessageStatusWidget,
                        );
                      },
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                    ),
            ),
            if (replyingTo != null)
              _buildActiveReplyPreview(replyingTo),
            if (editingMessage != null)
              _buildActiveEditIndicator(editingMessage),
            _buildInputArea(),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildInputArea() {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
        bottom: true,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.image, color: Colors.pinkAccent, size: 28),
              onPressed: _showImageSourceSelection,
            ),
            IconButton(
              icon: const Icon(Icons.mic, color: Colors.pinkAccent, size: 28),
              onPressed: _toggleRecording,
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(24.0),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        focusNode: _inputFocusNode,
                        style: const TextStyle(color: Colors.white),
                        scrollPadding: EdgeInsets.zero,
                        enableSuggestions: false,
                        smartDashesType: SmartDashesType.disabled,
                        smartQuotesType: SmartQuotesType.disabled,
                        textInputAction: TextInputAction.send,
                        decoration: InputDecoration(
                          hintText: 'Message',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        ),
                        onTap: () {
                          SystemChannels.textInput.invokeMethod('TextInput.show');
                        },
                        onChanged: (text) {
                          _presenter.notifyTyping(text.isNotEmpty);
                          // Removed setState to prevent full screen rebuilds on every keystroke
                        },
                        onSubmitted: (_) {
                          if (_messageController.text.trim().isNotEmpty) {
                            _sendMessage();
                          }
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.sentiment_satisfied_alt, color: Colors.pinkAccent),
                      onPressed: () {}, // Emoji picker
                    ),
                  ],
                ),
              ),
            ),
            // Optimized to rebuild only the button when text changes
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _messageController,
              builder: (context, value, child) {
                final hasText = value.text.trim().isNotEmpty;
                return IconButton(
                  icon: hasText 
      ? const Icon(
          Icons.send, 
          color: Colors.pinkAccent, 
          size: 28,
        ) 
      : const Text(
          '🌝', 
          style: TextStyle(
            fontSize: 28, // Matches the icon size
          ),
        ),
                  onPressed: hasText 
                      ? _sendMessage 
                      : () => _presenter.sendTextMessage("🌝"),
                );
              },
            ),
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

  Widget _buildMessageStatusWidget(Message message, bool isCurrentUser) {
    if (!isCurrentUser) {
      return const SizedBox.shrink(); // No status for incoming messages
    }

    // For outgoing messages, display status icons
    IconData iconData;
    Color iconColor = Colors.grey; // Default color

    switch (message.status) {
      case MessageStatus.sending:
        iconData = Icons.access_time; // Clock icon for sending
        break;
      case MessageStatus.sent:
        iconData = Icons.check; // Single check for sent
        iconColor = Colors.grey; // Set color for sent messages
        break;
      case MessageStatus.delivered:
        iconData = Icons.done_all; // Double check for delivered
        break;
      case MessageStatus.read:
        iconData = Icons.done_all; // Double check for read
        iconColor = Colors.blue; // Different color for read
        break;
    }

    return Icon(
      iconData,
      size: 14,
      color: iconColor,
    );
  }

  Widget _buildReactions(Map<String, String> reactions) {
    if (reactions.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 2.0),
      decoration: BoxDecoration(
        color: const Color(0xFF303030), // Dark grey background for reactions
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: Colors.transparent),
        boxShadow: [
          BoxShadow(
            color: Colors.transparent.withOpacity(0.5),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: reactions.values.map((emoji) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.0),
          child: Text(emoji, style: const TextStyle(fontSize: 14)),
        )).toList(),
      ),
    );
  }

  Widget _buildReplyPreview(String replyToMessageId) {
    final repliedMessage = _presenter.getMessageById(replyToMessageId);
    if (repliedMessage == null) return const SizedBox.shrink();
    
    final isMe = repliedMessage.senderId == _presenter.currentUserId;
    final senderName = isMe ? 'You' : widget.chat.otherUserName;

    return Container(
      margin: const EdgeInsets.only(bottom: 4.0),
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Replying to $senderName',
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            repliedMessage.type == MessageType.text 
                ? repliedMessage.content 
                : (repliedMessage.type == MessageType.image ? '📷 Photo' : '🎤 Voice Message'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActiveReplyPreview(Message message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C), // Dark background for active reply
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Replying to ${message.senderId == _presenter.currentUserId ? 'You' : widget.chat.otherUserName}',
                  style: const TextStyle(fontSize: 12, color: Colors.pinkAccent, fontWeight: FontWeight.bold),
                ),
                Text(
                  message.type == MessageType.text ? message.content : '[${message.type.name} message]',
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white54),
            onPressed: () {
              _presenter.cancelReply();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActiveEditIndicator(Message message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      color: Colors.blue.withOpacity(0.1),
      child: Row(
        children: [
          const Icon(Icons.edit, size: 16, color: Colors.blue),
          const SizedBox(width: 8),
          const Text('Editing message', style: TextStyle(color: Colors.blue)),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: () {
              _presenter.cancelEdit();
              _messageController.clear();
            },
          ),
        ],
      ),
    );
  }

  String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inMinutes < 1) {
      return 'Last seen just now';
    } else if (difference.inMinutes < 60) {
      return 'Last seen ${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return 'Last seen ${difference.inHours}h ago';
    } else {
      return 'Last seen ${DateFormat('MMM d, h:mm a').format(lastSeen)}';
    }
  }
}


