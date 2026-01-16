import 'package:flutter/material.dart';
import 'package:my_chat_app/presenter/chat_presenter.dart';
import 'package:my_chat_app/model/message.dart';

class ChatInputArea extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ChatPresenter presenter;
  final bool isRecording;
  final int recordingDuration;
  final bool showEmojiPicker;
  final int emojiTabIndex;
  final double keyboardHeight;
  final double bottomInset;
  final Message? replyingTo;
  final Message? editingMessage;
  final VoidCallback onSend;
  final VoidCallback onToggleRecording;
  final VoidCallback onCancelRecording;
  final VoidCallback onImageSourceSelection;
  final VoidCallback onEmojiToggle;
  final Function(int) onEmojiTabChanged;
  final List<String> yazanEmojis;
  final List<String> alineEmojis;
  final List<String> bothEmojis;
  final Widget Function(Message) buildActiveReplyPreview;
  final Widget Function(Message) buildActiveEditIndicator;

  const ChatInputArea({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.presenter,
    required this.isRecording,
    required this.recordingDuration,
    required this.showEmojiPicker,
    required this.emojiTabIndex,
    required this.keyboardHeight,
    required this.bottomInset,
    required this.replyingTo,
    required this.editingMessage,
    required this.onSend,
    required this.onToggleRecording,
    required this.onCancelRecording,
    required this.onImageSourceSelection,
    required this.onEmojiToggle,
    required this.onEmojiTabChanged,
    required this.yazanEmojis,
    required this.alineEmojis,
    required this.bothEmojis,
    required this.buildActiveReplyPreview,
    required this.buildActiveEditIndicator,
  });

  @override
  State<ChatInputArea> createState() => _ChatInputAreaState();
}

class _ChatInputAreaState extends State<ChatInputArea> {
  bool _isExpanded = false;
  final GlobalKey _textFieldKey = GlobalKey();

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // The emoji picker should occupy the same space as the keyboard.
    // When the keyboard is animating, we compensate for the changing bottomInset
    // to keep the input area at a stable vertical position.
    final double emojiPickerHeight = widget.showEmojiPicker ? widget.keyboardHeight : 0;
    final double effectiveBottomPadding = (emojiPickerHeight - widget.bottomInset).clamp(0.0, widget.keyboardHeight);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.replyingTo != null) widget.buildActiveReplyPreview(widget.replyingTo!),
        if (widget.editingMessage != null) widget.buildActiveEditIndicator(widget.editingMessage!),
        Container(
          padding: const EdgeInsets.only(left: 8, right: 8, top: 4, bottom: 8),
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
              Visibility(
                visible: !widget.isRecording,
                maintainState: true,
                child: Opacity(
                  opacity: widget.isRecording ? 0.0 : 1.0,
                  child: IgnorePointer(
                    ignoring: widget.isRecording,
                    child: _buildNormalInputUI(),
                  ),
                ),
              ),
              if (widget.isRecording) _buildRecordingUI(),
            ],
          ),
        ),
        // This SizedBox acts as the placeholder for either the emoji picker or the keyboard space.
        // It shrinks as the keyboard (bottomInset) grows, and expands as the keyboard closes.
        if (widget.showEmojiPicker || effectiveBottomPadding > 0)
          SizedBox(
            height: effectiveBottomPadding,
            child: widget.showEmojiPicker ? _buildEmojiPicker() : const SizedBox.shrink(),
          ),
      ],
    );
  }

  Widget _buildNormalInputUI() {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: widget.controller,
      builder: (context, value, child) {
        final isTyping = value.text.isNotEmpty;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              icon: Icon(_isExpanded ? Icons.arrow_back_ios : Icons.arrow_forward_ios,
                  color: Colors.pink, size: 22),
              onPressed: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
            ),
            if (_isExpanded) ...[
              IconButton(
                focusNode: FocusNode(canRequestFocus: false),
                icon: const Icon(Icons.image, color: Colors.pink, size: 24),
                onPressed: widget.onImageSourceSelection,
              ),
              IconButton(
                focusNode: FocusNode(canRequestFocus: false),
                icon: const Icon(Icons.mic_rounded, color: Colors.pink, size: 24),
                onPressed: widget.onToggleRecording,
              ),
            ],
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
                          controller: widget.controller,
                          focusNode: widget.focusNode,
                          maxLines: null,
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                          decoration: const InputDecoration(
                            hintText: 'Message',
                            hintStyle: TextStyle(color: Colors.white54),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 10),
                          ),
                          onChanged: (text) {
                            if (text.isNotEmpty && _isExpanded) {
                              setState(() {
                                _isExpanded = false;
                              });
                            }
                            widget.presenter.notifyTyping(text.isNotEmpty);
                          },
                        ),
                      ),
                    ),
                    IconButton(
                      focusNode: FocusNode(canRequestFocus: false),
                      icon: Icon(
                          widget.showEmojiPicker
                              ? Icons.keyboard_rounded
                              : Icons.emoji_emotions_rounded,
                          color: Colors.pink,
                          size: 24),
                      onPressed: widget.onEmojiToggle,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 4, left: 4),
              child: isTyping
                  ? IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.pink, size: 28),
                      onPressed: widget.onSend,
                    )
                  : InkWell(
                      onTap: () {
                        widget.controller.text = '🌝';
                        widget.onSend();
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
          focusNode: FocusNode(canRequestFocus: false),
          icon: const Icon(Icons.delete_rounded, color: Colors.pink, size: 28),
          onPressed: widget.onCancelRecording,
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
                    _formatDuration(widget.recordingDuration),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
        IconButton(
          focusNode: FocusNode(canRequestFocus: false),
          icon: const Icon(Icons.send_rounded, color: Colors.pink, size: 28),
          onPressed: widget.onToggleRecording,
        ),
      ],
    );
  }

  Widget _buildEmojiPicker() {
    List<String> currentEmojis;
    switch (widget.emojiTabIndex) {
      case 0:
        currentEmojis = widget.yazanEmojis;
        break;
      case 1:
        currentEmojis = widget.alineEmojis;
        break;
      case 2:
      default:
        currentEmojis = widget.bothEmojis;
        break;
    }

    return Container(
      color: Colors.grey.shade900,
      child: Column(
        children: [
          Container(
            height: 50,
            decoration: const BoxDecoration(
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
                    widget.controller.text += currentEmojis[index];
                    widget.presenter.notifyTyping(true);
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
    final isSelected = widget.emojiTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => widget.onEmojiTabChanged(index),
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
