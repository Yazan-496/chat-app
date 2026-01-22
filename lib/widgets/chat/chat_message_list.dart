import 'package:flutter/material.dart';
import 'package:my_chat_app/model/message.dart';
import 'package:my_chat_app/presenter/chat_presenter.dart';
import 'package:my_chat_app/widgets/chat/message_item_wrapper.dart';

class ChatMessageList extends StatelessWidget {
  final ScrollController scrollController;
  final List<Message> messages;
  final ChatPresenter presenter;
  final bool isLoading;
  final Map<String, GlobalKey> messageKeys;
  final Function(String) onReplyTap;
  final Function(Message) onLongPress;
  final Function(Message) onDoubleTapReact;
  final Function(Message) onSwipeReply;
  final Widget Function(String) buildReplyPreview;
  final Widget Function(Map<String, String>) buildReactions;
  final Widget Function(Message, bool) buildMessageStatus;
  final bool Function(String) isOnlyEmojis;
  final double bottomPadding;

  const ChatMessageList({
    super.key,
    required this.scrollController,
    required this.messages,
    required this.presenter,
    required this.isLoading,
    required this.messageKeys,
    required this.onReplyTap,
    required this.onLongPress,
    required this.onDoubleTapReact,
    required this.onSwipeReply,
    required this.buildReplyPreview,
    required this.buildReactions,
    required this.buildMessageStatus,
    required this.isOnlyEmojis,
    this.bottomPadding = 0,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    return ListView.separated(
      controller: scrollController,
      reverse: true,
      physics: const ClampingScrollPhysics(), // Prevent overscroll flickering
      itemCount: messages.length,
      padding: EdgeInsets.only(
        top: 10,
        left: 10,
        right: 10,
        bottom: bottomPadding + 10,
      ),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
      cacheExtent: 1000,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final message = messages[index];
        final bool isMe = message.senderId == presenter.currentUserId;
        final bool showAvatar = !isMe && (index == 0 || messages[index - 1].senderId != message.senderId);

        return MessageItemWrapper(
          messageKey: messageKeys.putIfAbsent(message.id, () => GlobalKey()),
          message: message,
          isMe: isMe,
          showAvatar: showAvatar,
          presenter: presenter,
          isOnlyEmojis: isOnlyEmojis(message.content ?? '') && message.type == MessageType.text,
          onLongPress: onLongPress,
          onDoubleTapReact: onDoubleTapReact,
          onReplyTap: onReplyTap,
          onSwipeReply: onSwipeReply,
          buildReplyPreview: buildReplyPreview,
          buildReactions: buildReactions,
          buildMessageStatus: buildMessageStatus,
        );
      },
    );
  }
}
