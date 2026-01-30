import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Non-seekable progress display for TV.
/// Shows current playback position as "current/total" time format.
class TVProgressBar extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final Duration? duration;
  final Duration? currentTime;
  final Color? accentColor; // Album art dominant color for progress display

  const TVProgressBar({
    super.key,
    required this.progress,
    this.duration,
    this.currentTime,
    this.accentColor,
  });

  String _formatDuration(Duration? d) {
    if (d == null) return '0:00';
    final minutes = d.inMinutes;
    final seconds = d.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final useAccent = accentColor != null;
    final textColor = useAccent
        ? accentColor!.withOpacity(0.9)
        : const Color(0xE6FFFFFF);

    return Text(
      '${_formatDuration(currentTime)} / ${_formatDuration(duration)}',
      style: GoogleFonts.courierPrime(
        textStyle: TextStyle(
          fontSize: 20,
          color: textColor,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
