import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class User {
  final String id;
  final String email;

  User({required this.id, required this.email});
}

class AuthService {
  User? _user;

  Future<bool> signInWithGoogle() async {
    final GoogleSignIn _googleSignIn = GoogleSignIn();

    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return false;

      final authentication = await account.authentication;
      final idToken = authentication.idToken;
      if (idToken == null) return false;

      // Sends the token to the backend
      final response = await http.post(
        Uri.parse("http://localhost:8080/api/auth/google"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"token": idToken}),
      );

      if (response.statusCode != 200) return false;

      final data = jsonDecode(response.body);
      _user = User(id: data['id'], email: data['email']);
      return true;
    } catch (e) {
      print("Google Sign-In failed: $e");
      return false;
    }
  }

  User? getUser() => _user;
}
