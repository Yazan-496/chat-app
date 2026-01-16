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
    final bool isVisible = !isConnected || showRestoredMessage;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: isVisible ? 30 : 0,
      width: double.infinity,
      color: isConnected ? Colors.green : Colors.red,
      child: isVisible 
        ? Center(
            child: Text(
              isConnected ? 'Connection Restored' : 'No Internet Connection',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          )
        : const SizedBox.shrink(),
    );
  }
}
