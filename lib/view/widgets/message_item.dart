import 'package:flutter/material.dart';
import 'package:my_chat_app/model/message.dart';
import 'package:my_chat_app/view/voice_message_player.dart';

class MessageItem extends StatelessWidget {
  final Message message;
  final bool isMe;
  final bool showAvatar;
  final String? otherUserProfilePictureUrl;
  final String otherUserName;
  final bool isOnlyEmojis;
  final Function(Message) onLongPress;
  final Widget Function(String) buildReplyPreview;
  final Widget Function(Map<String, String>) buildReactions;
  final Widget Function(Message, bool) buildMessageStatus;

  const MessageItem({
    super.key,
    required this.message,
    required this.isMe,
    required this.showAvatar,
    required this.otherUserProfilePictureUrl,
    required this.otherUserName,
    required this.isOnlyEmojis,
    required this.onLongPress,
    required this.buildReplyPreview,
    required this.buildReactions,
    required this.buildMessageStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe)
             Padding(
               padding: const EdgeInsets.only(right: 8.0, bottom: 4.0),
               child: showAvatar 
                 ? CircleAvatar(
                     radius: 14,
                     backgroundImage: otherUserProfilePictureUrl != null 
                       ? NetworkImage(otherUserProfilePictureUrl!) 
                       : null,
                     child: otherUserProfilePictureUrl == null 
                       ? Text(otherUserName.isEmpty ? '?' : otherUserName[0].toUpperCase()) 
                       : null,
                   )
                 : const SizedBox(width: 28), // Placeholder for alignment
             ),
          
          Flexible(
            child: GestureDetector(
              onLongPress: () => onLongPress(message),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: isOnlyEmojis 
                        ? const EdgeInsets.all(0) 
                        : const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                    decoration: isOnlyEmojis 
                        ? null 
                        : BoxDecoration(
                            gradient: isMe 
                                ? const LinearGradient(
                                    colors: [Color(0xFFE91E63), Color(0xFF9C27B0)], // Pink to Purple gradient
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            color: isMe ? null : const Color(0xFF424242), // Dark Grey for Other
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(20),
                              topRight: const Radius.circular(20),
                              bottomLeft: Radius.circular(isMe ? 20 : 5),
                              bottomRight: Radius.circular(isMe ? 5 : 20),
                            ),
                          ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (message.replyToMessageId != null)
                          buildReplyPreview(message.replyToMessageId!),
                        
                        if (message.type == MessageType.text)
                          Text(
                            message.editedContent ?? message.content,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isOnlyEmojis ? 40 : 16,
                            ),
                          ),
                        if (message.type == MessageType.image)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(message.content, width: 200, fit: BoxFit.cover),
                          ),
                        if (message.type == MessageType.voice)
                           VoiceMessagePlayer(
                              audioUrl: message.content,
                              backgroundColor: Colors.transparent,
                              textColor: Colors.white,
                            ),
                      ],
                    ),
                  ),
                  // Reactions overlap
                  if (message.reactions.isNotEmpty)
                    Positioned(
                      bottom: -10,
                      right: isMe ? null : -10,
                      left: isMe ? -10 : null,
                      child: buildReactions(message.reactions),
                    ),
                ],
              ),
            ),
          ),
          if (isMe)
             Padding(
               padding: const EdgeInsets.only(left: 4.0, bottom: 4.0),
               child: buildMessageStatus(message, true),
             ),
        ],
      ),
    );
  }
}
