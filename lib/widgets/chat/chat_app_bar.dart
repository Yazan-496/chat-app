import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:my_chat_app/model/profile.dart';
import 'package:my_chat_app/presenter/chat_presenter.dart';
import 'package:my_chat_app/l10n/app_localizations.dart';
import 'package:my_chat_app/view/profile_screen.dart';

class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Profile otherProfile;
  final ChatPresenter presenter;
  final bool isConnected;
  final VoidCallback onBack;
  final bool isBubble;

  const ChatAppBar({
    super.key,
    required this.otherProfile,
    required this.presenter,
    required this.isConnected,
    required this.onBack,
    this.isBubble = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

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

  @override
  Widget build(BuildContext context) {
    final isOnline = otherProfile.status == UserStatus.online;
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.black,
      surfaceTintColor: Colors.transparent, // Prevent Material 3 color shifts
      leading: isBubble
          ? null
          : IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: onBack,
            ),
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: GestureDetector(
        onTap: isBubble
            ? null
            : () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ProfileScreen(
                userId: otherProfile.id,
              ),
            ),
          );
        },
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: otherProfile.avatarColor != null
                      ? Color(otherProfile.avatarColor!)
                      : Colors.blue.shade300,
                  backgroundImage: otherProfile.avatarUrl != null
                      ? CachedNetworkImageProvider(otherProfile.avatarUrl!)
                      : null,
                  child: otherProfile.avatarUrl == null
                      ? Text(
                          otherProfile.displayName.isNotEmpty
                              ? otherProfile.displayName[0].toUpperCase()
                              : '',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18),
                        )
                      : null,
                ),
                if (isOnline && isConnected)
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
                  otherProfile.displayName,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                if (isConnected)
                  if (presenter.otherUserTyping && isOnline)
                    Text(
                      AppLocalizations.of(context).translate('typing'),
                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                    )
                  else
                    Text(
                      isOnline ? 'Online' : _formatLastSeen(otherProfile.lastSeen),
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
    );
  }
}
