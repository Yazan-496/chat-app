import 'dart:async';
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
import 'package:my_chat_app/message_widget.dart';
import 'package:my_chat_app/services/local_storage_service.dart';
import 'package:my_chat_app/notification_service.dart';
import 'package:flutter/services.dart';
import 'package:my_chat_app/services/sound_service.dart';
import 'package:my_chat_app/supabase_client.dart'; // Import SupabaseManager
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_chat_app/utils/toast_utils.dart';

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
  bool _showEmojiPicker = false;
  int _emojiTabIndex = 0; // 0: Yazan, 1: Aline, 2: Both
  final LocalStorageService _localStorageService = LocalStorageService(); // New instance
  Timer? _statusUpdateTimer;
  RealtimeChannel? _statusChannel;
  bool _isConnected = true;
  bool _showRestoredMessage = false;
  Timer? _restoredMessageTimer;
  Timer? _connectionDebounceTimer;
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Voice recording state
  Timer? _recordingTimer;
  int _recordingDuration = 0;
  bool _isRecording = false;

  // New emoji reactions list
  final List<String> _emojiReactions = [
    '💋', '🌚', '🔫', '❤️', '💔', '🙂', '😒', '😡', '✂️', '😂',
  ];

  final List<String> _yazanEmojis = ['🙂', '😒', '🫠', '🙁', '😡', '😠', '✂️'];
  final List<String> _alineEmojis = ['😌', '🙁', '😠', '🤭', '🤫', '👻', '🤡', '🤏', '💋', '💄', '🤶', '🎅', '💏', '🥀', '🌝', '🌚', '🥂', '🔫', '❤️', '💔'];
  final List<String> _bothEmojis = [
    '😌', '🙁', '😠', '🤭', '🤫', '👻', '🤡', '🤏', '💋', '💄', '🤶', '🎅', '💏', '🥀', '🌝', '🌚', '🥂', '🔫', '❤️', '💔', '🙂', '😒', '🫠', '😡', '✂️', '👍', '😂', '😮', '😢', '🙏'
  ];

  @override
  void initState() {
    super.initState();
    _presenter = ChatPresenter(this, widget.chat);
    NotificationService.setActiveChatId(widget.chat.id);
    // Clear notifications for this chat when entering
    NotificationService.flutterLocalNotificationsPlugin.cancel(widget.chat.id.hashCode);
    NotificationService.flutterLocalNotificationsPlugin.cancel(widget.chat.id.hashCode + 1);
    _presenter.loadMessages();
    _presenter.scheduleReadMark();

    // Listen to Supabase connection status using a channel
    _statusChannel = _supabase.channel('chat_conn_tracker').subscribe((status, error) {
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

    _inputFocusNode.addListener(() {
      if (_inputFocusNode.hasFocus && _showEmojiPicker) {
        setState(() {
          _showEmojiPicker = false;
        });
      }
    });

    // Periodic timer to refresh "last seen" labels
    _statusUpdateTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        setState(() {
          // Trigger rebuild to update relative time
        });
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _inputFocusNode.dispose();
    _statusUpdateTimer?.cancel();
    _restoredMessageTimer?.cancel();
    _connectionDebounceTimer?.cancel();
    if (_statusChannel != null) {
      _supabase.removeChannel(_statusChannel!);
    }
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
    ToastUtils.showCustomToast(context, message);
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
    if (_isRecording) {
      _recordingTimer?.cancel();
      await _presenter.stopRecordingAndSend();
      setState(() {
        _isRecording = false;
        _recordingDuration = 0;
      });
    } else {
      await _presenter.startRecording();
      if (_presenter.isRecording) {
        setState(() {
          _isRecording = true;
          _recordingDuration = 0;
        });
        _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            _recordingDuration++;
          });
        });
      }
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
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
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _emojiReactions.map((emoji) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _presenter.addReaction(message.id, emoji);
                    },
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                );
              }).toList(),
            ),
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
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: true,
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
              Stack(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: widget.chat.avatarColor != null 
                        ? Color(widget.chat.avatarColor!) 
                        : Colors.blue.shade300,
                    backgroundImage: widget.chat.profilePictureUrl != null
                        ? NetworkImage(widget.chat.profilePictureUrl!)
                        : null,
                    child: widget.chat.profilePictureUrl == null
                        ? Text(
                            widget.chat.displayName.isNotEmpty ? widget.chat.displayName[0] : '',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                          )
                        : null,
                  ),
                  if (widget.chat.isActuallyOnline && _isConnected)
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
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.chat.displayName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  if (_isConnected)
                    if (_presenter.otherUserTyping && widget.chat.isActuallyOnline)
                      Text(
                        AppLocalizations.of(context).translate('typing'),
                        style: const TextStyle(fontSize: 12, color: Colors.white70),
                      )
                    else if (_presenter.otherUserInChat && widget.chat.isActuallyOnline)
                      const Text(
                        'In Chat',
                        style: TextStyle(fontSize: 12, color: Colors.white70),
                      )
                    else
                      Text(
                        widget.chat.isActuallyOnline ? 'Online' : _formatLastSeen(widget.chat.lastSeen),
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
          setState(() {
            _showEmojiPicker = false;
          });
          FocusManager.instance.primaryFocus?.unfocus();
          SystemChannels.textInput.invokeMethod('TextInput.hide');
        },
        child: Container(
        color: const Color(0xFF121212), // Solid dark background
        child: Column(
          children: [
            // No Internet Connection Banner
            if (!_isConnected)
              Container(
                width: double.infinity,
                color: Colors.redAccent.withOpacity(0.9),
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.wifi_off, color: Colors.white, size: 14),
                    SizedBox(width: 8),
                    Text(
                      'No internet connection',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

            // Connection Restored Banner
            if (_showRestoredMessage)
              Container(
                width: double.infinity,
                color: Colors.green.withOpacity(0.9),
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.white, size: 14),
                    SizedBox(width: 8),
                    Text(
                      'Connection restored',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

            // Spacer for AppBar since extendBodyBehindAppBar is true
            SizedBox(height: kToolbarHeight + MediaQuery.of(context).padding.top),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : RepaintBoundary(
                      child: ListView.separated(
                        reverse: true,
                        itemCount: _messages.length,
                        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                        cacheExtent: 1000, // Preload items for smoother scrolling
                        // Optimization: Use a separate widget for items to prevent full list rebuilds
                        itemBuilder: (context, index) {
                        final message = _messages[index];
                        final bool isMe = isCurrentUser(message.senderId);
                        final bool showAvatar = !isMe && (index == 0 || _messages[index - 1].senderId != message.senderId);

                        final widgets = <Widget>[];
                        final nextMsg = index > 0 ? _messages[index - 1] : null;
                        final needsHeader = _needsTimeHeader(message, nextMsg);
                        // if (needsHeader) {
                        //   widgets.add(
                        //     Padding(
                        //       padding: const EdgeInsets.symmetric(vertical: 8.0),
                        //       child: Center(
                        //         child: Container(
                        //           padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                        //           decoration: BoxDecoration(
                        //             color: Colors.grey.shade800,
                        //             borderRadius: BorderRadius.circular(16.0),
                        //           ),
                        //           // child: Text(
                        //           //   _formatHeader(message.timestamp),
                        //           //   style: const TextStyle(color: Colors.white70, fontSize: 12),
                        //           // ),
                        //         ),
                        //       ),
                        //     ),
                        //   );
                        // }
                        if (message.replyToMessageId != null) {
                          widgets.add(
                            Align(
                              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 4.0),
                                padding: const EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8.0),
                                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                                ),
                                child: InkWell(
                                  onTap: () => _scrollToMessage(message.replyToMessageId!),
                                  child: _buildReplyPreview(message.replyToMessageId!),
                                ),
                              ),
                            ),
                          );
                        }
                        widgets.add(
                          MessageItem(
                            key: _messageKeys.putIfAbsent(message.id, () => GlobalKey()),
                            message: message,
                            isMe: isMe,
                            showAvatar: showAvatar,
                            profilePictureUrl: widget.chat.profilePictureUrl,
                            avatarColor: widget.chat.avatarColor,
                            displayName: widget.chat.displayName,
                            isOnlyEmojis: _isOnlyEmojis(message.content) && message.type == MessageType.text,
                            onLongPress: _onMessageLongPress,
                            onDoubleTapReact: _showReactionPicker,
                            buildReplyPreview: _buildReplyPreview,
                            buildReactions: _buildReactions,
                            buildMessageStatus: _buildMessageStatusWidget,
                            onSwipeReply: (m) {
                              _presenter.selectMessageForReply(m);
                              _inputFocusNode.requestFocus();
                            },
                          ),
                        );
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: widgets,
                        );
                      },
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                    ),
                  ),
            ),
            if (replyingTo != null)
              _buildActiveReplyPreview(replyingTo),
            if (editingMessage != null)
              _buildActiveEditIndicator(editingMessage),
            _buildInputArea(),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              height: _showEmojiPicker ? 250 : 0,
              child: _showEmojiPicker ? _buildEmojiPicker() : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
      ),
    );
  }

  bool _needsTimeHeader(Message current, Message? next) {
    if (next == null) return true;
    final c = current.timestamp;
    final n = next.timestamp;
    return c.year != n.year ||
        c.month != n.month ||
        c.day != n.day ||
        c.hour != n.hour ||
        c.minute != n.minute;
  }

  String _formatHeader(DateTime dt) {
    return DateFormat('HH:mm').format(dt);
  }

  final Map<String, GlobalKey> _messageKeys = {};
  void _scrollToMessage(String messageId) {
    final key = _messageKeys[messageId];
    final ctx = key?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 300),
        alignment: 0.2,
        curve: Curves.easeInOut,
      );
    }
  }

  void _onMessageLongPress(Message message) async {
    final isMine = message.senderId == _presenter.currentUserId;
    final canEdit = isMine && message.type == MessageType.text && !message.deleted;
    final canDelete = isMine && !message.deleted;
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.reply, color: Colors.white),
                title: const Text('Reply', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _presenter.selectMessageForReply(message);
                },
              ),
              ListTile(
                leading: const Icon(Icons.emoji_emotions, color: Colors.white),
                title: const Text('React', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _showReactionPicker(message);
                },
              ),
              if (canEdit)
                ListTile(
                  leading: const Icon(Icons.edit, color: Colors.white),
                  title: const Text('Edit', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    _presenter.selectMessageForEdit(message);
                    _messageController.text = message.editedContent ?? message.content;
                    _inputFocusNode.requestFocus();
                  },
                ),
              if (canDelete)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Delete', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _presenter.deleteMessage(message);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  String _formatLastSeen(DateTime? lastSeen) {
    if (lastSeen == null) return 'Offline';
    final now = DateTime.now();
    final difference = now.difference(lastSeen);
    
    if (difference.inSeconds < 30) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes < 1 ? 1 : difference.inMinutes;
      return 'Last seen ${minutes}m ago';
    } else if (difference.inHours < 24) {
      return 'Last seen ${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return 'Last seen ${difference.inDays}d ago';
    } else {
      return 'Last seen ${DateFormat('MMM d').format(lastSeen)}';
    }
  }

  Widget _buildReplyPreview(String messageId) {
    final message = _presenter.getMessageById(messageId);
    if (message == null) {
      return const Text('Message not found', style: TextStyle(color: Colors.white70, fontSize: 12));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          message.senderId == _presenter.currentUserId ? 'You' : widget.chat.displayName,
          style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          message.deleted ? 'Removed message' : (message.editedContent ?? message.content),
          style: TextStyle(
            color: message.deleted ? Colors.white54 : Colors.white70,
            fontSize: 12,
            fontStyle: message.deleted ? FontStyle.italic : FontStyle.normal,
            decoration: message.deleted ? TextDecoration.lineThrough : TextDecoration.none,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildReactions(Map<String, String> reactions) {
    if (reactions.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: reactions.values.map((emoji) {
          return Text(emoji, style: const TextStyle(fontSize: 14));
        }).toList(),
      ),
    );
  }

  Widget _buildMessageStatusWidget(Message message, bool isMe) {
    if (!isMe) return const SizedBox.shrink();
    IconData icon;
    Color color;
    switch (message.status) {
      case MessageStatus.sending:
        icon = Icons.access_time;
        color = Colors.white54;
        break;
      case MessageStatus.sent:
        icon = Icons.check;
        color = Colors.white54;
        break;
      case MessageStatus.delivered:
        icon = Icons.done_all;
        color = Colors.white54;
        break;
      case MessageStatus.read:
        icon = Icons.done_all;
        color = Colors.blue;
        break;
    }
    return Icon(icon, size: 14, color: color);
  }

  Widget _buildActiveReplyPreview(Message message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey.shade900,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Replying to',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  message.deleted ? 'Removed message' : (message.editedContent ?? message.content),
                  style: TextStyle(
                    color: message.deleted ? Colors.white54 : Colors.white,
                    fontSize: 14,
                    fontStyle: message.deleted ? FontStyle.italic : FontStyle.normal,
                    decoration: message.deleted ? TextDecoration.lineThrough : TextDecoration.none,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white70),
            onPressed: () => _presenter.cancelReply(),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveEditIndicator(Message message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.blue.shade900.withOpacity(0.3),
      child: Row(
        children: [
          const Icon(Icons.edit, color: Colors.blue, size: 16),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Editing message',
              style: TextStyle(color: Colors.blue, fontSize: 14),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.blue),
            onPressed: () => _presenter.cancelEdit(),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: _isRecording ? _buildRecordingUI() : _buildNormalInputUI(),
    );
  }

  Widget _buildRecordingUI() {
    return Row(
      children: [
        const SizedBox(width: 8),
        Icon(Icons.mic, color: Colors.red.shade400, size: 28),
        const SizedBox(width: 12),
        Text(
          _formatDuration(_recordingDuration),
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 15),
        const Expanded(
          child: Text(
            'Recording...',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ),
        TextButton(
          onPressed: () async {
            _recordingTimer?.cancel();
            await _presenter.stopRecordingAndCancel(); // Need to implement this in presenter
            setState(() {
              _isRecording = false;
              _recordingDuration = 0;
            });
          },
          child: const Text('Cancel', style: TextStyle(color: Colors.red)),
        ),
        IconButton(
          icon: const Icon(Icons.send, color: Colors.purpleAccent, size: 28),
          onPressed: _toggleRecording,
        ),
      ],
    );
  }

  Widget _buildNormalInputUI() {
    return Row(
      children: [
        IconButton(
          icon: Icon(
            _showEmojiPicker ? Icons.keyboard : Icons.emoji_emotions,
            color: Colors.white70,
          ),
          onPressed: () {
            if (_showEmojiPicker) {
              _inputFocusNode.requestFocus();
            } else {
              _inputFocusNode.unfocus();
              SystemChannels.textInput.invokeMethod('TextInput.hide');
              setState(() {
                _showEmojiPicker = true;
              });
            }
          },
        ),
        Expanded(
          child: TextField(
            controller: _messageController,
            focusNode: _inputFocusNode,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: _presenter.selectedMessageForEdit != null
                  ? 'Edit message...'
                  : _presenter.selectedMessageForReply != null
                      ? 'Reply to message...'
                      : 'Type a message...',
              hintStyle: const TextStyle(color: Colors.white54),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey.shade800,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onChanged: (text) {
              _presenter.notifyTyping(text.isNotEmpty);
            },
            onSubmitted: (text) {
              if (text.trim().isNotEmpty) {
                _sendMessage();
              }
            },
          ),
        ),
        IconButton(
          icon: const Icon(Icons.attach_file, color: Colors.white70),
          onPressed: _showImageSourceSelection,
        ),
        IconButton(
          icon: const Icon(Icons.mic, color: Colors.white70),
          onPressed: _toggleRecording,
        ),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _messageController,
          builder: (context, value, child) {
            final isNotEmpty = value.text.trim().isNotEmpty;
            return IconButton(
              icon: isNotEmpty 
                ? const Icon(Icons.send, color: Colors.purpleAccent)
                : const Text('🌝', style: TextStyle(fontSize: 24)),
              onPressed: () {
                if (isNotEmpty) {
                  _sendMessage();
                } else {
                  _messageController.text = '🌝';
                  _sendMessage();
                }
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmojiPicker() {
    List<String> currentEmojis;
    switch (_emojiTabIndex) {
      case 0:
        currentEmojis = _yazanEmojis;
        break;
      case 1:
        currentEmojis = _alineEmojis;
        break;
      case 2:
      default:
        currentEmojis = _bothEmojis;
        break;
    }

    return Container(
      height: 250,
      color: Colors.grey.shade900,
      child: Column(
        children: [
          Container(
            height: 50,
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white10)),
            ),
            child: Row(
              children: [
                _buildEmojiTab(0, 'Yazan'),
                _buildEmojiTab(1, 'Aline'),
                _buildEmojiTab(2, 'Both'),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                childAspectRatio: 1,
              ),
              itemCount: currentEmojis.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    _messageController.text += currentEmojis[index];
                    _presenter.notifyTyping(true);
                  },
                  child: Center(
                    child: Text(
                      currentEmojis[index],
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmojiTab(int index, String label) {
    final isSelected = _emojiTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _emojiTabIndex = index;
          });
        },
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? Colors.purpleAccent : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.purpleAccent : Colors.white70,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}