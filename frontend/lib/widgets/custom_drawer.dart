import 'package:flutter/material.dart';
import '../services/reddit_auth_service.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.black87,
      child: ListView(
        children: [
          ListTile(
            title: const Text('Login with Reddit', style: TextStyle(color: Colors.white)),
            onTap: () {
              RedditAuthService().signInWithReddit(context);
            },
          ),
        ],
      ),
    );
  }
}
