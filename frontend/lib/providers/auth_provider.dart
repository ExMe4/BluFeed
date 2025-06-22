import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  String? _redditToken;
  String? get redditToken => _redditToken;

  late Future<void> _loadingFuture;
  Future<void> get loadingFuture => _loadingFuture;

  AuthProvider() {
    _loadingFuture = _loadToken(); // Save the loading future
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _redditToken = prefs.getString('reddit_token');
    print("Loaded token from SharedPreferences: $_redditToken");
    notifyListeners();
  }

  void setRedditToken(String token) async {
    _redditToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('reddit_token', token);
    notifyListeners();
  }
}