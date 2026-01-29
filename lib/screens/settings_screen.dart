import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/settings_service.dart';
import '../services/auth/auth_manager.dart';

/// Settings screen for TV app.
/// Allows configuration of Music Assistant server URL and credentials.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _serverUrlController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _error;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final serverUrl = await SettingsService.getServerUrl();
      final username = await SettingsService.getUsername();
      setState(() {
        _serverUrlController.text = serverUrl ?? '';
        _usernameController.text = username ?? '';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load settings: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveAndLogin() async {
    final url = _serverUrlController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (url.isEmpty) {
      setState(() => _error = 'Server URL cannot be empty');
      return;
    }

    if (username.isEmpty || password.isEmpty) {
      setState(() => _error = 'Username and password are required');
      return;
    }

    setState(() => _isLoading = true);
    _error = null;

    try {
      // Save settings
      await SettingsService.setServerUrl(url);
      await SettingsService.setUsername(username);

      // Try to login
      final authManager = AuthManager();
      final token = await authManager.login(url, username, password);

      if (token == null) {
        setState(() {
          _error = 'Login failed - check your username and password';
          _isLoading = false;
        });
        return;
      }

      // Save token
      await SettingsService.setToken(token);

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate settings changed
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to connect: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 20),
                    Text(
                      'Connecting to Music Assistant...',
                      style: TextStyle(fontSize: 24, color: Colors.grey),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(60),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      const Text(
                        'Settings',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Server URL field
                      const Text(
                        'Music Assistant Server',
                        style: TextStyle(
                          fontSize: 28,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextField(
                        controller: _serverUrlController,
                        style: const TextStyle(fontSize: 24, color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'e.g., 192.168.1.100:8095',
                          hintStyle: const TextStyle(color: Colors.grey),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.white24),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.white24),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.white),
                          ),
                          filled: true,
                          fillColor: Colors.white10,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[a-zA-Z0-9.:\-]'),
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      // Username field
                      const Text(
                        'Username',
                        style: TextStyle(
                          fontSize: 28,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextField(
                        controller: _usernameController,
                        style: const TextStyle(fontSize: 24, color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Your Music Assistant username',
                          hintStyle: const TextStyle(color: Colors.grey),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.white24),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.white24),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.white),
                          ),
                          filled: true,
                          fillColor: Colors.white10,
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Password field
                      const Text(
                        'Password',
                        style: TextStyle(
                          fontSize: 28,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: const TextStyle(fontSize: 24, color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Your Music Assistant password',
                          hintStyle: const TextStyle(color: Colors.grey),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.white24),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.white24),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.white),
                          ),
                          filled: true,
                          fillColor: Colors.white10,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() => _obscurePassword = !_obscurePassword);
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Help text
                      const Text(
                        'Enter your Music Assistant server address and login credentials',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.grey,
                        ),
                      ),

                      if (_error != null) ...[
                        const SizedBox(height: 20),
                        Text(
                          _error!,
                          style: const TextStyle(
                            fontSize: 20,
                            color: Colors.red,
                          ),
                        ),
                      ],

                      const SizedBox(height: 40),

                      // Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isLoading
                                  ? null
                                  : () {
                                      Navigator.of(context).pop();
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white24,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 24),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(fontSize: 24),
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _saveAndLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 24),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.black,
                                      ),
                                    )
                                  : const Text(
                                      'Save & Login',
                                      style: TextStyle(fontSize: 24),
                                    ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
