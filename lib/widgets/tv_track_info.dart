import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Track information display for TV.
/// Shows title, artist, and album with album art colors.
class TVTrackInfo extends StatelessWidget {
  final String title;
  final String artist;
  final String album;
  final String? playerName; // Optional - if null/empty, player name is hidden
  final bool isPlaying;
  final Color? accentColor; // Album art dominant color for text

  const TVTrackInfo({
    super.key,
    required this.title,
    required this.artist,
    required this.album,
    this.playerName, // Optional
    required this.isPlaying,
    this.accentColor, // Album art color for text
  });

  @override
  Widget build(BuildContext context) {
    final useAccent = accentColor != null;
    final titleColor = useAccent ? accentColor! : const Color(0xFFFFFFFF);
    final artistColor = useAccent ? accentColor!.withOpacity(0.6) : const Color(0x99FFFFFF);
    final albumColor = useAccent ? accentColor!.withOpacity(0.8) : const Color(0xCCFFFFFF);
    final indicatorColor = useAccent ? accentColor! : Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title (largest) - can use multiple lines for long classical names
        Text(
          title,
          style: GoogleFonts.courierPrime(
            textStyle: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w500,
              color: titleColor,
              height: 1.2,
            ),
          ),
          maxLines: 5,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 16),

        // Artist - can use multiple lines
        Text(
          artist,
          style: GoogleFonts.courierPrime(
            textStyle: TextStyle(
              fontSize: 28,
              color: artistColor,
              height: 1.2,
            ),
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),

        // Album (smaller) - can use multiple lines
        if (album.isNotEmpty) ...[
          Text(
            album,
            style: GoogleFonts.courierPrime(
              textStyle: TextStyle(
                fontSize: 26,
                color: albumColor,
                height: 1.2,
              ),
            ),
            maxLines: 2,
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
                    color: indicatorColor,
                  ),
                ),
              Text(
                playerName!,
                style: GoogleFonts.courierPrime(
                  textStyle: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w500,
                    color: artistColor,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
