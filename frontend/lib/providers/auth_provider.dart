import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  String? _redditToken;
  String? _twitterToken;
  User? _user;

  String? get redditToken => _redditToken;
  String? get twitterToken => _twitterToken;
  User? get user => _user;

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

    final userJson = prefs.getString('user');
    if (userJson != null) {
      _user = User.fromJson(jsonDecode(userJson));
    }

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

  Future<void> setUser(User user) async {
    _user = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', jsonEncode(user.toJson()));
    notifyListeners();
  }
}
