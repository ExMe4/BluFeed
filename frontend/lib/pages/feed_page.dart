import 'package:BluFeed/utils/strings.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
  Future<http.Response>? _feedFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.loadingFuture;

      final token = authProvider.redditToken;
      print("Token after await in initState: $token");

      if (token != null && token.isNotEmpty) {
        setState(() {
          _feedFuture = _fetchFeed(token);
        });
      }
    });
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  Future<http.Response> _fetchFeed(String token) {
    final backendUrl = dotenv.env['BACKEND_URL'] ?? '';
    print("Fetching feed from: $backendUrl/api/reddit/feed");
    return http.post(
      Uri.parse("$backendUrl/api/reddit/feed"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({'token': token}),
    );
  }

  Future<void> _refreshFeed() async {
    print("Refreshing feed...");
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.redditToken;

    print("Token from AuthProvider during refresh: $token");

    if (token != null && token.isNotEmpty) {
      final newFeed = _fetchFeed(token);
      setState(() {
        _feedFuture = newFeed;
      });
      await newFeed;
      print("Feed refreshed.");
    } else {
      print("Cannot refresh. No token.");
    }
  }


  @override
  Widget build(BuildContext context) {
    final token = Provider.of<AuthProvider>(context).redditToken;
    print("Token in build: $token");

    return Scaffold(
      key: _scaffoldKey,
      drawer: const CustomDrawer(),
      backgroundColor: Colors.black,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          print("FAB pressed: refreshing feed...");
          _refreshFeed();
        },
        backgroundColor: Colors.white,
        child: const Icon(Icons.refresh, color: Colors.black),
        tooltip: 'Refresh Feed',
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          CustomAppBar(onMenuPressed: _openDrawer),
        ],
        body: token == null || token.isEmpty
            ? const Center(
          child: Text(
            AppStrings.emptyFeed,
            style: TextStyle(color: Colors.white),
          ),
        )
            : RefreshIndicator(
          onRefresh: _refreshFeed,
          child: FutureBuilder<http.Response>(
            future: _feedFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError || snapshot.data == null) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: Text(AppStrings.errorLoadingFeed, style: TextStyle(color: Colors.red)),
                      ),
                    ),
                  ],
                );
              }

              final response = snapshot.data!;
              dynamic json;
              try {
                json = jsonDecode(response.body);
              } catch (_) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: Text(
                          "Invalid JSON response:\n${response.body}",
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                );
              }

              if (json['data'] == null || json['data']['children'] == null) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: Text(
                          "Unexpected response format:\n${response.body}",
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                );
              }

              final posts = json['data']['children'];

              return ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final post = posts[index]['data'];
                  return ListTile(
                    title: Text(
                      post['title'] ?? '',
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      "r/${post['subreddit']}",
                      style: const TextStyle(color: Colors.grey),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
