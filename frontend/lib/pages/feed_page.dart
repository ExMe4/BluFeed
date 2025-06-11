import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_drawer.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  @override
  Widget build(BuildContext context) {
    // Get the token from the provider
    final accessToken = Provider.of<AuthProvider>(context).redditToken;

    return Scaffold(
      key: _scaffoldKey,
      drawer: const CustomDrawer(),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          CustomAppBar(onMenuPressed: () => _scaffoldKey.currentState?.openDrawer()),
        ],
        body: FutureBuilder(
          future: http.post(
            Uri.parse("http://192.168.178.28:3000/api/reddit/feed"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({'token': accessToken}),
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError || snapshot.data == null) {
              return Center(
                child: Text("Error loading feed", style: TextStyle(color: Colors.red)),
              );
            }

            final response = snapshot.data!;
            final json = jsonDecode(response.body);

            if (json['data'] == null || json['data']['children'] == null) {
              return Center(
                child: Text(
                  "Unexpected response format:\n${response.body}",
                  style: TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              );
            }

            final posts = json['data']['children'];
            return ListView.builder(
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index]['data'];
                return ListTile(
                  title: Text(post['title'] ?? '',
                      style: const TextStyle(color: Colors.white)),
                  subtitle: Text("r/${post['subreddit']}",
                      style: const TextStyle(color: Colors.grey)),
                );
              },
            );
          },
        ),
      ),
      backgroundColor: Colors.black,
    );
  }
}
