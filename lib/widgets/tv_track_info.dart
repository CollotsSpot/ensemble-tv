import 'package:flutter/material.dart';

/// Track information display for TV.
/// Shows title, artist, and album with extracted colors.
class TVTrackInfo extends StatelessWidget {
  final String title;
  final String artist;
  final String album;
  final String? playerName; // Optional - if null/empty, player name is hidden
  final bool isPlaying;
  final Color textColor;

  const TVTrackInfo({
    super.key,
    required this.title,
    required this.artist,
    required this.album,
    this.playerName, // Optional
    required this.isPlaying,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title (largest)
        Text(
          title,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 16),

        // Artist
        Text(
          artist,
          style: TextStyle(
            fontSize: 24,
            color: textColor.withOpacity(0.9),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),

        // Album (smaller)
        if (album.isNotEmpty) ...[
          Text(
            album,
            style: TextStyle(
              fontSize: 20,
              color: textColor.withOpacity(0.8),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
        ],

        // Player name with playing indicator (only show if playerName provided)
        if (playerName != null && playerName!.isNotEmpty)
          Row(
            children: [
              if (isPlaying)
                Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: textColor,
                  ),
                ),
              Text(
                playerName!,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  color: textColor.withOpacity(0.9),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
