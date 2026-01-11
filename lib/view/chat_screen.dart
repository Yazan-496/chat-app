import 'package:flutter/material.dart';
import 'package:my_chat_app/model/chat.dart';
import 'package:my_chat_app/model/message.dart';
import 'package:my_chat_app/presenter/chat_presenter.dart';
import 'package:my_chat_app/view/chat_view.dart';
import 'package:my_chat_app/view/voice_message_player.dart'; // New import
import 'package:my_chat_app/model/relationship.dart'; // Import for RelationshipExtension
import 'package:image_picker/image_picker.dart'; // Import for ImageSource

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
        title: Text(widget.chat.otherUserName),
        backgroundColor: widget.chat.relationshipType.primaryColor,
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
                              Container(
                                margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                padding: widget.chat.relationshipType.chatBubblePadding,
                                decoration: BoxDecoration(
                                  color: isCurrentUser(message.senderId)
                                      ? widget.chat.relationshipType.primaryColor
                                      : widget.chat.relationshipType.accentColor,
                                  borderRadius: widget.chat.relationshipType.chatBubbleRadius,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (message.type == MessageType.text)
                                      Text(
                                        message.editedContent ?? message.content,
                                        style: TextStyle(color: widget.chat.relationshipType.textColor),
                                      ),
                                    if (message.type == MessageType.image)
                                      Image.network(message.content, width: 200), // Display image
                                    if (message.type == MessageType.voice)
                                      VoiceMessagePlayer(
                                        audioUrl: message.content,
                                        backgroundColor: isCurrentUser(message.senderId)
                                            ? widget.chat.relationshipType.primaryColor
                                            : widget.chat.relationshipType.accentColor,
                                        textColor: widget.chat.relationshipType.textColor,
                                      ), // Voice message player
                                    const SizedBox(height: 4.0),
                                    _buildMessageStatusWidget(message, isCurrentUser(message.senderId)),
                                    if (message.reactions.isNotEmpty)
                                      _buildReactions(message.reactions),
                                  ],
                                ),
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

  Widget _buildMessageStatusWidget(Message message, bool isCurrentUser) {
    final formattedTime = '${message.timestamp.toLocal().hour.toString().padLeft(2, '0')}:${message.timestamp.toLocal().minute.toString().padLeft(2, '0')}';

    if (!isCurrentUser) {
      return Text(
        formattedTime,
        style: TextStyle(fontSize: 10, color: widget.chat.relationshipType.textColor.withOpacity(0.7)),
      );
    }

    // For outgoing messages, display status icons and timestamp
    IconData iconData;
    Color iconColor = widget.chat.relationshipType.textColor.withOpacity(0.7);

    switch (message.status) {
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
        iconColor = widget.chat.relationshipType.primaryColor; // Different color for read
        break;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          formattedTime,
          style: TextStyle(fontSize: 10, color: widget.chat.relationshipType.textColor.withOpacity(0.7)),
        ),
        const SizedBox(width: 4),
        Icon(
          iconData,
          size: 14,
          color: iconColor,
        ),
      ],
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
            style: const TextStyle(fontSize: 12)),
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
}
