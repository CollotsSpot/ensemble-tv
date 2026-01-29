import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/media_item.dart';
import '../providers/tv_display_provider.dart';
import '../widgets/tv_album_art.dart';
import '../widgets/tv_track_info.dart';
import '../widgets/tv_progress_bar.dart';

/// Main display screen for Ensemble TV.
/// Shows album art and track info for the selected player.
/// No on-screen controls - all control via Shield remote.
class DisplayScreen extends StatefulWidget {
  const DisplayScreen({super.key});

  @override
  State<DisplayScreen> createState() => _DisplayScreenState();
}

class _DisplayScreenState extends State<DisplayScreen> {
  /// Get album art URL from track metadata
  String? _getAlbumArtUrl(Track? track) {
    if (track == null) return null;

    // Try to get image from metadata
    final metadata = track.metadata;
    if (metadata != null) {
      final image = metadata['image'] as Map<String, dynamic>?;
      if (image != null) {
        return image['url'] as String?;
      }
    }

    // Try album's image
    if (track.album?.metadata != null) {
      final albumImage = track.album!.metadata!['image'] as Map<String, dynamic>?;
      if (albumImage != null) {
        return albumImage['url'] as String?;
      }
    }

    return null;
  }
  @override
  void initState() {
    super.initState();
    // Initialize connection when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TVDisplayProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Consumer<TVDisplayProvider>(
          builder: (context, provider, child) {
            // Show player select if no player selected
            if (provider.selectedPlayerId == null) {
              return const Center(
                child: Text(
                  'No player selected',
                  style: TextStyle(fontSize: 32, color: Colors.white),
                ),
              );
            }

            // Show loading if connecting
            if (provider.isLoading) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 20),
                    Text(
                      'Connecting to Music Assistant...',
                      style: TextStyle(fontSize: 24, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            // Show error state
            if (provider.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 80,
                      color: Colors.red,
                    ),
                    SizedBox(height: 20),
                    Text(
                      provider.error!,
                      style: const TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: () => provider.initialize(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 20,
                        ),
                      ),
                      child: const Text(
                        'Retry',
                        style: TextStyle(fontSize: 24),
                      ),
                    ),
                  ],
                ),
              );
            }

            // Get current track info
            final currentTrack = provider.currentTrack;
            final currentPlayer = provider.currentPlayer;

            // Show display screen
            return Row(
              children: [
                // Left side: Album art (full height)
                Expanded(
                  flex: 1,
                  child: TVAlbumArt(
                    imageUrl: _getAlbumArtUrl(currentTrack),
                    backgroundColor: provider.dominantColor,
                  ),
                ),

                // Right side: Track info and progress
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 60),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (currentTrack != null) ...[
                          TVTrackInfo(
                            title: currentTrack.name,
                            artist: currentTrack.artistsString,
                            album: currentTrack.album?.name ?? '',
                            playerName: currentPlayer?.name ?? 'Unknown Player',
                            isPlaying: currentPlayer?.isPlaying ?? false,
                            textColor: provider.dominantColor ?? Colors.white,
                          ),
                          const SizedBox(height: 40),
                          TVProgressBar(
                            progress: provider.progress,
                            duration: provider.duration,
                            currentTime: provider.currentTime,
                            textColor: provider.dominantColor ?? Colors.white,
                          ),
                        ] else ...[
                          // Idle state - no track playing
                          Text(
                            currentPlayer?.name ?? 'Unknown Player',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: provider.dominantColor ?? Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Ready to play',
                            style: TextStyle(
                              fontSize: 32,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Press Play on your remote to start playback',
                            style: TextStyle(
                              fontSize: 24,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                        const SizedBox(height: 60),
                        const Text(
                          'Press Menu for options',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
