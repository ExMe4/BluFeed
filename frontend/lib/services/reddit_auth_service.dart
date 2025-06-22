import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import '../pages/feed_page.dart';
import '../providers/auth_provider.dart';

class RedditAuthService {

  Future<void> loginToReddit(BuildContext context) async {
    final clientId = dotenv.env['REDDIT_CLIENT_ID'];
    print("Reddit client id: $clientId");
    final redirectUri = 'blufeed://auth-callback';
    final authUrl = Uri.https('www.reddit.com', '/api/v1/authorize.compact', {
      'client_id': clientId,
      'response_type': 'code',
      'state': 'random_state_string',
      'redirect_uri': redirectUri,
      'duration': 'permanent',
      'scope': 'identity read',
    });

    print("Auth URL: $authUrl");

    try {
      print("Starting FlutterWebAuth.authenticate...");
      final result = await FlutterWebAuth.authenticate(
        url: authUrl.toString(),
        callbackUrlScheme: "blufeed",
      );
      print("result = $result");

      final code = Uri.parse(result).queryParameters['code'];
      if (code == null) {
        print("No code returned");
        return;
      }

      print("Received Reddit auth code: $code");

      final backendUrl = dotenv.env['BACKEND_URL'];
      final tokenResp = await http.post(
        Uri.parse("$backendUrl/api/reddit/token"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "code": code,
          "redirect_uri": redirectUri,
        }),
      );

      if (tokenResp.statusCode == 200) {
        final data = jsonDecode(tokenResp.body);
        final accessToken = data['token'];
        Provider.of<AuthProvider>(context, listen: false).setRedditToken(accessToken);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const FeedPage()),
        );
        print("Token saved: $accessToken");
      } else {
        print("Failed to get token: ${tokenResp.body}");
      }
    } on PlatformException catch (e) {
      if (e.code == 'CANCELED') {
        print("User canceled Reddit login.");
      } else {
        rethrow;
      }
    }
  }
}
