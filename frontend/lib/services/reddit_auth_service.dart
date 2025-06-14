import 'package:flutter/material.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class RedditAuthService {
  final _clientId = 'YdI88tj889dfm1S_DMw51g';
  final _redirectUri = 'blufeed://auth-callback';

  Future<void> signInWithReddit(BuildContext context) async {
    final url = Uri.https('www.reddit.com', '/api/v1/authorize.compact', {
      'client_id': _clientId,
      'response_type': 'code',
      'state': 'random_string',
      'redirect_uri': _redirectUri,
      'duration': 'permanent',
      'scope': 'read identity',
    });

    try {
      final result = await FlutterWebAuth.authenticate(
        url: url.toString(),
        callbackUrlScheme: 'bluefeed',
      );
      print("Auth result: $result");

      final code = Uri.parse(result).queryParameters['code'];

      if (code != null) {
        final tokenResponse = await http.post(
          Uri.parse('https://www.reddit.com/api/v1/access_token'),
          headers: {
            'Authorization':
            'Basic ${base64Encode(utf8.encode("$_clientId:"))}',
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          body: {
            'grant_type': 'authorization_code',
            'code': code,
            'redirect_uri': _redirectUri,
          },
        );

        if (tokenResponse.statusCode == 200) {
          final data = jsonDecode(tokenResponse.body);
          final accessToken = data['access_token'];

          Provider.of<AuthProvider>(context, listen: false)
              .setRedditToken(accessToken);
        } else {
          print("Token exchange failed: ${tokenResponse.body}");
        }
      }
    } catch (e) {
      print("Login error: $e");
    }


  }
}
