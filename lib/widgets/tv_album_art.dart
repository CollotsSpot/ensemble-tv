import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Large album art display for TV.
/// Full screen height, left-aligned layout.
class TVAlbumArt extends StatelessWidget {
  final String? imageUrl;
  final Color? backgroundColor;

  const TVAlbumArt({
    super.key,
    this.imageUrl,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.black,
        gradient: backgroundColor != null
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  backgroundColor!,
                  backgroundColor!.withOpacity(0.7),
                ],
              )
            : null,
      ),
      child: imageUrl != null && imageUrl!.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: imageUrl!,
              fit: BoxFit.contain,
              placeholder: (context, url) => _buildSkeletonLoader(context),
              errorWidget: (context, url, error) => const Center(
                child: Icon(
                  Icons.album,
                  size: 200,
                  color: Colors.white24,
                ),
              ),
            )
          : const Center(
              child: Icon(
                Icons.album,
                size: 200,
                color: Colors.white24,
              ),
            ),
    );
  }

  Widget _buildSkeletonLoader(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 200,
            height: 200,
            child: CircularProgressIndicator(
              color: backgroundColor != null
                  ? Colors.white
                  : Theme.of(context).colorScheme.primary,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Loading album art...',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white54,
            ),
          ),
        ],
      ),
    );
  }
}
