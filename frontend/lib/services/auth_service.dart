import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/user_model.dart';

class AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
    serverClientId: dotenv.env['SERVER_CLIENT_ID'],
  );

  User? _user;

  Future<bool> signInWithGoogle() async {
    try {
      // Try silent sign-in first
      final account = await _googleSignIn.signInSilently();
      if (account == null) {
        print("Silent sign-in failed, showing login screen...");
        final manualAccount = await _googleSignIn.signIn();
        if (manualAccount == null) return false;
        return _handleAuth(manualAccount);
      }
      return _handleAuth(account);
    } catch (e) {
      print("Google Sign-In failed: $e");
      return false;
    }
  }

  Future<bool> _handleAuth(GoogleSignInAccount account) async {
    final authentication = await account.authentication;
    final idToken = authentication.idToken;
    if (idToken == null) return false;

    final response = await http.post(
      Uri.parse("${dotenv.env['BACKEND_URL']}/api/auth/google"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"token": idToken}),
    );

    if (response.statusCode != 200) return false;

    final data = jsonDecode(response.body);
    _user = User(id: data['id'], email: data['email']);
    return true;
  }

  User? getUser() => _user;
}
