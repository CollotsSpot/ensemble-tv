/// Represents a music provider instance from Music Assistant.
///
/// Each provider (like Spotify, Tidal) can have multiple instances
/// (e.g., two different Spotify accounts). This class represents
/// a single provider instance with its unique ID.
class ProviderInstance {
  /// Unique identifier for this provider instance (e.g., "spotify--abc123")
  final String instanceId;

  /// The provider domain/type (e.g., "spotify", "tidal", "qobuz")
  final String domain;

  /// Display name for this instance (e.g., "Spotify (John's Account)")
  final String name;

  /// Whether this provider is currently available/connected
  final bool available;

  ProviderInstance({
    required this.instanceId,
    required this.domain,
    required this.name,
    required this.available,
  });

  /// Provider capabilities - maps domain to supported content types
  /// This determines which tabs/categories show which providers
  static const Map<String, Set<String>> providerCapabilities = {
    // Music streaming services (support artists, albums, tracks, playlists)
    // Spotify also has audiobooks and podcasts
    'spotify': {'artists', 'albums', 'tracks', 'playlists', 'audiobooks', 'podcasts'},
    'tidal': {'artists', 'albums', 'tracks', 'playlists'},
    'qobuz': {'artists', 'albums', 'tracks', 'playlists'},
    'deezer': {'artists', 'albums', 'tracks', 'playlists'},
    'ytmusic': {'artists', 'albums', 'tracks', 'playlists', 'podcasts'},
    'soundcloud': {'artists', 'albums', 'tracks', 'playlists'},
    'apple_music': {'artists', 'albums', 'tracks', 'playlists', 'podcasts'},
    'amazon_music': {'artists', 'albums', 'tracks', 'playlists'},
    // Self-hosted media servers (can have music, audiobooks, and podcasts)
    'plex': {'artists', 'albums', 'tracks', 'playlists', 'audiobooks', 'podcasts'},
    'jellyfin': {'artists', 'albums', 'tracks', 'playlists', 'audiobooks', 'podcasts'},
    'emby': {'artists', 'albums', 'tracks', 'playlists', 'audiobooks', 'podcasts'},
    // Music-only servers
    'subsonic': {'artists', 'albums', 'tracks', 'playlists'},
    'opensubsonic': {'artists', 'albums', 'tracks', 'playlists'},
    'navidrome': {'artists', 'albums', 'tracks', 'playlists'},
    'filesystem': {'artists', 'albums', 'tracks', 'playlists'},
    // Audiobook and podcast providers
    'audiobookshelf': {'audiobooks', 'podcasts'},
    'itunes_podcasts': {'podcasts'},
    // Radio providers (tunein also has podcasts)
    'tunein': {'radio', 'podcasts'},
    'radiobrowser': {'radio'},
    // Player/system providers (no library content)
    'snapcast': <String>{},
    'fully_kiosk': <String>{},
  };

  /// Known music provider domains that provide library content
  static const Set<String> musicProviderDomains = {
    // Streaming services
    'spotify',
    'tidal',
    'qobuz',
    'deezer',
    'ytmusic',
    'soundcloud',
    'apple_music',
    'amazon_music',
    // Self-hosted / local
    'plex',
    'subsonic',
    'opensubsonic',
    'jellyfin',
    'emby',
    'navidrome',
    'audiobookshelf',
    'filesystem',
    'itunes_podcasts',
    // Other
    'tunein',
    'radiobrowser',
    'snapcast',
    'fully_kiosk',
  };

  /// Whether this is a music provider (vs. player provider, metadata provider, etc.)
  bool get isMusicProvider => musicProviderDomains.contains(domain);

  /// Get supported content types for this provider
  Set<String> get supportedContentTypes =>
      providerCapabilities[domain] ?? <String>{};

  /// Check if this provider supports a specific content type/category
  bool supportsContentType(String category) =>
      supportedContentTypes.contains(category);

  factory ProviderInstance.fromJson(Map<String, dynamic> json) {
    return ProviderInstance(
      instanceId: json['instance_id'] as String? ?? '',
      domain: json['domain'] as String? ?? json['type'] as String? ?? '',
      name: json['name'] as String? ?? json['instance_id'] as String? ?? 'Unknown',
      available: json['available'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'instance_id': instanceId,
      'domain': domain,
      'name': name,
      'available': available,
    };
  }

  @override
  String toString() => 'ProviderInstance($instanceId: $name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProviderInstance &&
          runtimeType == other.runtimeType &&
          instanceId == other.instanceId;

  @override
  int get hashCode => instanceId.hashCode;
}
