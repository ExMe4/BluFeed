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

      final redditToken = authProvider.redditToken;
      final twitterToken = authProvider.twitterToken;

      if ((redditToken != null && redditToken.isNotEmpty) ||
          (twitterToken != null && twitterToken.isNotEmpty)) {
        setState(() {
          _feedFuture = _fetchFeed(redditToken, twitterToken);
        });
      }
    });
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  Future<http.Response> _fetchFeed(String? redditToken, String? twitterToken) {
    final backendUrl = dotenv.env['BACKEND_URL'] ?? '';
    print("Fetching combined feed from: $backendUrl/api/combined/feed");

    return http.post(
      Uri.parse("$backendUrl/api/combined/feed"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        'reddit_token': redditToken,
        'twitter_token': twitterToken,
      }),
    );
  }

  Future<void> _refreshFeed() async {
    print("Refreshing feed...");
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final redditToken = authProvider.redditToken;
    final twitterToken = authProvider.twitterToken;

    if ((redditToken != null && redditToken.isNotEmpty) ||
        (twitterToken != null && twitterToken.isNotEmpty)) {
      final newFeed = _fetchFeed(redditToken, twitterToken);
      setState(() {
        _feedFuture = newFeed;
      });
      await newFeed;
      print("Feed refreshed.");
    } else {
      print("Cannot refresh. No tokens.");
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
        tooltip: 'Refresh Feed',
        child: const Icon(Icons.refresh, color: Colors.black),
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
              if (!snapshot.hasData || snapshot.data == null) {
                return const Center(child: CircularProgressIndicator());
              }

              final response = snapshot.data!;
              final json = jsonDecode(response.body);

              if (json['data'] == null || json['data'] is! List) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: Text("Unexpected response format", style: TextStyle(color: Colors.red)),
                      ),
                    ),
                  ],
                );
              }

              final List<dynamic> posts = json['data'];

              return ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final post = posts[index];
                  final source = post['source'];

                  if (source == 'reddit') {
                    return ListTile(
                      title: Text(post['title'] ?? '', style: const TextStyle(color: Colors.white)),
                      subtitle: Text("r/${post['subreddit']}", style: const TextStyle(color: Colors.grey)),
                    );
                  } else if (source == 'twitter') {
                    return ListTile(
                      title: Text(post['text'] ?? '', style: const TextStyle(color: Colors.white)),
                      subtitle: Text("@${post['username']}", style: const TextStyle(color: Colors.blue)),
                    );
                  } else {
                    return const SizedBox();
                  }
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
