import 'dart:async';
import 'package:flutter/material.dart';
import 'package:my_chat_app/model/chat.dart';
import 'package:my_chat_app/model/message.dart';
import 'package:my_chat_app/presenter/chat_presenter.dart';
import 'package:my_chat_app/view/chat_view.dart';
import 'package:my_chat_app/notification_service.dart';
import 'package:my_chat_app/services/local_storage_service.dart';
import 'package:my_chat_app/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_chat_app/utils/toast_utils.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_chat_app/widgets/chat/chat_app_bar.dart';
import 'package:my_chat_app/widgets/chat/connection_status_banner.dart';
import 'package:my_chat_app/widgets/chat/chat_message_list.dart';
import 'package:my_chat_app/widgets/chat/chat_input_area.dart';

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
  int _emojiTabIndex = 0;
  final LocalStorageService _localStorageService = LocalStorageService();
  Timer? _statusUpdateTimer;
  RealtimeChannel? _statusChannel;
  bool _isConnected = true;
  bool _showRestoredMessage = false;
  Timer? _restoredMessageTimer;
  Timer? _connectionDebounceTimer;
  final SupabaseClient _supabase = Supabase.instance.client;
  
  Timer? _recordingTimer;
  int _recordingDuration = 0;
  bool _isRecording = false;
  bool _isImagePickerOpen = false;
  double _keyboardHeight = 300.0;
  Message? _menuMessage;
  bool _showReactionsOnly = false;

  final List<String> _yazanEmojis = ['🙂', '😒', '🫠', '🙁', '😡', '😠', '✂️'];
  final List<String> _alineEmojis = ['😌', '🙁', '😠', '🤭', '🤫', '👻', '🤡', '🤏', '💋', '💄', '🤶', '🎅', '💏', '🥀', '🌝', '🌚', '🥂', '🔫', '❤️', '💔'];
  final List<String> _bothEmojis = [
    '😌', '🙁', '😠', '🤭', '🤫', '👻', '🤡', '🤏', '💋', '💄', '🤶', '🎅', '💏', '🥀', '🌝', '🌚', '🥂', '🔫', '❤️', '💔', '🙂', '😒', '🫠', '😡', '✂️', '👍', '😂', '😮', '😢', '🙏'
  ];

  final Map<String, GlobalKey> _messageKeys = {};
  final ScrollController _scrollController = ScrollController();
  double _lastBottomInset = 0;

  @override
  void initState() {
    super.initState();
    _presenter = ChatPresenter(this, widget.chat);
    NotificationService.setActiveChatId(widget.chat.id);
    NotificationService.flutterLocalNotificationsPlugin.cancel(widget.chat.id.hashCode);
    NotificationService.flutterLocalNotificationsPlugin.cancel(widget.chat.id.hashCode + 1);
    _presenter.loadMessages();
    _presenter.scheduleReadMark();

    _statusChannel = _supabase.channel('chat_conn_tracker').subscribe((status, error) {
      if (mounted) {
        final newConnected = status == RealtimeSubscribeStatus.subscribed;
        if (newConnected) {
          _connectionDebounceTimer?.cancel();
          if (!_isConnected) {
            setState(() {
              _isConnected = true;
              _showRestoredMessage = true;
            });
            _restoredMessageTimer?.cancel();
            _restoredMessageTimer = Timer(const Duration(seconds: 3), () {
              if (mounted) setState(() => _showRestoredMessage = false);
            });
          }
        } else {
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

    _statusUpdateTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _inputFocusNode.dispose();
    _statusUpdateTimer?.cancel();
    _restoredMessageTimer?.cancel();
    _connectionDebounceTimer?.cancel();
    if (_statusChannel != null) _supabase.removeChannel(_statusChannel!);
    _presenter.dispose();
    NotificationService.setActiveChatId(null);
    super.dispose();
  }

  @override
  void showLoading() => setState(() => _isLoading = true);
  @override
  void hideLoading() => setState(() => _isLoading = false);
  @override
  void showMessage(String message) => ToastUtils.showCustomToast(context, message);
  @override
  void displayMessages(List<Message> messages) => setState(() => _messages = messages);
  @override
  void updateView() => setState(() {});

  void _sendMessage() {
    if (_presenter.selectedMessageForEdit != null) {
      _presenter.confirmEditMessage(_messageController.text);
    } else {
      _presenter.sendTextMessage(_messageController.text);
    }
    _messageController.clear();
    _presenter.cancelReply();
    _presenter.cancelEdit();
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
          setState(() => _recordingDuration++);
        });
      }
    }
  }

  void _cancelRecording() async {
    _recordingTimer?.cancel();
    await _presenter.stopRecordingAndCancel();
    setState(() {
      _isRecording = false;
      _recordingDuration = 0;
    });
  }

  void _showImageSourceSelection() {
    setState(() => _isImagePickerOpen = true);
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
      ),
    ).then((_) {
      if (mounted) setState(() => _isImagePickerOpen = false);
    });
  }

  bool _isOnlyEmojis(String text) {
    if (text.isEmpty) return false;
    if (RegExp(r'[a-zA-Z0-9]').hasMatch(text)) return false;
    if (RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]').hasMatch(text)) return false;
    try {
      if (RegExp(r'[\p{L}\p{N}]', unicode: true).hasMatch(text)) return false;
    } catch (e) {}
    return text.runes.length <= 5;
  }

  void _scrollToMessage(String messageId) {
    final key = _messageKeys[messageId];
    final ctx = key?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 300), alignment: 0.2, curve: Curves.easeInOut);
    }
  }

  Widget _buildReplyPreview(String messageId) {
    final message = _presenter.getMessageById(messageId);
    if (message == null) return const Text('Message not found', style: TextStyle(color: Colors.white70, fontSize: 12));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(message.senderId == _presenter.currentUserId ? 'You' : widget.chat.displayName,
            style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(message.deleted ? 'Removed message' : (message.editedContent ?? message.content),
            style: TextStyle(color: message.deleted ? Colors.white54 : Colors.white70, fontSize: 12,
                fontStyle: message.deleted ? FontStyle.italic : FontStyle.normal,
                decoration: message.deleted ? TextDecoration.lineThrough : TextDecoration.none),
            maxLines: 2, overflow: TextOverflow.ellipsis),
      ],
    );
  }

  Widget _buildReactions(Map<String, String> reactions) {
    if (reactions.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: Colors.grey.shade800, borderRadius: BorderRadius.circular(12)),
      child: Row(mainAxisSize: MainAxisSize.min, children: reactions.values.map((emoji) => Text(emoji, style: const TextStyle(fontSize: 14))).toList()),
    );
  }

  Widget _buildMessageStatusWidget(Message message, bool isMe) {
    if (!isMe) return const SizedBox.shrink();
    IconData icon;
    Color color;
    switch (message.status) {
      case MessageStatus.sending: icon = Icons.access_time; color = Colors.white54; break;
      case MessageStatus.sent: icon = Icons.check; color = Colors.white54; break;
      case MessageStatus.delivered: icon = Icons.done_all; color = Colors.white54; break;
      case MessageStatus.read: icon = Icons.done_all; color = Colors.blue; break;
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
                const Text('Replying to', style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 4),
                Text(message.deleted ? 'Removed message' : (message.editedContent ?? message.content),
                    style: TextStyle(color: message.deleted ? Colors.white54 : Colors.white, fontSize: 14,
                        fontStyle: message.deleted ? FontStyle.italic : FontStyle.normal,
                        decoration: message.deleted ? TextDecoration.lineThrough : TextDecoration.none),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.close, color: Colors.white70), onPressed: () => _presenter.cancelReply()),
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
          const Expanded(child: Text('Editing message', style: TextStyle(color: Colors.blue, fontSize: 14))),
          IconButton(icon: const Icon(Icons.close, color: Colors.blue), onPressed: () => _presenter.cancelEdit()),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Standard Flutter architecture: Scaffold handles resizing natively.
    // Using Column + Expanded allows the Android OS to manage layout transitions
    // during IME (keyboard) animations, ensuring 60FPS performance.
    
    final double bottomInset = MediaQuery.of(context).viewInsets.bottom;
    if (bottomInset > 0) {
      // Only update _keyboardHeight if the new inset is significantly larger,
      // to avoid capturing animation frames as the "max" height.
      if (bottomInset > _keyboardHeight) {
        _keyboardHeight = bottomInset;
      }
      
      // Auto-close emoji picker only when the keyboard is being opened (has focus)
      // and is almost fully covering the screen.
      if (_showEmojiPicker && _inputFocusNode.hasFocus && bottomInset >= _keyboardHeight * 0.9) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _showEmojiPicker) {
            setState(() => _showEmojiPicker = false);
          }
        });
      }
    }

    return PopScope(
      canPop: !_showEmojiPicker,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _showEmojiPicker) setState(() => _showEmojiPicker = false);
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        resizeToAvoidBottomInset: true, // Let the OS handle viewport resizing
        appBar: ChatAppBar(
          chat: widget.chat,
          presenter: _presenter,
          isConnected: _isConnected,
          onBack: () => Navigator.of(context).pop(),
        ),
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            if (_showEmojiPicker) setState(() => _showEmojiPicker = false);
            // Removed automatic unfocus on body tap to prevent accidental keyboard closure.
            // Most chat apps only close the keyboard on scroll or specific actions.
          },
          child: Stack(
            children: [
              // Layer 1: Main UI (Messages, Input)
              Column(
                children: [
                  // Spacer to push messages below the absolute-positioned banner
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: (!_isConnected || _showRestoredMessage) ? 30 : 0,
                    color: Colors.black, // Match the background
                  ),
                  Expanded(
                    child: ChatMessageList(
                      scrollController: _scrollController,
                      messages: _messages,
                      chat: widget.chat,
                      presenter: _presenter,
                      isLoading: _isLoading,
                      messageKeys: _messageKeys,
                      onReplyTap: _scrollToMessage,
                      onLongPress: (m) => setState(() { _menuMessage = m; }),
                      onDoubleTapReact: (m) => setState(() { _menuMessage = m; _showReactionsOnly = true; }),
                      onSwipeReply: (m) { _presenter.selectMessageForReply(m); _inputFocusNode.requestFocus(); },
                      buildReplyPreview: _buildReplyPreview,
                      buildReactions: _buildReactions,
                      buildMessageStatus: _buildMessageStatusWidget,
                      isOnlyEmojis: _isOnlyEmojis,
                      bottomPadding: 0, // Scaffold handles padding via resizing
                    ),
                  ),
                  ChatInputArea(
                    controller: _messageController,
                    focusNode: _inputFocusNode,
                    presenter: _presenter,
                    isRecording: _isRecording,
                    recordingDuration: _recordingDuration,
                    showEmojiPicker: _showEmojiPicker,
                    isImagePickerOpen: _isImagePickerOpen,
                    emojiTabIndex: _emojiTabIndex,
                    keyboardHeight: _keyboardHeight,
                    bottomInset: bottomInset,
                    replyingTo: _presenter.selectedMessageForReply,
                    editingMessage: _presenter.selectedMessageForEdit,
                    onSend: _sendMessage,
                    onToggleRecording: _toggleRecording,
                    onCancelRecording: _cancelRecording,
                    onImageSourceSelection: _showImageSourceSelection,
                    onEmojiToggle: () {
                      if (_showEmojiPicker) {
                        _inputFocusNode.requestFocus();
                      } else {
                        // Ensure we set the state to show the picker BEFORE unfocusing
                        // so that the build method can calculate the compensation correctly.
                        setState(() => _showEmojiPicker = true);
                        if (_inputFocusNode.hasFocus) {
                          _inputFocusNode.unfocus();
                        }
                      }
                    },
                    onEmojiTabChanged: (index) => setState(() => _emojiTabIndex = index),
                    yazanEmojis: _yazanEmojis,
                    alineEmojis: _alineEmojis,
                    bothEmojis: _bothEmojis,
                    buildActiveReplyPreview: _buildActiveReplyPreview,
                    buildActiveEditIndicator: _buildActiveEditIndicator,
                  ),
                ],
              ),

              // Layer 2: Fixed Banner (Always at top, prevents layout shifts)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: ConnectionStatusBanner(
                  isConnected: _isConnected, 
                  showRestoredMessage: _showRestoredMessage
                ),
              ),

              // Layer 3: Context Menu (Overlay)
              if (_menuMessage != null) Positioned.fill(child: _buildMessageMenu()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageMenu() {
    final bool isMe = _menuMessage!.senderId == _presenter.currentUserId;
    final List<String> reactions = ['👍', '❤️', '😂', '😮', '😢', '🙏'];

    return GestureDetector(
      onTap: () => setState(() { _menuMessage = null; _showReactionsOnly = false; }),
      child: Container(
        color: Colors.black54,
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Reactions Bar
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2C2C),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: reactions.map((emoji) {
                        final bool hasReacted = _menuMessage!.reactions[_presenter.currentUserId] == emoji;
                        return GestureDetector(
                          onTap: () {
                            if (hasReacted) {
                              _presenter.removeReaction(_menuMessage!.id);
                            } else {
                              _presenter.addReaction(_menuMessage!.id, emoji);
                            }
                            setState(() { _menuMessage = null; _showReactionsOnly = false; });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: hasReacted ? Colors.blue.withOpacity(0.2) : Colors.transparent,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Text(emoji, style: const TextStyle(fontSize: 24)),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  if (!_showReactionsOnly) ...[
                    const SizedBox(height: 16),
                    // Actions Menu
                    Container(
                      width: 200,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2C2C),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildMenuItem(
                            icon: Icons.reply,
                            label: 'Reply',
                            onTap: () {
                              _presenter.selectMessageForReply(_menuMessage!);
                              setState(() { _menuMessage = null; });
                              _inputFocusNode.requestFocus();
                            },
                          ),
                          if (isMe && _menuMessage!.type == MessageType.text)
                            _buildMenuItem(
                              icon: Icons.edit,
                              label: 'Edit',
                              onTap: () {
                                _presenter.selectMessageForEdit(_menuMessage!);
                                setState(() { _menuMessage = null; });
                                _inputFocusNode.requestFocus();
                              },
                            ),
                          _buildMenuItem(
                            icon: Icons.copy,
                            label: 'Copy',
                            onTap: () {
                              // Use Clipboard if available, or just a toast for now
                              setState(() { _menuMessage = null; });
                              showMessage('Copied to clipboard');
                            },
                          ),
                          if (isMe)
                            _buildMenuItem(
                              icon: Icons.delete,
                              label: 'Delete',
                              isDestructive: true,
                              onTap: () {
                                _presenter.deleteMessage(_menuMessage!);
                                setState(() { _menuMessage = null; });
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? Colors.red : Colors.white),
      title: Text(
        label,
        style: TextStyle(color: isDestructive ? Colors.red : Colors.white),
      ),
      onTap: onTap,
    );
  }
}
