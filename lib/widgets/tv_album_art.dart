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
      height: double.infinity,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey.shade900,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            backgroundColor ?? Colors.grey.shade900,
            (backgroundColor ?? Colors.grey.shade900).withOpacity(0.7),
          ],
        ),
      ),
      child: imageUrl != null && imageUrl!.isNotEmpty
          ? Padding(
              padding: const EdgeInsets.all(20),
              child: CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.contain,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                errorWidget: (context, url, error) => Center(
                  child: Icon(
                    Icons.album,
                    size: 200,
                    color: (backgroundColor ?? Colors.white).withOpacity(0.5),
                  ),
                ),
              ),
            )
          : Center(
              child: Icon(
                Icons.album,
                size: 200,
                color: (backgroundColor ?? Colors.white).withOpacity(0.5),
              ),
            ),
    );
  }
}
