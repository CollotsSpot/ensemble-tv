import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/player.dart';
import '../providers/tv_display_provider.dart';
import '../services/settings_service.dart';
import 'settings_screen.dart';
import 'debug_logs_screen.dart';

/// Screen for selecting a player to control on first launch.
/// Shows a list of available Music Assistant players.
class PlayerSelectScreen extends StatefulWidget {
  const PlayerSelectScreen({super.key});

  @override
  State<PlayerSelectScreen> createState() => _PlayerSelectScreenState();
}

class _PlayerSelectScreenState extends State<PlayerSelectScreen> {
  bool _checkingServer = true;
  String? _serverUrl;

  @override
  void initState() {
    super.initState();
    _checkServerConfig();
  }

  Future<void> _checkServerConfig() async {
    final url = await SettingsService.getServerUrl();
    if (mounted) {
      setState(() {
        _serverUrl = url;
        _checkingServer = false;
      });

      // Initialize provider if server is configured
      if (_serverUrl != null && _serverUrl!.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<TVDisplayProvider>().initialize();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show configure server screen if no server URL is set
    if (!_checkingServer && (_serverUrl == null || _serverUrl!.isEmpty)) {
      // Use WidgetsBinding to show settings and re-check when returning
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final result = await Navigator.of(context).push<bool>(
          MaterialPageRoute(builder: (context) => const SettingsScreen()),
        );
        if (result == true && mounted) {
          _checkServerConfig();
        }
      });
      // Return loading indicator while showing settings
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Consumer<TVDisplayProvider>(
          builder: (context, provider, child) {
            if (_checkingServer || provider.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              );
            }

            if (provider.error != null) {
              return _buildError(context, provider.error!);
            }

            final players = provider.availablePlayers;

            if (players.isEmpty) {
              return _buildNoPlayers(context);
            }

            return _buildPlayerList(context, players, provider);
          },
        ),
      ),
    );
  }

  Widget _buildPlayerList(
    BuildContext context,
    List<Player> players,
    TVDisplayProvider provider,
  ) {
    return Column(
      children: [
        const SizedBox(height: 24),
        // Header with settings button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              const Text(
                'Select Player',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const Spacer(),
              IconButton(
                onPressed: () async {
                  await Navigator.of(context).push<bool>(
                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                  );
                  _checkServerConfig();
                },
                icon: const Icon(Icons.settings, color: Colors.white, size: 20),
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: players.length,
            itemBuilder: (context, index) {
              final player = players[index];
              return _PlayerListItem(
                player: player,
                onTap: () => _selectPlayer(context, provider, player),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNoPlayers(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.speaker_outlined,
            size: 32,
            color: colorScheme.onSurface.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          const Text(
            'No players found',
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
          const SizedBox(height: 6),
          const Text(
            'Make sure Music Assistant is running',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: () {
                  DebugLogsScreen.show(context);
                },
                icon: const Icon(Icons.bug_report_outlined, size: 16),
                label: const Text('Logs', style: TextStyle(fontSize: 13)),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white70,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  context.read<TVDisplayProvider>().loadPlayers();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: const Text('Retry', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, String error) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 32, color: colorScheme.error),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              error,
              style: const TextStyle(fontSize: 14, color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: () {
                  DebugLogsScreen.show(context);
                },
                icon: const Icon(Icons.bug_report_outlined, size: 16),
                label: const Text('Logs', style: TextStyle(fontSize: 13)),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white70,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  context.read<TVDisplayProvider>().loadPlayers();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: const Text('Retry', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _selectPlayer(
    BuildContext context,
    TVDisplayProvider provider,
    Player player,
  ) {
    provider.selectPlayer(player.playerId);
    // Navigation to display screen will be handled by the provider
  }
}

class _PlayerListItem extends StatefulWidget {
  final Player player;
  final VoidCallback onTap;

  const _PlayerListItem({
    required this.player,
    required this.onTap,
  });

  @override
  State<_PlayerListItem> createState() => _PlayerListItemState();
}

class _PlayerListItemState extends State<_PlayerListItem> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted && _isFocused != _focusNode.hasFocus) {
      setState(() => _isFocused = _focusNode.hasFocus);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Focus(
        focusNode: _focusNode,
        onKeyEvent: (node, event) {
          if (event is! KeyDownEvent) return KeyEventResult.ignored;
          if (event.logicalKey == LogicalKeyboardKey.select ||
              event.logicalKey == LogicalKeyboardKey.enter) {
            widget.onTap();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Builder(
          builder: (context) {
            final isFocused = _focusNode.hasFocus;
            return InkWell(
              onTap: widget.onTap,
              focusColor: colorScheme.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 80,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: isFocused
                      ? Border.all(color: colorScheme.primary, width: 3)
                      : null,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceVariant.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        widget.player.state == 'playing'
                            ? Icons.play_arrow
                            : Icons.speaker,
                        size: 24,
                        color: widget.player.state == 'playing'
                            ? Colors.green
                            : Colors.white70,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.player.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.player.provider ?? 'Unknown Player',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (widget.player.state == 'playing')
                      const Icon(Icons.volume_up, size: 24, color: Colors.green)
                    else if (widget.player.available)
                      const Icon(Icons.check_circle, size: 24, color: Colors.green)
                    else
                      const Icon(Icons.offline_bolt, size: 24, color: Colors.orange),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
