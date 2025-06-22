import 'package:flutter/material.dart';
import '../utils/strings.dart';
import '../services/reddit_auth_service.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.black87,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          OutlinedButton.icon(
            icon: const Icon(Icons.reddit, color: Colors.orange),
            label: const Text(
              AppStrings.syncWithReddit,
              style: TextStyle(color: Colors.orange),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.orange),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () {
              RedditAuthService().loginToReddit(context);
            },
          ),
        ],
      ),
    );
  }
}
