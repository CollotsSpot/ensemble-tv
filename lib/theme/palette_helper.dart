import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_color_utilities/material_color_utilities.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:image/image.dart' as img;
import 'package:http/http.dart' as http;
import '../services/debug_logger.dart';

final _logger = DebugLogger();

/// Minimum contrast ratio for UI components (WCAG 2.1 Level AA)
const double _minContrastRatio = 3.0;

/// Minimum chroma for primary colors to ensure they're visually distinct
/// Material Design 3 uses 48 for vibrant, but we use 36 as a balance
const double _minPrimaryChroma = 36.0;

/// Minimum chroma for surface/container colors (lower is fine for backgrounds)
const double _minSurfaceChroma = 6.0;

/// Extracted adaptive colors from album art
class AdaptiveColors {
  final Color primary;       // Main accent color (vibrant)
  final Color surface;       // Background color
  final Color onSurface;     // Text color on background
  final Color miniPlayer;    // Darker version for mini player

  const AdaptiveColors({
    required this.primary,
    required this.surface,
    required this.onSurface,
    required this.miniPlayer,
  });

  static const fallback = AdaptiveColors(
    primary: Color(0xFF604CEC),
    surface: Color(0xFF121212),
    onSurface: Colors.white,
    miniPlayer: Color(0xFF1a1a1a),
  );
}

/// Data class to pass color extraction results from isolate
/// (Color objects can't be passed directly between isolates)
class _ExtractedColors {
  final int vibrantColor;
  final int lightVibrantColor;
  final int dominantColor;
  final int darkMutedColor;
  final int mutedColor;
  final int lightMutedColor;

  const _ExtractedColors({
    required this.vibrantColor,
    required this.lightVibrantColor,
    required this.dominantColor,
    required this.darkMutedColor,
    required this.mutedColor,
    required this.lightMutedColor,
  });
}

/// Calculate WCAG 2.1 contrast ratio between two colors
double _contrastRatio(Color c1, Color c2) {
  final l1 = c1.computeLuminance();
  final l2 = c2.computeLuminance();
  final lighter = math.max(l1, l2);
  final darker = math.min(l1, l2);
  return (lighter + 0.05) / (darker + 0.05);
}

/// Helper to get contrasting text color based on WCAG contrast ratio
Color getContrastingTextColor(Color backgroundColor) {
  // Calculate contrast with both black and white, pick the one with better contrast
  final contrastWithWhite = _contrastRatio(backgroundColor, Colors.white);
  final contrastWithBlack = _contrastRatio(backgroundColor, Colors.black);
  return contrastWithWhite >= contrastWithBlack ? Colors.white : Colors.black;
}

/// Adjust a color's tone using HCT to ensure minimum contrast against a background
/// Uses binary search to find the MINIMUM tone adjustment needed (preserves color identity)
Color _ensureContrastHct(Color foreground, Color background, {double minRatio = _minContrastRatio}) {
  final fgHct = Hct.fromInt(foreground.value);
  final bgHct = Hct.fromInt(background.value);

  // Ensure foreground has enough chroma to be visually distinct
  final chroma = math.max(fgHct.chroma, _minPrimaryChroma);

  final currentRatio = _contrastRatio(foreground, background);
  if (currentRatio >= minRatio) {
    // Already has sufficient contrast, just ensure chroma
    if (fgHct.chroma < _minPrimaryChroma) {
      return Color(Hct.from(fgHct.hue, chroma, fgHct.tone).toInt());
    }
    return foreground;
  }

  // For dark backgrounds (tone < 50), we need lighter foreground
  // For light backgrounds (tone >= 50), we need darker foreground
  final bgIsDark = bgHct.tone < 50;

  // Binary search for the minimum tone that achieves target contrast
  double lo, hi;
  if (bgIsDark) {
    // Search upward from current tone toward white
    lo = fgHct.tone;
    hi = 100.0;
  } else {
    // Search downward from current tone toward black
    lo = 0.0;
    hi = fgHct.tone;
  }

  double bestTone = bgIsDark ? hi : lo; // Fallback to extreme if needed

  for (int i = 0; i < 20; i++) {
    final mid = (lo + hi) / 2;
    final testColor = Hct.from(fgHct.hue, chroma, mid);
    final testRatio = _contrastRatio(Color(testColor.toInt()), background);

    if (bgIsDark) {
      // We want lighter - if mid works, try lower (closer to original)
      if (testRatio >= minRatio) {
        bestTone = mid;
        hi = mid; // Try to find a lower tone that still works
      } else {
        lo = mid; // Need to go lighter
      }
    } else {
      // We want darker - if mid works, try higher (closer to original)
      if (testRatio >= minRatio) {
        bestTone = mid;
        lo = mid; // Try to find a higher tone that still works
      } else {
        hi = mid; // Need to go darker
      }
    }

    if (hi - lo < 0.5) break; // Precision reached
  }

  return Color(Hct.from(fgHct.hue, chroma, bestTone).toInt());
}

/// Ensure a color has minimum chroma (colorfulness) for primary use
Color _ensureMinChroma(Color color) {
  final hct = Hct.fromInt(color.value);
  if (hct.chroma >= _minPrimaryChroma) {
    return color;
  }
  final adjusted = Hct.from(hct.hue, _minPrimaryChroma, hct.tone);
  return Color(adjusted.toInt());
}

/// Top-level function for isolate-based color extraction
/// Must be top-level or static to work with compute()
_ExtractedColors? _extractColorsInIsolate(Uint8List imageBytes) {
  try {
    // Decode image using pure Dart image package
    final image = img.decodeImage(imageBytes);
    if (image == null) return null;

    // Resize for faster processing (max 100x100)
    final resized = img.copyResize(
      image,
      width: image.width > 100 ? 100 : image.width,
      height: image.height > 100 ? 100 : image.height,
      interpolation: img.Interpolation.average,
    );

    // Extract color histogram
    final colorCounts = <int, int>{};
    for (int y = 0; y < resized.height; y++) {
      for (int x = 0; x < resized.width; x++) {
        final pixel = resized.getPixel(x, y);
        // Quantize to reduce color space (shift off lower 4 bits)
        final r = (pixel.r.toInt() >> 4) << 4;
        final g = (pixel.g.toInt() >> 4) << 4;
        final b = (pixel.b.toInt() >> 4) << 4;
        final quantized = (0xFF << 24) | (r << 16) | (g << 8) | b;
        colorCounts[quantized] = (colorCounts[quantized] ?? 0) + 1;
      }
    }

    // Sort colors by frequency
    final sortedColors = colorCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sortedColors.isEmpty) return null;

    // Categorize colors by HSL properties
    int? vibrant, lightVibrant, dominant, darkMuted, muted, lightMuted;

    for (final entry in sortedColors.take(32)) {
      final color = entry.key;
      final r = (color >> 16) & 0xFF;
      final g = (color >> 8) & 0xFF;
      final b = color & 0xFF;

      // Calculate HSL manually
      final rf = r / 255.0;
      final gf = g / 255.0;
      final bf = b / 255.0;
      final maxC = [rf, gf, bf].reduce((a, b) => a > b ? a : b);
      final minC = [rf, gf, bf].reduce((a, b) => a < b ? a : b);
      final lightness = (maxC + minC) / 2;
      final saturation = maxC == minC ? 0.0 :
          (lightness > 0.5
              ? (maxC - minC) / (2 - maxC - minC)
              : (maxC - minC) / (maxC + minC));

      // Categorize based on saturation and lightness
      if (saturation > 0.5 && lightness > 0.3 && lightness < 0.7) {
        vibrant ??= color;
      }
      if (saturation > 0.4 && lightness > 0.6) {
        lightVibrant ??= color;
      }
      if (saturation < 0.4 && lightness < 0.3) {
        darkMuted ??= color;
      }
      if (saturation < 0.4 && lightness > 0.3 && lightness < 0.7) {
        muted ??= color;
      }
      if (saturation < 0.4 && lightness > 0.7) {
        lightMuted ??= color;
      }

      // First color is dominant
      dominant ??= color;
    }

    // Fallback to dominant for any missing colors
    final defaultColor = dominant ?? sortedColors.first.key;

    return _ExtractedColors(
      vibrantColor: vibrant ?? defaultColor,
      lightVibrantColor: lightVibrant ?? vibrant ?? defaultColor,
      dominantColor: dominant ?? defaultColor,
      darkMutedColor: darkMuted ?? defaultColor,
      mutedColor: muted ?? defaultColor,
      lightMutedColor: lightMuted ?? muted ?? defaultColor,
    );
  } catch (e) {
    return null;
  }
}

class PaletteHelper {
  /// Cache for downloaded image bytes to avoid re-downloading
  static final Map<String, Uint8List> _imageCache = {};
  static const int _maxCacheSize = 20;

  /// Cache for extracted color schemes to avoid re-processing
  static final Map<String, (ColorScheme, ColorScheme)> _colorSchemeCache = {};
  static const int _maxColorSchemeCacheSize = 30;

  /// Extract color schemes from a URL using isolate-based processing
  /// This is the preferred method as it doesn't block the main thread
  /// Results are cached for instant retrieval on subsequent calls
  static Future<(ColorScheme, ColorScheme)?> extractColorSchemesFromUrl(String imageUrl) async {
    try {
      // Check color scheme cache first for instant return
      final cachedSchemes = _colorSchemeCache[imageUrl];
      if (cachedSchemes != null) {
        return cachedSchemes;
      }

      // Check image bytes cache
      Uint8List? imageBytes = _imageCache[imageUrl];

      if (imageBytes == null) {
        // Download image bytes
        final response = await http.get(Uri.parse(imageUrl));
        if (response.statusCode != 200) {
          _logger.warning('Failed to download image: ${response.statusCode}', context: 'Palette');
          return null;
        }
        imageBytes = response.bodyBytes;

        // Cache the bytes
        if (_imageCache.length >= _maxCacheSize) {
          _imageCache.remove(_imageCache.keys.first);
        }
        _imageCache[imageUrl] = imageBytes;
      }

      // Extract colors in isolate
      final extractedColors = await compute(_extractColorsInIsolate, imageBytes);
      if (extractedColors == null) return null;

      // Convert to ColorSchemes on main thread
      final colorSchemes = _buildColorSchemes(extractedColors);

      // Cache the color schemes for instant access next time
      if (_colorSchemeCache.length >= _maxColorSchemeCacheSize) {
        _colorSchemeCache.remove(_colorSchemeCache.keys.first);
      }
      _colorSchemeCache[imageUrl] = colorSchemes;

      return colorSchemes;
    } catch (e) {
      _logger.warning('Failed to extract colors from URL: $e', context: 'Palette');
      return null;
    }
  }

  /// Build ColorSchemes from extracted color data using HCT color space
  static (ColorScheme, ColorScheme) _buildColorSchemes(_ExtractedColors colors) {
    // Convert int colors to Color objects
    final vibrant = Color(colors.vibrantColor);
    final lightVibrant = Color(colors.lightVibrantColor);
    final dominant = Color(colors.dominantColor);
    final darkMuted = Color(colors.darkMutedColor);
    final muted = Color(colors.mutedColor);
    final lightMuted = Color(colors.lightMutedColor);

    // Get primary color - prefer vibrant, then lightVibrant, then dominant
    Color primary = vibrant;
    final vibrantHct = Hct.fromInt(vibrant.value);
    if (vibrantHct.tone < 20 || vibrantHct.chroma < 8) {
      primary = lightVibrant;
    }
    final primaryHct = Hct.fromInt(primary.value);
    if (primaryHct.tone < 20 || primaryHct.chroma < 8) {
      primary = dominant;
    }

    // Use HCT for perceptually accurate color adjustment
    // Ensure minimum chroma (colorfulness) so colors aren't muddy
    Color adjustedPrimary = _ensureMinChroma(primary);

    // Build dark mode colors using HCT
    final darkMutedHct = Hct.fromInt(darkMuted.value);
    final darkSurface = Color(Hct.from(
      darkMutedHct.hue,
      math.min(darkMutedHct.chroma, _minSurfaceChroma), // Low chroma for surface
      math.max(darkMutedHct.tone * 0.3, 5.0).clamp(5.0, 15.0), // Very dark
    ).toInt());
    final darkMiniPlayer = Color(Hct.from(
      darkMutedHct.hue,
      (darkMutedHct.chroma * 1.2).clamp(4, 16),
      30, // Fixed tone for consistency
    ).toInt());

    // Build light mode colors using HCT
    final lightMutedHct = Hct.fromInt(lightMuted.value);
    final lightSurface = Color(Hct.from(
      lightMutedHct.hue,
      math.min(lightMutedHct.chroma, _minSurfaceChroma),
      95, // Very light
    ).toInt());
    final lightMiniPlayer = Color(Hct.from(
      lightMutedHct.hue,
      (lightMutedHct.chroma * 1.2).clamp(4, 16),
      75,
    ).toInt());

    // Generate secondary container colors using HCT
    // Dark secondary container at tone 25 for tonal buttons
    final primaryHctFinal = Hct.fromInt(adjustedPrimary.value);
    final darkSecondaryContainer = Color(Hct.from(
      primaryHctFinal.hue,
      (primaryHctFinal.chroma * 0.4).clamp(4, 16),
      25, // Fixed tone for dark mode tonal buttons
    ).toInt());
    final lightSecondaryContainer = Color(Hct.from(
      primaryHctFinal.hue,
      (primaryHctFinal.chroma * 0.3).clamp(4, 12),
      90, // Fixed tone for light mode tonal buttons
    ).toInt());

    // CRITICAL: Ensure primary has sufficient contrast against secondaryContainer
    // This guarantees highlighted icons are visible on tonal buttons
    final darkAdjustedPrimary = _ensureContrastHct(
      adjustedPrimary,
      darkSecondaryContainer,
      minRatio: _minContrastRatio,
    );
    final lightAdjustedPrimary = _ensureContrastHct(
      adjustedPrimary,
      lightSecondaryContainer,
      minRatio: _minContrastRatio,
    );

    // Determine contrasting text colors
    final lightOnPrimary = getContrastingTextColor(lightAdjustedPrimary);
    final darkOnPrimary = getContrastingTextColor(darkAdjustedPrimary);
    final lightOnMiniPlayer = getContrastingTextColor(lightMiniPlayer);
    final darkOnMiniPlayer = getContrastingTextColor(darkMiniPlayer);

    final lightScheme = ColorScheme(
      brightness: Brightness.light,
      primary: lightAdjustedPrimary,
      onPrimary: lightOnPrimary,
      secondary: lightAdjustedPrimary.withOpacity(0.8),
      onSecondary: lightOnPrimary,
      secondaryContainer: lightSecondaryContainer,
      onSecondaryContainer: Colors.black87,
      error: Colors.red,
      onError: Colors.white,
      surface: lightSurface,
      onSurface: Colors.black87,
      primaryContainer: lightMiniPlayer,
      onPrimaryContainer: lightOnMiniPlayer,
    );

    final darkScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: darkAdjustedPrimary,
      onPrimary: darkOnPrimary,
      secondary: darkAdjustedPrimary.withOpacity(0.8),
      onSecondary: darkOnPrimary,
      secondaryContainer: darkSecondaryContainer,
      onSecondaryContainer: Colors.white,
      error: Colors.redAccent,
      onError: Colors.black,
      surface: darkSurface,
      onSurface: Colors.white,
      primaryContainer: darkMiniPlayer,
      onPrimaryContainer: darkOnMiniPlayer,
    );

    return (lightScheme, darkScheme);
  }

  /// Clear all caches (image bytes and color schemes)
  static void clearCache() {
    _imageCache.clear();
    _colorSchemeCache.clear();
  }

  /// Extract a color palette from an image with higher color count for better variety
  /// NOTE: This runs on the main thread. Prefer extractColorSchemesFromUrl for better performance.
  static Future<PaletteGenerator?> extractPalette(ImageProvider imageProvider) async {
    try {
      final palette = await PaletteGenerator.fromImageProvider(
        imageProvider,
        maximumColorCount: 32, // Increased from 20 for more color variety
      );
      return palette;
    } catch (e) {
      _logger.warning('Failed to extract palette: $e', context: 'Palette');
      return null;
    }
  }

  /// Extract actual colors from the palette using HCT color space
  static AdaptiveColors? extractAdaptiveColors(PaletteGenerator? palette, {required bool isDark}) {
    if (palette == null) return null;

    // Get primary color - prefer vibrant, then dominant
    final Color primary = palette.vibrantColor?.color ??
                         palette.lightVibrantColor?.color ??
                         palette.dominantColor?.color ??
                         const Color(0xFF604CEC);

    // Use HCT for perceptually accurate color adjustment
    // Ensure minimum chroma (colorfulness) so colors aren't muddy
    Color adjustedPrimary = _ensureMinChroma(primary);

    if (isDark) {
      // Dark mode: use dark muted colors for background
      final Color surfaceBase = palette.darkMutedColor?.color ??
                                palette.mutedColor?.color ??
                                const Color(0xFF121212);

      // Build surface colors using HCT
      final surfaceHct = Hct.fromInt(surfaceBase.value);
      final Color surface = Color(Hct.from(
        surfaceHct.hue,
        math.min(surfaceHct.chroma, _minSurfaceChroma),
        math.max(surfaceHct.tone * 0.3, 5.0).clamp(5.0, 15.0),
      ).toInt());

      final Color miniPlayer = Color(Hct.from(
        surfaceHct.hue,
        (surfaceHct.chroma * 1.2).clamp(4, 16),
        30,
      ).toInt());

      return AdaptiveColors(
        primary: adjustedPrimary,
        surface: surface,
        onSurface: Colors.white,
        miniPlayer: miniPlayer,
      );
    } else {
      // Light mode: use light muted colors
      final Color surfaceBase = palette.lightMutedColor?.color ??
                                palette.mutedColor?.color ??
                                Colors.white;

      final surfaceHct = Hct.fromInt(surfaceBase.value);
      final Color surface = Color(Hct.from(
        surfaceHct.hue,
        math.min(surfaceHct.chroma, _minSurfaceChroma),
        95,
      ).toInt());

      final Color miniPlayer = Color(Hct.from(
        surfaceHct.hue,
        (surfaceHct.chroma * 1.2).clamp(4, 16),
        75,
      ).toInt());

      return AdaptiveColors(
        primary: adjustedPrimary,
        surface: surface,
        onSurface: Colors.black87,
        miniPlayer: miniPlayer,
      );
    }
  }

  /// Generate color schemes from a palette using HCT color space
  static (ColorScheme, ColorScheme)? generateColorSchemes(PaletteGenerator? palette) {
    if (palette == null) return null;

    final lightColors = extractAdaptiveColors(palette, isDark: false);
    final darkColors = extractAdaptiveColors(palette, isDark: true);

    if (lightColors == null || darkColors == null) return null;

    // Generate secondary container colors using HCT
    final lightPrimaryHct = Hct.fromInt(lightColors.primary.value);
    final lightSecondaryContainer = Color(Hct.from(
      lightPrimaryHct.hue,
      (lightPrimaryHct.chroma * 0.3).clamp(4, 12),
      90, // Fixed tone for light mode tonal buttons
    ).toInt());

    final darkPrimaryHct = Hct.fromInt(darkColors.primary.value);
    final darkSecondaryContainer = Color(Hct.from(
      darkPrimaryHct.hue,
      (darkPrimaryHct.chroma * 0.4).clamp(4, 16),
      25, // Fixed tone for dark mode tonal buttons
    ).toInt());

    // CRITICAL: Ensure primary has sufficient contrast against secondaryContainer
    final lightAdjustedPrimary = _ensureContrastHct(
      lightColors.primary,
      lightSecondaryContainer,
      minRatio: _minContrastRatio,
    );
    final darkAdjustedPrimary = _ensureContrastHct(
      darkColors.primary,
      darkSecondaryContainer,
      minRatio: _minContrastRatio,
    );

    // Determine contrasting text colors
    final lightOnPrimary = getContrastingTextColor(lightAdjustedPrimary);
    final darkOnPrimary = getContrastingTextColor(darkAdjustedPrimary);
    final lightOnMiniPlayer = getContrastingTextColor(lightColors.miniPlayer);
    final darkOnMiniPlayer = getContrastingTextColor(darkColors.miniPlayer);

    final lightScheme = ColorScheme(
      brightness: Brightness.light,
      primary: lightAdjustedPrimary,
      onPrimary: lightOnPrimary,
      secondary: lightAdjustedPrimary.withOpacity(0.8),
      onSecondary: lightOnPrimary,
      secondaryContainer: lightSecondaryContainer,
      onSecondaryContainer: Colors.black87,
      error: Colors.red,
      onError: Colors.white,
      surface: lightColors.surface,
      onSurface: lightColors.onSurface,
      primaryContainer: lightColors.miniPlayer,
      onPrimaryContainer: lightOnMiniPlayer,
    );

    final darkScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: darkAdjustedPrimary,
      onPrimary: darkOnPrimary,
      secondary: darkAdjustedPrimary.withOpacity(0.8),
      onSecondary: darkOnPrimary,
      secondaryContainer: darkSecondaryContainer,
      onSecondaryContainer: Colors.white,
      error: Colors.redAccent,
      onError: Colors.black,
      surface: darkColors.surface,
      onSurface: darkColors.onSurface,
      primaryContainer: darkColors.miniPlayer,
      onPrimaryContainer: darkOnMiniPlayer,
    );

    return (lightScheme, darkScheme);
  }

  /// Extract color schemes from an image provider in one call
  /// NOTE: This runs on the main thread. Prefer extractColorSchemesFromUrl for better performance.
  static Future<(ColorScheme, ColorScheme)?> extractColorSchemes(ImageProvider imageProvider) async {
    final palette = await extractPalette(imageProvider);
    return generateColorSchemes(palette);
  }

  /// Get primary color for use in UI elements
  static Color? getPrimaryColor(PaletteGenerator? palette) {
    if (palette == null) return null;

    return palette.vibrantColor?.color ??
           palette.dominantColor?.color ??
           palette.lightVibrantColor?.color;
  }

  /// Get background color for use in UI
  static Color? getBackgroundColor(PaletteGenerator? palette, {required bool isDark}) {
    if (palette == null) return null;

    if (isDark) {
      return palette.darkMutedColor?.color ??
             palette.mutedColor?.color?.withOpacity(0.3) ??
             const Color(0xFF1a1a1a);
    } else {
      return palette.lightMutedColor?.color ??
             palette.mutedColor?.color?.withOpacity(0.9) ??
             Colors.white;
    }
  }
}
