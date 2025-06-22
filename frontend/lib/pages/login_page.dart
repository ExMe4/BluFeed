import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import '../utils/strings.dart';
import '../pages/feed_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final success = await _authService.signInWithGoogle();

      if (success) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const FeedPage()),
        );
      }
    });
  }

  Future<void> _handleLogin() async {
    final success = await _authService.signInWithGoogle();
    if (!success) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const FeedPage()),
    );
  }

  Future<void> loginToReddit(BuildContext context) async {
    final clientId = dotenv.env['REDDIT_CLIENT_ID'];
    final redirectUri = 'blufeed://auth-callback';
    final authUrl = 'https://www.reddit.com/api/v1/authorize'
        '?client_id=$clientId'
        '&response_type=code'
        '&state=random_state_string'
        '&redirect_uri=$redirectUri'
        '&duration=permanent'
        '&scope=identity read';

    try {
      final result = await FlutterWebAuth.authenticate(
        url: authUrl,
        callbackUrlScheme: "blufeed",
      );

      final code = Uri.parse(result).queryParameters['code'];
      if (code == null) {
        print("No code returned from Reddit");
        return;
      }

      print("Received Reddit auth code: $code");

      final response = await http.post(
        Uri.parse("${dotenv.env['BACKEND_URL']}/api/reddit/token"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"code": code, "redirect_uri": redirectUri}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final redditToken = data['token'];
        Provider.of<AuthProvider>(context, listen: false).setRedditToken(redditToken);

        print("Reddit token saved: $redditToken");

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const FeedPage()),
        );
      } else {
        print("Failed to get Reddit token: ${response.body}");
      }
    } catch (e) {
      print("Reddit OAuth has failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
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
