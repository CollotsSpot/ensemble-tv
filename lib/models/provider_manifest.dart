/// Represents a provider manifest from Music Assistant.
///
/// Contains metadata about a provider type including its icons.
/// This is separate from ProviderInstance which represents a configured
/// instance of a provider.
class ProviderManifest {
  /// The provider domain/type (e.g., "spotify", "tidal", "qobuz")
  final String domain;

  /// Display name for this provider type
  final String name;

  /// Description of the provider
  final String? description;

  /// SVG icon as XML string
  final String? iconSvg;

  /// SVG icon for dark theme as XML string
  final String? iconSvgDark;

  /// Monochrome SVG icon as XML string
  final String? iconSvgMonochrome;

  /// Material Design icon name (fallback)
  final String? icon;

  ProviderManifest({
    required this.domain,
    required this.name,
    this.description,
    this.iconSvg,
    this.iconSvgDark,
    this.iconSvgMonochrome,
    this.icon,
  });

  /// Whether this manifest has any SVG icon available
  bool get hasSvgIcon =>
      iconSvg != null || iconSvgDark != null || iconSvgMonochrome != null;

  /// Get the best available SVG icon for the given brightness
  /// Prefers dark icon for dark themes, falls back to regular or monochrome
  String? getSvgIcon({bool isDark = false}) {
    if (isDark && iconSvgDark != null) {
      return iconSvgDark;
    }
    return iconSvg ?? iconSvgMonochrome;
  }

  factory ProviderManifest.fromJson(Map<String, dynamic> json) {
    return ProviderManifest(
      domain: json['domain'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      iconSvg: json['icon_svg'] as String?,
      iconSvgDark: json['icon_svg_dark'] as String?,
      iconSvgMonochrome: json['icon_svg_monochrome'] as String?,
      icon: json['icon'] as String?,
    );
  }

  @override
  String toString() => 'ProviderManifest($domain: $name)';
}
