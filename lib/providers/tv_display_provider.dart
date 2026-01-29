import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:palette_generator/palette_generator.dart';
import '../models/media_item.dart';
import '../models/player.dart';
import '../services/music_assistant_api.dart';
import '../services/auth/auth_manager.dart';
import '../services/settings_service.dart';

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
  String? _albumArtUrl;

  // Loading/Error states
  bool _isLoading = false;
  bool _isInitializing = false;
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
  MusicAssistantAPI? get api => _api;
  String? get albumArtUrl => _albumArtUrl;

  /// Update progress based on current player state
  void updateProgress() {
    if (_currentPlayer == null || _duration == null) return;

    // Calculate progress based on elapsed time and duration
    final elapsed = _currentPlayer!.currentElapsedTime;
    if (elapsed != null && _duration != null) {
      _currentTime = Duration(seconds: elapsed.round());
      _progress = _currentTime!.inMilliseconds / _duration!.inMilliseconds;
      notifyListeners();
    }
  }

  /// Initialize the provider - load saved player and connect
  Future<void> initialize() async {
    // Guard against concurrent initialization
    if (_isInitializing) {
      print('[TVDisplayProvider] Already initializing, skipping');
      return;
    }

    _isInitializing = true;
    _setLoading(true);
    _clearError();

    try {
      // Load saved player ID
      final prefs = await SharedPreferences.getInstance();
      _selectedPlayerId = prefs.getString(_selectedPlayerKey);

      // Initialize auth manager
      _authManager = AuthManager();

      // Load server URL from settings
      final serverUrl = await SettingsService.getServerUrl();
      if (serverUrl == null || serverUrl.isEmpty) {
        _setError('Please configure your Music Assistant server in Settings');
        _setLoading(false);
        return;
      }

      // Load saved token
      final token = await SettingsService.getToken();
      if (token != null && token.isNotEmpty && _authManager != null) {
        print('[TVDisplayProvider] Loaded token from storage: ${token.substring(0, 10)}...');
        _authManager!.setToken(token);
      } else {
        print('[TVDisplayProvider] No token found in storage (token=$token)');
      }

      // Dispose old API connection if exists
      _api?.dispose();
      _connectionStateSubscription?.cancel();

      // Initialize API
      _api = MusicAssistantAPI(serverUrl, _authManager!);

      // Log token status before connecting
      print('[TVDisplayProvider] AuthManager hasCredentials: ${_authManager!.hasCredentials}');
      print('[TVDisplayProvider] AuthManager token: ${_authManager!.token?.substring(0, 10) ?? "null"}...');

      // Listen to connection state
      _connectionStateSubscription = _api!.connectionState.listen((state) {
        print('[TVDisplayProvider] Connection state changed: $state');
        if (state == MAConnectionState.authenticated) {
          print('[TVDisplayProvider] Authenticated - calling _onConnected()');
          _onConnected();
        } else if (state == MAConnectionState.connected) {
          // Connected but may need auth or may already be authenticated
          print('[TVDisplayProvider] Connected - isAuthenticated: ${_api!.isAuthenticated}, authRequired: ${_api!.authRequired}');
          if (_api!.isAuthenticated || !_api!.authRequired) {
            // Already authenticated or no auth needed
            print('[TVDisplayProvider] No auth needed - calling _onConnected()');
            _onConnected();
          } else {
            // Authentication required - trigger it
            print('[TVDisplayProvider] Authentication required - triggering auth...');
            _handleAuthentication();
          }
        } else if (state == MAConnectionState.error) {
          _setError('Connection error');
        }
      });

      // Connect to Music Assistant
      await _api!.connect();
    } catch (e) {
      _setError('Failed to initialize: $e');
    } finally {
      _isInitializing = false;
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
    _selectedPlayerId = playerId.isEmpty ? null : playerId;

    // Clear current player and track state
    _currentPlayer = null;
    _currentTrack = null;
    _dominantColor = null;
    _progress = 0.0;
    _duration = null;
    _currentTime = null;

    // Save to preferences (or clear if empty)
    final prefs = await SharedPreferences.getInstance();
    if (playerId.isEmpty) {
      await prefs.remove(_selectedPlayerKey);
    } else {
      await prefs.setString(_selectedPlayerKey, playerId);
    }

    // Subscribe to player updates if a player was selected
    if (_selectedPlayerId != null) {
      await _subscribeToPlayer();
    } else {
      notifyListeners();
    }
  }

  /// Subscribe to updates for the selected player
  Future<void> _subscribeToPlayer() async {
    if (_api == null || _selectedPlayerId == null) return;

    try {
      // Subscribe to player update events
      _playerUpdateSubscription = _api!.playerUpdatedEvents.listen(_onPlayerUpdate);

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
    final playerId = data['player_id'] as String?;

    if (playerId != _selectedPlayerId) return;

    final oldItemId = _currentPlayer?.currentItemId;
    // Update player state
    _currentPlayer = Player.fromJson(data);
    final newItemId = _currentPlayer!.currentItemId;

    // Check if track changed
    if (oldItemId != newItemId && newItemId != null) {
      // Track changed - reload track info
      _loadCurrentTrack();
    }

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
      final queue = await _api!.getQueue(_currentPlayer!.playerId);
      final item = queue?.currentItem;

      if (item != null && item.track != _currentTrack) {
        _currentTrack = item.track;

        // Get album art URL and extract dominant color
        _albumArtUrl = _getAlbumArtUrl(_currentTrack);
        if (_albumArtUrl != null) {
          _extractAlbumColor(_albumArtUrl!);
        }

        // Update duration
        if (item.track.duration != null) {
          _duration = item.track.duration;
        }

        notifyListeners();
      }
    } catch (e) {
      // Ignore errors loading track
    }
  }

  /// Get album art URL from track
  String? _getAlbumArtUrl(Track? track) {
    if (track == null || _api == null) {
      print('[TVDisplayProvider] _getAlbumArtUrl: track=$track, api=$_api');
      return null;
    }

    print('[TVDisplayProvider] _getAlbumArtUrl: track has metadata=${track.metadata != null}');

    // Use the API's getImageUrl method for proper authentication
    try {
      final imageUrl = _api!.getImageUrl(track, size: 512);
      print('[TVDisplayProvider] getImageUrl returned: $imageUrl');
      if (imageUrl != null) return imageUrl;
    } catch (e) {
      print('[TVDisplayProvider] getImageUrl error: $e');
    }

    // Fallback: Try to get image from metadata
    final metadata = track.metadata;
    if (metadata != null) {
      final image = metadata['image'] as Map<String, dynamic>?;
      if (image != null) {
        final url = image['url'] as String?;
        print('[TVDisplayProvider] Using fallback image URL: $url');
        return url;
      }
    }

    // Try album's image
    if (track.album?.metadata != null) {
      final albumImage = track.album!.metadata!['image'] as Map<String, dynamic>?;
      if (albumImage != null) {
        final url = albumImage['url'] as String?;
        print('[TVDisplayProvider] Using album fallback image URL: $url');
        return url;
      }
    }

    print('[TVDisplayProvider] No image URL found');
    return null;
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
      // Ignore color extraction errors
    }
  }

  /// Send play/pause command to selected player
  Future<void> togglePlayPause() async {
    if (_api == null || _currentPlayer == null) return;

    try {
      if (_currentPlayer!.isPlaying) {
        await _api!.pausePlayer(_currentPlayer!.playerId);
      } else {
        await _api!.resumePlayer(_currentPlayer!.playerId);
      }
    } catch (e) {
      _setError('Failed to toggle play/pause: $e');
    }
  }

  /// Send next track command
  Future<void> nextTrack() async {
    if (_api == null || _currentPlayer == null) return;

    try {
      await _api!.nextTrack(_currentPlayer!.playerId);
    } catch (e) {
      _setError('Failed to skip to next track: $e');
    }
  }

  /// Send previous track command
  Future<void> previousTrack() async {
    if (_api == null || _currentPlayer == null) return;

    try {
      await _api!.previousTrack(_currentPlayer!.playerId);
    } catch (e) {
      _setError('Failed to go to previous track: $e');
    }
  }

  /// Handle authentication after WebSocket connection
  Future<void> _handleAuthentication() async {
    if (_authManager == null || _api == null) {
      print('[TVDisplayProvider] AuthManager or API is null, cannot authenticate');
      _setError('Authentication failed');
      return;
    }

    final token = _authManager!.token;
    if (token == null || token.isEmpty) {
      print('[TVDisplayProvider] No token available for authentication');
      _setError('No authentication token found. Please login again.');
      return;
    }

    try {
      print('[TVDisplayProvider] Authenticating with token...');
      final success = await _api!.authenticateWithToken(token);
      if (success) {
        print('[TVDisplayProvider] Authentication successful');
      } else {
        print('[TVDisplayProvider] Authentication failed - token may be invalid');
        _setError('Authentication failed. Please login again.');
      }
    } catch (e) {
      print('[TVDisplayProvider] Authentication error: $e');
      _setError('Authentication error: $e');
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
