import 'package:flutter/cupertino.dart';

class AuthProvider extends ChangeNotifier {
  String? _redditToken;

  String? get redditToken => _redditToken;

  void setRedditToken(String token) {
    _redditToken = token;
    notifyListeners();
  }
}