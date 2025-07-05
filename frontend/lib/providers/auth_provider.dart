import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  String? _redditToken;
  String? _twitterToken;

  String? get redditToken => _redditToken;
  String? get twitterToken => _twitterToken;

  late Future<void> _loadingFuture;
  Future<void> get loadingFuture => _loadingFuture;

  AuthProvider() {
    _loadingFuture = _loadTokens();
  }

  Future<void> _loadTokens() async {
    final prefs = await SharedPreferences.getInstance();
    _redditToken = prefs.getString('reddit_token');
    _twitterToken = prefs.getString('twitter_token');
    print("Loaded Reddit token: $_redditToken");
    print("Loaded Twitter token: $_twitterToken");
    notifyListeners();
  }

  Future<void> setRedditToken(String token) async {
    _redditToken = token;
    final prefs = await SharedPreferences.getInstance();
    print("All SharedPreferences: ${prefs.getKeys()}");
    await prefs.setString('reddit_token', token);
    notifyListeners();
  }

  Future<void> setTwitterToken(String token) async {
    _twitterToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('twitter_token', token);
    notifyListeners();
  }
}
