import 'package:my_chat_app/model/delivered_status.dart';
import 'package:my_chat_app/model/message.dart';
import 'package:my_chat_app/model/private_chat.dart';
import 'package:my_chat_app/model/profile.dart';

class ChatSummary {
  final PrivateChat chat;
  final Profile otherProfile;
  final Message? lastMessage;
  final int unreadCount;
  final DeliveredStatus deliveredStatus;

  ChatSummary({
    required this.chat,
    required this.otherProfile,
    this.lastMessage,
    this.unreadCount = 0,
    this.deliveredStatus = const DeliveredStatus(),
  });

  factory ChatSummary.fromJson(Map<String, dynamic> json) {
    return ChatSummary(
      chat: PrivateChat.fromJson(json['chat'] as Map<String, dynamic>),
      otherProfile: Profile.fromJson(json['other_profile'] as Map<String, dynamic>),
      lastMessage: json['last_message'] != null
          ? Message.fromJson(json['last_message'] as Map<String, dynamic>)
          : null,
      unreadCount: json['unread_count'] as int? ?? 0,
      deliveredStatus: json['delivered_status'] != null
          ? DeliveredStatus.fromJson(
              json['delivered_status'] as Map<String, dynamic>,
            )
          : const DeliveredStatus(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chat': chat.toJson(),
      'other_profile': otherProfile.toJson(),
      'last_message': lastMessage?.toJson(),
      'unread_count': unreadCount,
      'delivered_status': deliveredStatus.toJson(),
    };
  }

  ChatSummary copyWith({
    PrivateChat? chat,
    Profile? otherProfile,
    Message? lastMessage,
    int? unreadCount,
    DeliveredStatus? deliveredStatus,
  }) {
    return ChatSummary(
      chat: chat ?? this.chat,
      otherProfile: otherProfile ?? this.otherProfile,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      deliveredStatus: deliveredStatus ?? this.deliveredStatus,
    );
  }
}
