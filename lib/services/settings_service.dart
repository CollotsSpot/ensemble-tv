import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Simple settings service for TV app.
class SettingsService {
  static const _secureStorage = FlutterSecureStorage();

  static Future<String?> getServerUrl() async {
    return await _secureStorage.read(key: 'server_url');
  }

  static Future<void> setServerUrl(String url) async {
    await _secureStorage.write(key: 'server_url', value: url);
  }

  static Future<String?> getToken() async {
    return await _secureStorage.read(key: 'auth_token');
  }

  static Future<void> setToken(String token) async {
    await _secureStorage.write(key: 'auth_token', value: token);
  }

  static Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('username');
  }

  static Future<void> setUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username);
  }

  static Future<int?> getWebSocketPort() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('ws_port');
  }

  static Future<void> setWebSocketPort(int port) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('ws_port', port);
  }

  // Audiobookshelf stub methods (not used in TV app, but referenced by music_assistant_api.dart)
  // These return empty/default values since the TV app doesn't use Audiobookshelf features
  static Future<List<String>> getEnabledAbsLibraries() async => [];
  static Future<void> clearEnabledAbsLibraries() async {}
  static Future<void> setDiscoveredAbsLibraries(List<dynamic> libraries) async {}
}
