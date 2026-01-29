import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/tv_display_provider.dart';
import 'services/key_event_handler.dart';
import 'screens/player_select_screen.dart';
import 'screens/display_screen.dart';

void main() {
  runApp(const EnsembleTVApp());
}

class EnsembleTVApp extends StatefulWidget {
  const EnsembleTVApp({super.key});

  @override
  State<EnsembleTVApp> createState() => _EnsembleTVAppState();
}

class _EnsembleTVAppState extends State<EnsembleTVApp> {
  late final TVRemoteHandler _remoteHandler;
  final TVDisplayProvider _displayProvider = TVDisplayProvider();

  @override
  void initState() {
    super.initState();

    // Set up remote control handler
    _remoteHandler = TVRemoteHandler(
      onCommand: (command) {
        _handleRemoteCommand(command);
      },
    );
  }

  void _handleRemoteCommand(String command) {
    switch (command) {
      case 'playPause':
        _displayProvider.togglePlayPause();
        break;
      case 'next':
        _displayProvider.nextTrack();
        break;
      case 'previous':
        _displayProvider.previousTrack();
        break;
      case 'showMenu':
        _showMenu();
        break;
      case 'stop':
        _displayProvider.togglePlayPause(); // Toggle again to stop
        break;
    }
  }

  void _showMenu() {
    // TODO: Show menu dialog with options:
    // - Change Player
    // - Settings
    // - Exit
    print('Menu pressed - show options');
  }

  @override
  void dispose() {
    _remoteHandler.dispose();
    _displayProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _displayProvider,
      child: MaterialApp(
        title: 'Ensemble TV',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const _AppRouter(),
      ),
    );
  }
}

class _AppRouter extends StatelessWidget {
  const _AppRouter();

  @override
  Widget build(BuildContext context) {
    return Consumer<TVDisplayProvider>(
      builder: (context, provider, child) {
        // If no player selected, show player selection screen
        if (provider.selectedPlayerId == null) {
          return const PlayerSelectScreen();
        }

        // Otherwise show display screen
        return const DisplayScreen();
      },
    );
  }
}
