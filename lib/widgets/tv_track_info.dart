import 'package:flutter/material.dart';

/// Track information display for TV.
/// Shows title, artist, and album with white text for TV.
class TVTrackInfo extends StatelessWidget {
  final String title;
  final String artist;
  final String album;
  final String? playerName; // Optional - if null/empty, player name is hidden
  final bool isPlaying;

  const TVTrackInfo({
    super.key,
    required this.title,
    required this.artist,
    required this.album,
    this.playerName, // Optional
    required this.isPlaying,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title (largest) - pure white
        Text(
          title,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 16),

        // Artist - white with 90% opacity
        Text(
          artist,
          style: const TextStyle(
            fontSize: 24,
            color: Color(0xE6FFFFFF), // White with 90% opacity
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),

        // Album (smaller) - white with 80% opacity
        if (album.isNotEmpty) ...[
          Text(
            album,
            style: const TextStyle(
              fontSize: 20,
              color: Color(0xCCFFFFFF), // White with 80% opacity
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
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
              Text(
                playerName!,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  color: Color(0xE6FFFFFF), // White with 90% opacity
                ),
              ),
            ],
          ),
      ],
    );
  }
}
