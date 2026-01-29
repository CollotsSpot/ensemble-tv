import 'dart:convert';
import 'package:http/http.dart' as http;
import '../debug_logger.dart';

/// Simple authentication manager for Music Assistant
/// MA now uses its own built-in authentication system
class AuthManager {
  final _logger = DebugLogger();

  String? _accessToken;
  String? _longLivedToken;

  /// Get the best available token (prefer long-lived)
  String? get token => _longLivedToken ?? _accessToken;

  /// Check if we have valid credentials
  bool get hasCredentials => token != null;

  /// Login to Music Assistant and get an access token
  Future<String?> login(String serverUrl, String username, String password) async {
    try {
      final apiUrl = _buildApiUrl(serverUrl);
      _logger.log('🔐 Logging in to Music Assistant at $apiUrl');

      final response = await http.post(
        apiUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'command': 'auth/login',
          'args': {
            'username': username,
            'password': password,
          },
        }),
      ).timeout(const Duration(seconds: 10));

      _logger.log('Auth response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        if (data.containsKey('error_code')) {
          _logger.log('✗ Login failed: ${data['error_code']} - ${data['details']}');
          return null;
        }

        final result = data['result'] as Map<String, dynamic>?;
        _accessToken = result?['access_token'] as String?;

        if (_accessToken != null) {
          _logger.log('✓ Got access token from MA');

          // Try to create a long-lived token
          _longLivedToken = await _createLongLivedToken(apiUrl, _accessToken!);

          return _longLivedToken ?? _accessToken;
        }

        _logger.log('✗ No access token in response');
        return null;
      }

      _logger.log('✗ Authentication failed: ${response.statusCode}');
      return null;
    } catch (e) {
      _logger.log('✗ Login error: $e');
      return null;
    }
  }

  /// Create a long-lived token for persistent authentication
  Future<String?> _createLongLivedToken(Uri apiUrl, String accessToken) async {
    try {
      _logger.log('Creating long-lived token...');

      final response = await http.post(
        apiUrl,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'command': 'auth/create_token',
          'args': {
            'name': 'Ensemble Mobile App',
          },
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        if (!data.containsKey('error_code')) {
          final result = data['result'] as Map<String, dynamic>?;
          final token = result?['token'] as String?;

          if (token != null) {
            _logger.log('✓ Created long-lived token');
            return token;
          }
        }
      }

      _logger.log('⚠️ Could not create long-lived token (non-fatal)');
      return null;
    } catch (e) {
      _logger.log('⚠️ Long-lived token creation failed: $e (non-fatal)');
      return null;
    }
  }

  /// Validate a stored token
  Future<bool> validateToken(String serverUrl, String storedToken) async {
    try {
      final apiUrl = _buildApiUrl(serverUrl);

      final response = await http.post(
        apiUrl,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $storedToken',
        },
        body: jsonEncode({
          'command': 'server/info',
        }),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (!data.containsKey('error_code')) {
          _longLivedToken = storedToken;
          return true;
        }
      }

      return false;
    } catch (e) {
      _logger.log('Token validation failed: $e');
      return false;
    }
  }

  /// Build headers for WebSocket connection
  Map<String, dynamic> getWebSocketHeaders() {
    if (token != null) {
      return {'Authorization': 'Bearer $token'};
    }
    return {};
  }

  /// Build headers for HTTP streaming requests
  Map<String, String> getStreamingHeaders() {
    if (token != null) {
      return {'Authorization': 'Bearer $token'};
    }
    return {};
  }

  /// Set token from external source (e.g., restored from settings)
  void setToken(String? storedToken) {
    _longLivedToken = storedToken;
  }

  /// Clear authentication state
  void logout() {
    _accessToken = null;
    _longLivedToken = null;
    _logger.log('Logged out - cleared auth state');
  }

  /// Build API URL from server URL
  Uri _buildApiUrl(String serverUrl) {
    var baseUrl = serverUrl;
    if (!baseUrl.startsWith('http://') && !baseUrl.startsWith('https://')) {
      baseUrl = 'http://$baseUrl';
    }

    final uri = Uri.parse(baseUrl);
    return Uri(
      scheme: uri.scheme,
      host: uri.host,
      port: uri.hasPort ? uri.port : (uri.scheme == 'https' ? null : 8095),
      path: '/api',
    );
  }
}
