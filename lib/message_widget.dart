import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_chat_app/model/message.dart';
import 'package:my_chat_app/view/voice_message_player.dart';

class MessageItem extends StatefulWidget {
  final Message message;
  final bool isMe;
  final bool showAvatar;
  final String? profilePictureUrl;
  final int? avatarColor;
  final String displayName;
  final bool isOnlyEmojis;
  final Function(Message) onLongPress;
  final Widget Function(String) buildReplyPreview;
  final Widget Function(Map<String, String>) buildReactions;
  final Widget Function(Message, bool) buildMessageStatus;
  final Function(Message) onSwipeReply;
  final Function(Message) onDoubleTapReact;

  const MessageItem({
    super.key,
    required this.message,
    required this.isMe,
    required this.showAvatar,
    required this.profilePictureUrl,
    this.avatarColor,
    required this.displayName,
    required this.isOnlyEmojis,
    required this.onLongPress,
    required this.buildReplyPreview,
    required this.buildReactions,
    required this.buildMessageStatus,
    required this.onSwipeReply,
    required this.onDoubleTapReact,
  });

  @override
  State<MessageItem> createState() => _MessageItemState();
}

class _MessageItemState extends State<MessageItem> {
  double _dragX = 0.0;

  @override
  Widget build(BuildContext context) {
    final timeLabel = DateFormat('HH:mm').format(widget.message.timestamp);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
      child: Row(
        mainAxisAlignment: widget.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!widget.isMe)
            Padding(
              padding: const EdgeInsets.only(right: 8.0, bottom: 4.0),
              child: widget.showAvatar
                  ? CircleAvatar(
                      radius: 14,
                      backgroundColor: widget.avatarColor != null 
                          ? Color(widget.avatarColor!) 
                          : Colors.blue.shade300,
                      backgroundImage: widget.profilePictureUrl != null
                          ? NetworkImage(widget.profilePictureUrl!)
                          : null,
                      child: widget.profilePictureUrl == null
                          ? Text(
                              widget.displayName.isEmpty ? '?' : widget.displayName[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            )
                          : null,
                    )
                 : const SizedBox(width: 28), // Placeholder for alignment
             ),
         
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onLongPress: () => widget.onLongPress(widget.message),
              onDoubleTap: () => widget.onDoubleTapReact(widget.message),
              onHorizontalDragUpdate: (details) {
                final next = (_dragX + details.delta.dx).clamp(-80.0, 80.0);
                setState(() {
                  _dragX = next;
                });
              },
              onHorizontalDragEnd: (details) {
                if (_dragX.abs() > 50) {
                  widget.onSwipeReply(widget.message);
                }
                setState(() {
                  _dragX = 0;
                });
              },
              child: Transform.translate(
                offset: Offset(_dragX, 0),
                child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: widget.isOnlyEmojis
                        ? const EdgeInsets.all(0)
                        : const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                    decoration: widget.isOnlyEmojis
                        ? null
                        : BoxDecoration(
                            gradient: widget.isMe
                                ? const LinearGradient(
                                    colors: [Color(0xFFE91E63), Color(0xFF9C27B0)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            color: widget.isMe ? null : const Color(0xFF424242),
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(20),
                              topRight: const Radius.circular(20),
                              bottomLeft: Radius.circular(widget.isMe ? 20 : 5),
                              bottomRight: Radius.circular(widget.isMe ? 5 : 20),
                            ),
                          ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.message.type == MessageType.text)
                          Text(
                            widget.message.deleted ? 'Removed message' : (widget.message.editedContent ?? widget.message.content),
                            style: TextStyle(
                              color: widget.message.deleted ? Colors.white70 : Colors.white,
                              fontStyle: widget.message.deleted ? FontStyle.italic : FontStyle.normal,
                              decoration: widget.message.deleted ? TextDecoration.lineThrough : TextDecoration.none,
                              fontSize: widget.isOnlyEmojis ? 40 : 16,
                            ),
                          ),
                        if (widget.message.type == MessageType.image)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(widget.message.content, width: 200, fit: BoxFit.cover),
                          ),
                        if (widget.message.type == MessageType.voice)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: VoiceMessagePlayer(
                              audioUrl: widget.message.content,
                              backgroundColor: widget.isMe ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
                              textColor: Colors.white,
                            ),
                          ),
                        if (!widget.isOnlyEmojis)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (widget.message.editedContent != null && !widget.message.deleted)
                                const Padding(
                                  padding: EdgeInsets.only(right: 4.0),
                                  child: Icon(Icons.edit, size: 12, color: Colors.white70),
                                ),
                              Text(
                                timeLabel,
                                style: const TextStyle(color: Colors.white70, fontSize: 10),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  if (widget.message.reactions.isNotEmpty)
                    Positioned(
                      bottom: -10,
                      right: widget.isMe ? null : -10,
                      left: widget.isMe ? -10 : null,
                      child: widget.buildReactions(widget.message.reactions),
                    ),
                ],
              ),
              ),
            ),
          ),
          if (widget.isMe)
            Padding(
              padding: const EdgeInsets.only(left: 4.0, bottom: 4.0),
              child: widget.buildMessageStatus(widget.message, true),
            ),
        ],
      ),
    );
  }
}
