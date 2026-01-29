import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tv_display_provider.dart';
import '../screens/settings_screen.dart';
import '../screens/player_select_screen.dart';

/// Menu dialog for TV app.
/// Shows when Menu button is pressed on remote.
class TVMenuDialog extends StatelessWidget {
  const TVMenuDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const TVMenuDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black87,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white24, width: 2),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 500),
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              const Text(
                'Options',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 40),

              // Menu items
              _MenuItem(
                icon: Icons.speaker,
                label: 'Change Player',
                onTap: () => _changePlayer(context),
              ),
              const SizedBox(height: 16),
              _MenuItem(
                icon: Icons.settings,
                label: 'Settings',
                onTap: () => _openSettings(context),
              ),
              const SizedBox(height: 16),
              _MenuItem(
                icon: Icons.info_outline,
                label: 'About',
                onTap: () => _showAbout(context),
              ),
              const SizedBox(height: 16),
              _MenuItem(
                icon: Icons.close,
                label: 'Close',
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _changePlayer(BuildContext context) {
    Navigator.of(context).pop();
    // Clear selected player to return to player selection
    context.read<TVDisplayProvider>().selectPlayer('');
  }

  void _openSettings(BuildContext context) async {
    Navigator.of(context).pop();
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
    // If settings changed, reinitialize
    if (result == true && context.mounted) {
      context.read<TVDisplayProvider>().initialize();
    }
  }

  void _showAbout(BuildContext context) {
    Navigator.of(context).pop();
    showAboutDialog(
      context: context,
      applicationName: 'Ensemble TV',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.tv, size: 48, color: Colors.white),
      applicationLegalese: '© 2024 CollotsSpot\n\nUnofficial Music Assistant client for Google TV',
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      focusColor: Colors.white24,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white24, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 36, color: Colors.white),
            const SizedBox(width: 24),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 32,
                  color: Colors.white,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, size: 32, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
