import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/player.dart';
import '../providers/tv_display_provider.dart';

/// Screen for selecting a player to control on first launch.
/// Shows a list of available Music Assistant players.
class PlayerSelectScreen extends StatefulWidget {
  const PlayerSelectScreen({super.key});

  @override
  State<PlayerSelectScreen> createState() => _PlayerSelectScreenState();
}

class _PlayerSelectScreenState extends State<PlayerSelectScreen> {
  @override
  void initState() {
    super.initState();
    // Load players when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TVDisplayProvider>().loadPlayers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Consumer<TVDisplayProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
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
        const SizedBox(height: 80),
        const Text(
          'Welcome to Ensemble TV',
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Which player should I control?',
          style: TextStyle(
            fontSize: 32,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 60),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 80),
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
        const Padding(
          padding: EdgeInsets.only(bottom: 40),
          child: Text(
            'Use D-pad to select, press OK',
            style: TextStyle(
              fontSize: 24,
              color: Colors.grey,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoPlayers(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.speaker_outlined,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 20),
          const Text(
            'No players found',
            style: TextStyle(
              fontSize: 32,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Make sure Music Assistant is running',
            style: TextStyle(
              fontSize: 24,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () {
              context.read<TVDisplayProvider>().loadPlayers();
            },
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

  Widget _buildError(BuildContext context, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red,
          ),
          const SizedBox(height: 20),
          Text(
            'Error: $error',
            style: const TextStyle(
              fontSize: 24,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () {
              context.read<TVDisplayProvider>().loadPlayers();
            },
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

  void _selectPlayer(
    BuildContext context,
    TVDisplayProvider provider,
    Player player,
  ) {
    provider.selectPlayer(player.playerId);
    // Navigation to display screen will be handled by the provider
  }
}

class _PlayerListItem extends StatelessWidget {
  final Player player;
  final VoidCallback onTap;

  const _PlayerListItem({
    required this.player,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: InkWell(
        onTap: onTap,
        focusColor: Colors.white24,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.white24,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.speaker,
                  size: 48,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 30),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.name,
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      player.provider ?? 'Unknown Player',
                      style: const TextStyle(
                        fontSize: 24,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              if (player.available)
                const Icon(
                  Icons.check_circle,
                  size: 40,
                  color: Colors.green,
                )
              else
                const Icon(
                  Icons.offline_bolt,
                  size: 40,
                  color: Colors.orange,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
