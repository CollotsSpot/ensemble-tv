import 'package:flutter/material.dart';

/// Non-seekable progress bar for TV display.
/// Shows current playback position and duration.
class TVProgressBar extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final Duration? duration;
  final Duration? currentTime;
  final Color textColor;

  const TVProgressBar({
    super.key,
    required this.progress,
    this.duration,
    this.currentTime,
    required this.textColor,
  });

  String _formatDuration(Duration? d) {
    if (d == null) return '0:00';
    final minutes = d.inMinutes;
    final seconds = d.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress bar
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: textColor.withOpacity(0.3),
            borderRadius: BorderRadius.circular(3),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: FractionallySizedBox(
              widthFactor: progress.clamp(0.0, 1.0),
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  color: textColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Time display
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatDuration(currentTime),
              style: TextStyle(
                fontSize: 20,
                color: textColor.withOpacity(0.9),
              ),
            ),
            Text(
              _formatDuration(duration),
              style: TextStyle(
                fontSize: 20,
                color: textColor.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
