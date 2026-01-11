import 'package:intl/intl.dart'; // New import for DateFormat
import 'package:flutter/material.dart';
import 'package:my_chat_app/model/chat.dart';
import 'package:my_chat_app/model/message.dart';
import 'package:my_chat_app/presenter/chat_presenter.dart';
import 'package:my_chat_app/view/chat_view.dart';
import 'package:my_chat_app/view/voice_message_player.dart'; // New import
import 'package:my_chat_app/model/relationship.dart'; // Import for RelationshipExtension
import 'package:image_picker/image_picker.dart'; // Import for ImageSource
import 'package:my_chat_app/view/profile_screen.dart'; // Import for ProfileScreen
import 'package:my_chat_app/view/profile_screen.dart'; // Import for ProfileScreen

class ChatScreen extends StatefulWidget {
  final Chat chat;

  const ChatScreen({super.key, required this.chat});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> implements ChatView {
  late ChatPresenter _presenter;
  final TextEditingController _messageController = TextEditingController();
  List<Message> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _presenter = ChatPresenter(this, widget.chat);
    _presenter.loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _presenter.dispose(); // Dispose the presenter
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

  @override
  Widget build(BuildContext context) {
    final isCurrentUser = (senderId) => senderId == _presenter.currentUserId;
    final replyingTo = _presenter.selectedMessageForReply;
    final editingMessage = _presenter.selectedMessageForEdit;

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () {
            // Navigate to user profile/info screen
            // You'll need the other user's ID to pass to the ProfileScreen
            // Assuming `widget.chat.otherUserId` exists or can be derived
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ProfileScreen(userId: widget.chat.getOtherUserId(_presenter.currentUserId!)), // Placeholder other user ID
              ),
            );
          },
          child: Row(
            children: [
              CircleAvatar(
                radius: 18, // Smaller avatar for header
                backgroundColor: Colors.blue.shade300, // Consistent background color
                backgroundImage: widget.chat.otherUserProfilePictureUrl != null
                    ? NetworkImage(widget.chat.otherUserProfilePictureUrl!)
                    : null,
                child: widget.chat.otherUserProfilePictureUrl == null
                    ? Text(
                        widget.chat.otherUserName.isNotEmpty ? widget.chat.otherUserName[0].toUpperCase() : '',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      )
                    : null,
              ),
              const SizedBox(width: 20),
              Text(widget.chat.otherUserName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        backgroundColor: Colors.grey.shade800,
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    reverse: true,
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return GestureDetector(
                        onLongPress: () => _showMessageActions(message),
                        child: Align(
                          alignment: isCurrentUser(message.senderId) ? Alignment.centerRight : Alignment.centerLeft,
                          child: Column(
                            crossAxisAlignment: isCurrentUser(message.senderId) ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              if (message.replyToMessageId != null)
                                _buildReplyPreview(message.replyToMessageId!),
                              Row(
                                mainAxisAlignment: isCurrentUser(message.senderId) ? MainAxisAlignment.end : MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (!isCurrentUser(message.senderId))
                                    _buildMessageAvatar(message.senderId, isCurrentUser(message.senderId), widget.chat.otherUserProfilePictureUrl),
                                  Expanded(
                                    child: Container(
                                      margin: EdgeInsets.only(
                                        left: isCurrentUser(message.senderId) ? 200.0 : 8.0, // Indent incoming messages
                                        right: isCurrentUser(message.senderId) ? 8.0 : 200.0, // Indent outgoing messages
                                        top: 4.0,
                                        bottom: 4.0,
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0), // Consistent padding
                                      decoration: BoxDecoration(
                                        color: isCurrentUser(message.senderId)
                                            ? Colors.blue.shade200 // Blue for outgoing
                                            : Colors.grey.shade300, // Light gray for incoming
                                        borderRadius: BorderRadius.only(
                                          topLeft: const Radius.circular(12.0),
                                          topRight: const Radius.circular(12.0),
                                          bottomLeft: Radius.circular(isCurrentUser(message.senderId) ? 12.0 : 4.0),
                                          bottomRight: Radius.circular(isCurrentUser(message.senderId) ? 4.0 : 12.0),
                                        ), // Modern rounded corners
                                      ),
                                      child: Column(
                                        crossAxisAlignment: isCurrentUser(message.senderId) ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                        children: [
                                          if (message.type == MessageType.text)
                                            Text(
                                              message.editedContent ?? message.content,
                                              style: TextStyle(color: isCurrentUser(message.senderId) ? Colors.white : Colors.black87), // Adjust text color based on bubble color
                                            ),
                                          if (message.type == MessageType.image)
                                            Image.network(message.content, width: 200),
                                          if (message.type == MessageType.voice)
                                            VoiceMessagePlayer(
                                              audioUrl: message.content,
                                              backgroundColor: isCurrentUser(message.senderId) ? Colors.blue.shade600 : Colors.grey.shade300, // Match bubble color
                                              textColor: isCurrentUser(message.senderId) ? Colors.white : Colors.black87,
                                            ),
                                          const SizedBox(height: 4.0),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (isCurrentUser(message.senderId)) // Only show status for outgoing messages
                                                _buildMessageStatusWidget(message, isCurrentUser(message.senderId)),
                                              const SizedBox(width: 4), // Spacing between status and timestamp
                                              Text(
                                                _formatMessageTimestamp(message.timestamp),
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: isCurrentUser(message.senderId) ? Colors.white70 : Colors.black54,
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (message.reactions.isNotEmpty)
                                            _buildReactions(message.reactions),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (replyingTo != null)
            _buildActiveReplyPreview(replyingTo),
          if (editingMessage != null)
            _buildActiveEditIndicator(editingMessage),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(_presenter.isRecording ? Icons.stop : Icons.mic),
                  color: _presenter.isRecording ? Colors.red : null,
                  onPressed: _toggleRecording,
                ),
                IconButton(
                  icon: const Icon(Icons.image),
                  onPressed: _showImageSourceSelection,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: editingMessage != null
                          ? 'Edit message...'
                          : (_presenter.isRecording ? 'Recording voice...' : 'Type a message...'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      suffixIcon: editingMessage != null
                          ? IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                _presenter.cancelEdit();
                                _messageController.clear();
                              },
                            )
                          : null,
                    ),
                    readOnly: _presenter.isRecording, // Disable typing while recording
                  ),
                ),
                const SizedBox(width: 8.0),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
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
    return Container(
      padding: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: reactions.values.map((emoji) => Text(emoji, style: const TextStyle(fontSize: 16))).toList(),
      ),
    );
  }


  Widget _buildReplyPreview(String replyToMessageId) {
    final repliedMessage = _presenter.getMessageById(replyToMessageId);
    if (repliedMessage == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Replying to: ${repliedMessage.senderId == _presenter.currentUserId ? 'You' : widget.chat.otherUserName}',
            style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.blueGrey)),
          Text(repliedMessage.type == MessageType.text ? repliedMessage.content : '[${repliedMessage.type.name} message]',
            style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.green)),
        ],
      ),
    );
  }

  Widget _buildActiveReplyPreview(Message message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Replying to: ${message.senderId == _presenter.currentUserId ? 'You' : widget.chat.otherUserName}',
                  style: TextStyle(fontSize: 12, color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                Text(message.type == MessageType.text ? message.content : '[${message.type.name} message]',
                  style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
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
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text('Editing message...', style: TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.bold)),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              _presenter.cancelEdit();
              _messageController.clear();
            },
          ),
        ],
      ),
    );
  }

  void _showMessageActions(Message message) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.reply),
                title: const Text('Reply'),
                onTap: () {
                  Navigator.pop(context);
                  _startReply(message);
                },
              ),
              if (message.type == MessageType.text && message.senderId == _presenter.currentUserId)
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Edit'),
                  onTap: () {
                    Navigator.pop(context);
                    _startEdit(message);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.emoji_emotions),
                title: const Text('React'),
                onTap: () {
                  Navigator.pop(context);
                  _showEmojiPicker(message);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _startReply(Message message) {
    _presenter.selectMessageForReply(message);
    // Focus the text field
    FocusScope.of(context).requestFocus(FocusNode());
  }

  void _startEdit(Message message) {
    _presenter.selectMessageForEdit(message);
    _messageController.text = message.content;
    // Focus the text field and place cursor at the end
    _messageController.selection = TextSelection.fromPosition(TextPosition(offset: _messageController.text.length));
    FocusScope.of(context).requestFocus(FocusNode());
  }

  void _showEmojiPicker(Message message) {
    // TODO: Implement emoji picker and reaction logic
    showMessage('Showing emoji picker for: ${message.content}');
    _presenter.addReaction(message.id, '❤️'); // Placeholder reaction
  }

  Widget _buildMessageAvatar(String senderId, bool isCurrentUser, String? otherUserProfilePictureUrl) {
    if (isCurrentUser) {
      // Optionally show current user's avatar, or an empty SizedBox for alignment
      return const SizedBox(width: 30); // Placeholder for alignment
    }
    return CircleAvatar(
      radius: 15,
      backgroundColor: Colors.blue.shade300,
      backgroundImage: otherUserProfilePictureUrl != null
          ? NetworkImage(otherUserProfilePictureUrl)
          : null,
      child: otherUserProfilePictureUrl == null
          ? Text(
              widget.chat.otherUserName.isNotEmpty ? widget.chat.otherUserName[0].toUpperCase() : '',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            )
          : null,
    );
  }

  String _formatMessageTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final messageDate = DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (messageDate.isAtSameMomentAs(today)) {
      return DateFormat('HH:mm').format(timestamp.toLocal()); // E.g., '14:30'
    } else if (messageDate.isAtSameMomentAs(yesterday)) {
      return 'Yesterday, ${DateFormat('HH:mm').format(timestamp.toLocal())}';
    } else if (now.difference(messageDate).inDays < 7) {
      return DateFormat('EEE, HH:mm').format(timestamp.toLocal()); // E.g., 'Mon, 14:30'
    } else {
      return DateFormat('dd/MM/yyyy, HH:mm').format(timestamp.toLocal()); // E.g., '01/01/2026, 14:30'
    }
  }
}
