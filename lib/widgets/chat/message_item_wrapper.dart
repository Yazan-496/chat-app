import 'package:flutter/material.dart';
import 'package:my_chat_app/model/message.dart';
import 'package:my_chat_app/model/chat.dart';
import 'package:my_chat_app/presenter/chat_presenter.dart';
import 'package:my_chat_app/message_widget.dart';

class MessageItemWrapper extends StatelessWidget {
  final Message message;
  final bool isMe;
  final bool showAvatar;
  final Chat chat;
  final ChatPresenter presenter;
  final bool isOnlyEmojis;
  final GlobalKey messageKey;
  final Function(Message) onLongPress;
  final Function(Message) onDoubleTapReact;
  final Function(String) onReplyTap;
  final Function(Message) onSwipeReply;
  final Widget Function(String) buildReplyPreview;
  final Widget Function(Map<String, String>) buildReactions;
  final Widget Function(Message, bool) buildMessageStatus;

  const MessageItemWrapper({
    required this.messageKey,
    required this.message,
    required this.isMe,
    required this.showAvatar,
    required this.chat,
    required this.presenter,
    required this.isOnlyEmojis,
    required this.onLongPress,
    required this.onDoubleTapReact,
    required this.onReplyTap,
    required this.onSwipeReply,
    required this.buildReplyPreview,
    required this.buildReactions,
    required this.buildMessageStatus,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final widgets = <Widget>[];

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
              onTap: () => onReplyTap(message.replyToMessageId!),
              child: buildReplyPreview(message.replyToMessageId!),
            ),
          ),
        ),
      );
    }

    widgets.add(
      MessageItem(
        key: messageKey,
        message: message,
        isMe: isMe,
        showAvatar: showAvatar,
        profilePictureUrl: chat.profilePictureUrl,
        avatarColor: chat.avatarColor,
        displayName: chat.displayName,
        isOnlyEmojis: isOnlyEmojis,
        onLongPress: onLongPress,
        onDoubleTapReact: onDoubleTapReact,
        buildReplyPreview: buildReplyPreview,
        buildReactions: buildReactions,
        buildMessageStatus: buildMessageStatus,
        onSwipeReply: onSwipeReply,
      ),
    );

    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widgets,
      ),
    );
  }
}
