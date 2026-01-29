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
              placeholder: (context, url) => const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
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
}
