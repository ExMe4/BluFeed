import 'package:flutter/material.dart';
import '../services/twitter_auth_service.dart';
import '../utils/strings.dart';
import '../services/reddit_auth_service.dart';

class CustomDrawer extends StatefulWidget {
  const CustomDrawer({super.key});

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  bool _isLoggingIn = false;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.black87,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          OutlinedButton.icon(
            icon: const Icon(Icons.alternate_email, color: Colors.lightBlue),
            label: _isLoggingIn
                ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.lightBlue),
              ),
            )
                : const Text(
              'Sync with Twitter',
              style: TextStyle(color: Colors.lightBlue),
            ),
            onPressed: _isLoggingIn
                ? null
                : () async {
              setState(() => _isLoggingIn = true);
              await TwitterAuthService().loginToTwitter(context);
              setState(() => _isLoggingIn = false);
            },
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.reddit, color: Colors.orange),
            label: _isLoggingIn
                ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
              ),
            )
                : const Text(
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
            onPressed: _isLoggingIn
                ? null
                : () async {
              setState(() {
                _isLoggingIn = true;
              });

              await RedditAuthService().loginToReddit(context);

              setState(() {
                _isLoggingIn = false;
              });
            },
          ),
        ],
      ),
    );
  }
}
