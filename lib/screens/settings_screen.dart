import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/settings_service.dart';
import '../services/auth/auth_manager.dart';
import 'debug_logs_screen.dart';

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

  // Focus nodes for D-pad navigation - in tab order
  final FocusNode _serverUrlFocus = FocusNode();
  final FocusNode _usernameFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _saveButtonFocus = FocusNode();
  final FocusNode _visibilityButtonFocus = FocusNode();

  bool _isLoading = false;
  String? _error;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();

    // Auto-focus first field after a short delay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _serverUrlFocus.requestFocus();
      }
    });
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
    _serverUrlFocus.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    _saveButtonFocus.dispose();
    _visibilityButtonFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Define focus order for D-pad navigation
    final focusNodes = [
      _serverUrlFocus,
      _usernameFocus,
      _passwordFocus,
      _saveButtonFocus,
    ];

    return Focus(
      debugLabel: 'Settings Screen',
      onKeyEvent: (node, event) {
        // Handle D-pad navigation
        if (event is! KeyDownEvent) return KeyEventResult.ignored;

        switch (event.logicalKey) {
          case LogicalKeyboardKey.arrowDown:
          case LogicalKeyboardKey.tab:
            // Move to next focusable element
            final currentIndex = focusNodes.indexWhere((n) => n.hasFocus);
            if (currentIndex >= 0 && currentIndex < focusNodes.length - 1) {
              focusNodes[currentIndex + 1].requestFocus();
              return KeyEventResult.handled;
            }
            break;

          case LogicalKeyboardKey.arrowUp:
            // Move to previous focusable element
            final currentIndex = focusNodes.indexWhere((n) => n.hasFocus);
            if (currentIndex > 0) {
              focusNodes[currentIndex - 1].requestFocus();
              return KeyEventResult.handled;
            }
            break;

          case LogicalKeyboardKey.enter:
          case LogicalKeyboardKey.numpadEnter:
            // Handle OK/Enter button press
            if (_saveButtonFocus.hasFocus) {
              _saveAndLogin();
              return KeyEventResult.handled;
            }
            break;

          case LogicalKeyboardKey.escape:
          case LogicalKeyboardKey.backspace:
            // Handle back button - close the app
            SystemNavigator.pop();
            return KeyEventResult.handled;
        }

        return KeyEventResult.ignored;
      },
      child: Scaffold(
        backgroundColor: colorScheme.background,
        body: SafeArea(
          child: _isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: colorScheme.primary, strokeWidth: 2),
                      const SizedBox(height: 12),
                      const Text(
                        'Connecting...',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        const Text(
                          'Welcome to ensemble TV',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 20),

                        // Server URL field
                        const Text(
                          'Music Assistant Server',
                          style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 6),

                        _FocusableTextField(
                          controller: _serverUrlController,
                          focusNode: _serverUrlFocus,
                          hintText: 'e.g., 192.168.1.100:8095',
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[a-zA-Z0-9.:\-]'),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Username field
                        const Text(
                          'Username',
                          style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 6),

                        _FocusableTextField(
                          controller: _usernameController,
                          focusNode: _usernameFocus,
                          hintText: 'Your Music Assistant username',
                        ),

                        const SizedBox(height: 16),

                        // Password field
                        const Text(
                          'Password',
                          style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 6),

                        _FocusablePasswordField(
                          controller: _passwordController,
                          focusNode: _passwordFocus,
                          visibilityFocusNode: _visibilityButtonFocus,
                          obscureText: _obscurePassword,
                          onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),

                        const SizedBox(height: 12),

                        // Help text
                        const Text(
                          'Enter your Music Assistant server address and login credentials',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),

                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline, color: colorScheme.error, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _error!,
                                    style: TextStyle(
                                      color: colorScheme.onErrorContainer,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () {
                              DebugLogsScreen.show(context);
                            },
                            icon: const Icon(Icons.bug_report_outlined, size: 14),
                            label: const Text('View Logs', style: TextStyle(fontSize: 12)),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white70,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            ),
                          ),
                        ],

                        const SizedBox(height: 20),

                        // Connect button
                        SizedBox(
                          width: double.infinity,
                          child: _FocusableButton(
                            focusNode: _saveButtonFocus,
                            onPressed: _isLoading ? null : _saveAndLogin,
                            isPrimary: true,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Connect',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
          ),
        ),
    );
  }
}

// Focusable text field with visual focus indicator
class _FocusableTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final List<TextInputFormatter>? inputFormatters;

  const _FocusableTextField({
    required this.controller,
    required this.focusNode,
    required this.hintText,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bool isFocused = focusNode.hasFocus;

    return TextField(
      controller: controller,
      focusNode: focusNode,
      style: const TextStyle(fontSize: 14, color: Colors.white),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        filled: true,
        fillColor: isFocused
            ? colorScheme.surfaceVariant.withOpacity(0.4)
            : colorScheme.surfaceVariant.withOpacity(0.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isFocused ? colorScheme.primary : Colors.transparent,
            width: isFocused ? 2 : 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isFocused ? colorScheme.primary : Colors.transparent,
            width: isFocused ? 2 : 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        isDense: true,
      ),
      inputFormatters: inputFormatters,
    );
  }
}

// Focusable password field with visibility toggle
class _FocusablePasswordField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final FocusNode visibilityFocusNode;
  final bool obscureText;
  final VoidCallback onToggleVisibility;

  const _FocusablePasswordField({
    required this.controller,
    required this.focusNode,
    required this.visibilityFocusNode,
    required this.obscureText,
    required this.onToggleVisibility,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bool isFocused = focusNode.hasFocus;

    return TextField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      style: const TextStyle(fontSize: 14, color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Your Music Assistant password',
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        filled: true,
        fillColor: isFocused
            ? colorScheme.surfaceVariant.withOpacity(0.4)
            : colorScheme.surfaceVariant.withOpacity(0.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isFocused ? colorScheme.primary : Colors.transparent,
            width: isFocused ? 2 : 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isFocused ? colorScheme.primary : Colors.transparent,
            width: isFocused ? 2 : 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        isDense: true,
        suffixIcon: _FocusableIcon(
          focusNode: visibilityFocusNode,
          icon: obscureText ? Icons.visibility_off : Icons.visibility,
          iconSize: 18,
          onPressed: onToggleVisibility,
        ),
      ),
    );
  }
}

// Focusable button with visual focus indicator
class _FocusableButton extends StatefulWidget {
  final FocusNode focusNode;
  final VoidCallback? onPressed;
  final Widget child;
  final bool isPrimary;

  const _FocusableButton({
    required this.focusNode,
    required this.onPressed,
    required this.child,
    this.isPrimary = false,
  });

  @override
  State<_FocusableButton> createState() => _FocusableButtonState();
}

class _FocusableButtonState extends State<_FocusableButton> {
  bool _isFocused = false;
  final GlobalKey _focusKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
    _isFocused = widget.focusNode.hasFocus;
  }

  void _onFocusChange() {
    if (mounted && _isFocused != widget.focusNode.hasFocus) {
      setState(() {
        _isFocused = widget.focusNode.hasFocus;
      });
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Focus(
      key: _focusKey,
      focusNode: widget.focusNode,
      child: widget.isPrimary
          ? ElevatedButton(
              onPressed: widget.onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isFocused
                    ? colorScheme.primary.withOpacity(0.8)
                    : colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: _isFocused ? 4 : 0,
              ),
              child: widget.child,
            )
          : OutlinedButton(
              onPressed: widget.onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                side: BorderSide(color: Colors.white24, width: 1),
                backgroundColor: _isFocused
                    ? colorScheme.surfaceVariant.withOpacity(0.3)
                    : null,
              ),
              child: widget.child,
            ),
    );
  }
}

// Focusable icon button
class _FocusableIcon extends StatelessWidget {
  final FocusNode focusNode;
  final IconData icon;
  final double? iconSize;
  final VoidCallback onPressed;

  const _FocusableIcon({
    required this.focusNode,
    required this.icon,
    this.iconSize,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bool isFocused = focusNode.hasFocus;

    return Container(
      decoration: BoxDecoration(
        border: isFocused
            ? Border.all(color: colorScheme.primary, width: 2)
            : null,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Focus(
        focusNode: focusNode,
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon, color: Colors.white, size: iconSize ?? 20),
          iconSize: iconSize ?? 20,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ),
    );
  }
}
