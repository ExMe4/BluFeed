import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/strings.dart';
import '../pages/feed_page.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    Future<void> _handleLogin() async {
      final success = await authService.signInWithGoogle();
      if (!success) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const FeedPage()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.g_mobiledata_rounded, color: Colors.black),
              label: const Text(AppStrings.loginWithGoogle),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
              onPressed: _handleLogin,
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.apple, color: Colors.black),
              label: const Text(AppStrings.loginWithApple),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                // TODO: Apple login integration
              },
            ),
          ],
        ),
      ),
    );
  }
}
