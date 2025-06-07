import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class User {
  final String id;
  final String email;

  User({required this.id, required this.email});
}

class AuthService {
  User? _user;

  Future<bool> signInWithGoogle() async {
    final GoogleSignIn _googleSignIn = GoogleSignIn(
      scopes: ['email'],
      serverClientId: dotenv.env['SERVER_CLIENT_ID'],
    );

    try {
      final account = await _googleSignIn.signIn();

      if (account == null) {
        print("User cancelled Google Sign-In");
        return false;
      }

      final authentication = await account.authentication;
      final idToken = authentication.idToken;
      if (idToken == null) return false;

      print("ID Token: $idToken");

      // Sends the token to the backend
      final response = await http.post(
        Uri.parse("http://192.168.178.28:3000/api/auth/google"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"token": idToken}),
      );

      print("Status: ${response.statusCode}");
      print("Body: ${response.body}");

      if (response.statusCode != 200) return false;

      final data = jsonDecode(response.body);
      _user = User(id: data['id'], email: data['email']);
      return true;
    } catch (e) {
      print("Google Sign-In failed: $e");

      if (e is http.ClientException) {
        print("ClientException details: ${e.message}");
      }

      return false;
    }
  }

  User? getUser() => _user;
}
