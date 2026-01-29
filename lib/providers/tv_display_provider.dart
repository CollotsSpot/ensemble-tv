import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:palette_generator/palette_generator.dart';
import '../constants/network.dart';
import '../models/media_item.dart';
import '../models/player.dart';
import '../services/music_assistant_api.dart';
import '../services/auth/auth_manager.dart';
import '../theme/palette_helper.dart';

/// Provider for TV display state.
/// Manages connection to Music Assistant, player selection, and current track display.
class TVDisplayProvider extends ChangeNotifier {
  static const String _selectedPlayerKey = 'selected_player_id';

  // Services
  MusicAssistantAPI? _api;
  AuthManager? _authManager;
  StreamSubscription? _playerUpdateSubscription;
  StreamSubscription? _connectionStateSubscription;

  // State
  String? _selectedPlayerId;
  Player? _currentPlayer;
  Track? _currentTrack;
  List<Player> _availablePlayers = [];
  Color? _dominantColor;

  // Loading/Error states
  bool _isLoading = false;
  String? _error;

  // Progress tracking
  double _progress = 0.0;
  Duration? _duration;
  Duration? _currentTime;

  // Getters
  String? get selectedPlayerId => _selectedPlayerId;
  Player? get currentPlayer => _currentPlayer;
  Track? get currentTrack => _currentTrack;
  List<Player> get availablePlayers => _availablePlayers;
  Color? get dominantColor => _dominantColor;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get progress => _progress;
  Duration? get duration => _duration;
  Duration? get currentTime => _currentTime;

  /// Initialize the provider - load saved player and connect
  Future<void> initialize() async {
    _setLoading(true);
    _clearError();

    try {
      // Load saved player ID
      final prefs = await SharedPreferences.getInstance();
      _selectedPlayerId = prefs.getString(_selectedPlayerKey);

      // Initialize auth manager
      _authManager = AuthManager();

      // TODO: Load server URL from settings
      final serverUrl = 'your-ma-server.com'; // Placeholder

      // Initialize API
      _api = MusicAssistantAPI(serverUrl, _authManager!);

      // Listen to connection state
      _connectionStateSubscription = _api!.connectionState.listen((state) {
        if (state == MAConnectionState.authenticated) {
          _onConnected();
        } else if (state == MAConnectionState.error) {
          _setError('Connection error');
        }
      });

      // Connect to Music Assistant
      await _api!.connect();

      // If no saved player, load players for selection
      if (_selectedPlayerId == null) {
        await loadPlayers();
      } else {
        // Subscribe to selected player updates
        await _subscribeToPlayer();
      }
    } catch (e) {
      _setError('Failed to initialize: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Load available players from Music Assistant
  Future<void> loadPlayers() async {
    if (_api == null) {
      _setError('Not connected to Music Assistant');
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      final players = await _api!.getPlayers();
      _availablePlayers = players;
      notifyListeners();
    } catch (e) {
      _setError('Failed to load players: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Select a player to control
  Future<void> selectPlayer(String playerId) async {
    _selectedPlayerId = playerId;

    // Save to preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedPlayerKey, playerId);

    // Subscribe to player updates
    await _subscribeToPlayer();
  }

  /// Subscribe to updates for the selected player
  Future<void> _subscribeToPlayer() async {
    if (_api == null || _selectedPlayerId == null) return;

    try {
      // Subscribe to player update events
      _playerUpdateSubscription = _api!.playerUpdates(_selectedPlayerId!).listen(_onPlayerUpdate);

      // Get current player state
      final players = await _api!.getPlayers();
      _currentPlayer = players.firstWhere(
        (p) => p.playerId == _selectedPlayerId,
        orElse: () => Player(
          playerId: _selectedPlayerId!,
          name: 'Unknown Player',
          available: false,
          powered: false,
          state: 'idle',
        ),
      );

      // Get current track if playing
      if (_currentPlayer!.currentItemId != null) {
        await _loadCurrentTrack();
      }

      notifyListeners();
    } catch (e) {
      _setError('Failed to subscribe to player: $e');
    }
  }

  /// Handle player update events from Music Assistant
  void _onPlayerUpdate(Map<String, dynamic> data) {
    final eventType = data['event_type'] as String?;
    final playerId = data['player_id'] as String?;

    if (playerId != _selectedPlayerId) return;

    switch (eventType) {
      case 'player_update':
        _updatePlayerState(data);
        break;
      case 'queue_update':
        _loadCurrentTrack();
        break;
    }
  }

  /// Update player state from event
  void _updatePlayerState(Map<String, dynamic> data) {
    final playerData = data['data'] as Map<String, dynamic>?;
    if (playerData == null) return;

    _currentPlayer = Player.fromJson(playerData);

    // Update progress
    if (_currentPlayer!.elapsedTime != null && _duration != null) {
      _currentTime = Duration(seconds: _currentPlayer!.currentElapsedTime.round());
      _progress = _currentTime!.inMilliseconds / _duration!.inMilliseconds;
    }

    notifyListeners();
  }

  /// Load current track info
  Future<void> _loadCurrentTrack() async {
    if (_api == null || _currentPlayer == null) return;

    try {
      final queue = await _api!.getPlayerQueue(_currentPlayer!.playerId);
      final item = queue.currentItem;

      if (item != null && item.track != _currentTrack) {
        _currentTrack = item.track;

        // Extract dominant color from album art
        if (_currentTrack!.image?.url != null) {
          _extractAlbumColor(_currentTrack!.image!.url);
        }

        // Update duration
        if (item.track.duration != null) {
          _duration = Duration(seconds: item.track.duration!.round());
        }

        notifyListeners();
      }
    } catch (e) {
      print('Failed to load current track: $e');
    }
  }

  /// Extract dominant color from album art
  Future<void> _extractAlbumColor(String imageUrl) async {
    try {
      final paletteGenerator = await PaletteGenerator.fromImageProvider(
        NetworkImage(imageUrl),
        size: const Size(100, 100), // Small size for performance
      );

      if (paletteGenerator.colors.isNotEmpty) {
        _dominantColor = paletteGenerator.dominantColor?.color;
        notifyListeners();
      }
    } catch (e) {
      print('Failed to extract color: $e');
    }
  }

  /// Send play/pause command to selected player
  Future<void> togglePlayPause() async {
    if (_api == null || _selectedPlayerId == null) return;

    try {
      await _api!.sendPlayerCommand(_selectedPlayerId!, {
        'command': 'play_pause',
      });
    } catch (e) {
      _setError('Failed to toggle play/pause: $e');
    }
  }

  /// Send next track command
  Future<void> nextTrack() async {
    if (_api == null || _selectedPlayerId == null) return;

    try {
      await _api!.sendPlayerCommand(_selectedPlayerId!, {
        'command': 'next',
      });
    } catch (e) {
      _setError('Failed to skip to next track: $e');
    }
  }

  /// Send previous track command
  Future<void> previousTrack() async {
    if (_api == null || _selectedPlayerId == null) return;

    try {
      await _api!.sendPlayerCommand(_selectedPlayerId!, {
        'command': 'previous',
      });
    } catch (e) {
      _setError('Failed to go to previous track: $e');
    }
  }

  void _onConnected() {
    _clearError();
    if (_selectedPlayerId != null) {
      _subscribeToPlayer();
    } else {
      loadPlayers();
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _playerUpdateSubscription?.cancel();
    _connectionStateSubscription?.cancel();
    _api?.dispose();
    super.dispose();
  }
}
