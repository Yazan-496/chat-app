import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  final String? message;
  const SplashScreen({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  'assets/images/lozo.jpeg',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 22),
            // Loading Indicator
            const CircularProgressIndicator(color: Colors.blueAccent),
            const SizedBox(height: 14),
            Text(
              message ?? 'LoZo',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.normal,
                    fontSize: 12,
                    letterSpacing: 1,
                    color: Colors.white,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
