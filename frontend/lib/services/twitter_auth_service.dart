import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../pages/feed_page.dart';
import '../providers/auth_provider.dart';

class TwitterAuthService {
  static String _generateCodeVerifier() {
    final rand = Random.secure();
    final code = List.generate(64, (_) => rand.nextInt(256));
    return base64UrlEncode(code).replaceAll('=', '');
  }

  static String _generateCodeChallenge(String verifier) {
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes);
    return base64UrlEncode(digest.bytes).replaceAll('=', '');
  }

  Future<void> loginToTwitter(BuildContext context) async {
    final clientId = dotenv.env['TWITTER_CLIENT_ID']!;
    final redirectUri = 'blufeed://twitter-callback';

    final codeVerifier = _generateCodeVerifier();
    final codeChallenge = _generateCodeChallenge(codeVerifier);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('twitter_code_verifier', codeVerifier);

    final authUrl = Uri.https('twitter.com', '/i/oauth2/authorize', {
      'response_type': 'code',
      'client_id': clientId,
      'redirect_uri': redirectUri,
      'scope': 'tweet.read users.read offline.access',
      'state': 'secure_random',
      'code_challenge': codeChallenge,
      'code_challenge_method': 'S256',
    });

    print("Launching Twitter auth URL: $authUrl");

    try {
      final result = await FlutterWebAuth.authenticate(
        url: authUrl.toString(),
        callbackUrlScheme: 'blufeed',
      );

      final code = Uri.parse(result).queryParameters['code'];
      if (code == null) return;

      final storedCodeVerifier = prefs.getString('twitter_code_verifier');
      if (storedCodeVerifier == null) {
        print("No stored code verifier found.");
        return;
      }

      final backendUrl = dotenv.env['BACKEND_URL'];
      final userId = Provider.of<AuthProvider>(context, listen: false).user?.id;
      final tokenResp = await http.post(
        Uri.parse("$backendUrl/api/twitter/token"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "code": code,
          "redirect_uri": redirectUri,
          "code_verifier": storedCodeVerifier,
          "user_id": userId,
        }),
      );

      if (tokenResp.statusCode == 200) {
        final token = jsonDecode(tokenResp.body)['access_token'];
        await Provider.of<AuthProvider>(context, listen: false)
            .setTwitterToken(token);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const FeedPage()),
        );
      } else {
        print("Twitter token failed: ${tokenResp.statusCode} ${tokenResp.body}");
      }
    } catch (e) {
      print("Twitter login failed: $e");
    }
  }
}
