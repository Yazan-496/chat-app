import 'package:flutter/material.dart';

class ConnectionStatusBanner extends StatelessWidget {
  final bool isConnected;
  final bool showRestoredMessage;

  const ConnectionStatusBanner({
    super.key,
    required this.isConnected,
    required this.showRestoredMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (!isConnected) {
      return Container(
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
      );
    }

    if (showRestoredMessage) {
      return Container(
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
      );
    }

    return const SizedBox.shrink();
  }
}
