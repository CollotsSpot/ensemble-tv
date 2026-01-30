import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/tv_display_provider.dart';
import '../widgets/tv_album_art.dart';
import '../widgets/tv_track_info.dart';
import '../widgets/tv_progress_bar.dart';
import 'debug_logs_screen.dart';

/// Main display screen for Ensemble TV.
/// Shows album art and track info for the selected player.
/// No on-screen controls - all control via Shield remote.
class DisplayScreen extends StatefulWidget {
  const DisplayScreen({super.key});

  @override
  State<DisplayScreen> createState() => _DisplayScreenState();
}

class _DisplayScreenState extends State<DisplayScreen> {
  Timer? _progressTimer;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Initialize connection when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TVDisplayProvider>().initialize();
    });

    // Start progress update timer - update every second
    _progressTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final provider = context.read<TVDisplayProvider>();
      if (provider.currentPlayer?.isPlaying == true) {
        provider.updateProgress();
      }
    });

    // Request focus to receive key events
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final provider = context.read<TVDisplayProvider>();
    if (provider.currentPlayer == null) return;

    switch (event.logicalKey) {
      // Playback controls
      case LogicalKeyboardKey.select:
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.space:
        provider.togglePlayPause();
        break;
      case LogicalKeyboardKey.arrowLeft:
        provider.previousTrack();
        break;
      case LogicalKeyboardKey.arrowRight:
        provider.nextTrack();
        break;
      // Volume controls
      case LogicalKeyboardKey.arrowUp:
        provider.volumeUp();
        break;
      case LogicalKeyboardKey.arrowDown:
        provider.volumeDown();
        break;
      case LogicalKeyboardKey.keyM:
        provider.toggleMute();
        break;
      // Shuffle and repeat
      case LogicalKeyboardKey.keyS:
        provider.toggleShuffle();
        break;
      case LogicalKeyboardKey.keyR:
        provider.cycleRepeatMode();
        break;
      // Seek controls
      case LogicalKeyboardKey.pageUp:
      case LogicalKeyboardKey.bracketLeft:
        provider.seek(-10);
        break;
      case LogicalKeyboardKey.pageDown:
      case LogicalKeyboardKey.bracketRight:
        provider.seek(10);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () => DebugLogsScreen.show(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white24,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 20,
                            ),
                          ),
                          child: const Text(
                            'View Logs',
                            style: TextStyle(fontSize: 24),
                          ),
                        ),
                        const SizedBox(width: 20),
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
                  ],
                ),
              );
            }

            // Get current track info
            final currentTrack = provider.currentTrack;
            final currentPlayer = provider.currentPlayer;

            // Calculate album art size (1:1 square, full height)
            final size = MediaQuery.of(context).size.height;

            // Show display screen
            return Row(
              children: [
                // Left side: 1:1 square album art
                SizedBox(
                  width: size,
                  height: size,
                  child: TVAlbumArt(
                    imageUrl: provider.albumArtUrl,
                    backgroundColor: provider.dominantColor,
                  ),
                ),

                // Right side: Track info and progress (remaining space)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (currentTrack != null) ...[
                          TVTrackInfo(
                            title: currentTrack.name,
                            artist: currentTrack.artistsString,
                            album: currentTrack.album?.name ?? '',
                            isPlaying: currentPlayer?.isPlaying ?? false,
                            accentColor: provider.dominantColor,
                          ),
                          const SizedBox(height: 40),
                          TVProgressBar(
                            progress: provider.progress,
                            duration: provider.duration,
                            currentTime: provider.currentTime,
                            accentColor: provider.dominantColor,
                          ),
                        ] else ...[
                          // Idle state - no track playing
                          Text(
                            currentPlayer?.name ?? 'Unknown Player',
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Ready to play',
                            style: TextStyle(
                              fontSize: 32,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Press Play on your remote to start playback',
                            style: TextStyle(
                              fontSize: 24,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      ),
    );
  }
}
