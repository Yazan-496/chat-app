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
  bool _isExpanded = false;
  double _keyboardHeight = 250.0;
  Message? _menuMessage;
  bool _showReactionsOnly = false;

  // New emoji reactions list
  final List<String> _emojiReactions = [
    '💋', '🌚', '🔫', '❤️', '💔', '🙂', '😒', '😡', '✂️', '😂',
  ];

  final List<String> _yazanEmojis = ['🙂', '😒', '🫠', '🙁', '😡', '😠', '✂️'];
  final List<String> _alineEmojis = ['😌', '🙁', '😠', '🤭', '🤫', '👻', '🤡', '🤏', '💋', '💄', '🤶', '🎅', '💏', '🥀', '🌝', '🌚', '🥂', '🔫', '❤️', '💔'];
  final List<String> _bothEmojis = [
    '😌', '🙁', '😠', '🤭', '🤫', '👻', '🤡', '🤏', '💋', '💄', '🤶', '🎅', '💏', '🥀', '🌝', '🌚', '🥂', '🔫', '❤️', '💔', '🙂', '😒', '🫠', '😡', '✂️', '👍', '😂', '😮', '😢', '🙏'
  ];

  final GlobalKey<State> _textFieldKey = GlobalKey();

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
    setState(() {
      _menuMessage = message;
      _showReactionsOnly = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isCurrentUser = (senderId) => senderId == _presenter.currentUserId;
    final replyingTo = _presenter.selectedMessageForReply;
    final editingMessage = _presenter.selectedMessageForEdit;
    final theme = Theme.of(context);

    if (MediaQuery.of(context).viewInsets.bottom > 0) {
      _keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    }

    return PopScope(
      canPop: !_showEmojiPicker,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _showEmojiPicker) {
          setState(() {
            _showEmojiPicker = false;
          });
        }
      },
      child: Scaffold(
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
          if (_showEmojiPicker) {
            setState(() {
              _showEmojiPicker = false;
            });
          }
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
                            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
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
            SizedBox(
              height: _showEmojiPicker ? _keyboardHeight : (MediaQuery.of(context).viewInsets.bottom > 0 ? _keyboardHeight : 0),
              child: _showEmojiPicker ? _buildEmojiPicker() : null,
            ),
            // Extra padding for bottom safe area when no keyboard/emoji picker is shown
            if (!_showEmojiPicker && MediaQuery.of(context).viewInsets.bottom == 0)
              SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
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

  void _onMessageLongPress(Message message) {
    setState(() {
      _menuMessage = message;
      _showReactionsOnly = false;
    });
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
      padding: const EdgeInsets.only(left: 8, right: 8, top: 4, bottom: 18),
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
      child: Stack(
        children: [
          // Normal Input UI - always in tree to keep keyboard/focus
          Visibility(
            visible: !_isRecording,
            maintainState: true,
            child: _buildNormalInputUI(),
          ),
          // Recording UI - overlays when recording
          if (_isRecording)
            _buildRecordingUI(),
        ],
      ),
    );
  }

  Widget _buildNormalInputUI() {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _messageController,
      builder: (context, value, child) {
        final isTyping = value.text.isNotEmpty;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Stable leading icons section
            IconButton(
              icon: Icon(_isExpanded ? Icons.arrow_back_ios : Icons.arrow_forward_ios, color: Colors.pink, size: 22),
              onPressed: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
            ),
            
            if (_isExpanded) ...[
              IconButton(
                icon: const Icon(Icons.image, color: Colors.pink, size: 24),
                onPressed: _showImageSourceSelection,
              ),
              IconButton(
                icon: const Icon(Icons.mic_rounded, color: Colors.pink, size: 24),
                onPressed: _toggleRecording,
              ),
            ],

            // Text field with GlobalKey for focus stability
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxHeight: 200,
                        ),
                        child: TextField(
                          key: _textFieldKey,
                          controller: _messageController,
                          focusNode: _inputFocusNode,
                          maxLines: null,
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                          decoration: const InputDecoration(
                            hintText: 'Message',
                            hintStyle: TextStyle(color: Colors.white54),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 10),
                          ),
                          onChanged: (text) {
                            if (_showEmojiPicker) {
                              setState(() {
                                _showEmojiPicker = false;
                              });
                            }
                            // Don't auto-collapse if we want to avoid blips, 
                            // but usually icons hide when typing.
                            if (text.isNotEmpty && _isExpanded) {
                              setState(() {
                                _isExpanded = false;
                              });
                            }
                            _presenter.notifyTyping(text.isNotEmpty);
                          },
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.emoji_emotions_rounded, color: Colors.pink, size: 24),
                      onPressed: () {
                        if (_showEmojiPicker) {
                          _inputFocusNode.requestFocus();
                        } else {
                          // Note: To keep keyboard open, we DON'T unfocus.
                          // But if we show emoji picker, they usually overlap.
                          // User said: "closing keyboard mustt only user close it"
                          setState(() {
                            _showEmojiPicker = !_showEmojiPicker;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            // Send button or Quick Reaction
            Padding(
              padding: const EdgeInsets.only(bottom: 4, left: 4),
              child: isTyping
                  ? IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.pink, size: 28),
                      onPressed: _sendMessage,
                    )
                  : InkWell(
                      onTap: () {
                        _messageController.text = '🌝';
                        _sendMessage();
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('🌝', style: TextStyle(fontSize: 28)),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecordingUI() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.delete_rounded, color: Colors.pink, size: 28),
          onPressed: () async {
            _recordingTimer?.cancel();
            await _presenter.stopRecordingAndCancel();
            setState(() {
              _isRecording = false;
              _recordingDuration = 0;
            });
          },
        ),
        Expanded(
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.pink,
              borderRadius: BorderRadius.circular(25),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.pause_rounded, color: Colors.pink, size: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          30,
                          (index) => Container(
                            width: 3,
                            height: 3,
                            margin: const EdgeInsets.symmetric(horizontal: 1.5),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    _formatDuration(_recordingDuration),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.send_rounded, color: Colors.pink, size: 28),
          onPressed: _toggleRecording,
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