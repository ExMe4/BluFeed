import 'package:flutter/material.dart';
import '../utils/strings.dart';

class CustomAppBar extends StatelessWidget {
  final VoidCallback onMenuPressed;
  final VoidCallback? onRefreshPressed;

  const CustomAppBar({
    super.key,
    required this.onMenuPressed,
    this.onRefreshPressed,
  });

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top;

    return SliverAppBar(
      pinned: true,
      floating: true,
      snap: true,
      backgroundColor: Colors.black,
      expandedHeight: 60,
      automaticallyImplyLeading: false,
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.9),
      flexibleSpace: LayoutBuilder(
        builder: (context, _) {
          return Stack(
            children: [
              const FlexibleSpaceBar(
                centerTitle: true,
                titlePadding: EdgeInsets.only(bottom: 8.0),
                title: Text(
                  AppStrings.appName,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -1.2,
                    fontFamily: 'Merriweather',
                  ),
                ),
              ),
              Positioned(
                left: 8,
                top: topPadding + 8,
                child: IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white, size: 24),
                  onPressed: onMenuPressed,
                ),
              ),
              if (onRefreshPressed != null)
                Positioned(
                  right: 8,
                  top: topPadding + 8,
                  child: IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white, size: 24),
                    tooltip: AppStrings.refreshFeed,
                    onPressed: onRefreshPressed,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}