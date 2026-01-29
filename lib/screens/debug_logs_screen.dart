import 'package:flutter/material.dart';
import '../services/tv_logger.dart';

/// Debug screen for viewing logs.
/// Accessible from error states or settings.
class DebugLogsScreen extends StatelessWidget {
  const DebugLogsScreen({super.key});

  static Future<void> show(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const DebugLogsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final logger = TVLogger();
    final logs = logger.getLogs();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        title: const Text('Debug Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              logger.clearLogs();
              // Force rebuild by popping and pushing
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const DebugLogsScreen()),
              );
            },
          ),
        ],
      ),
      body: logs.isEmpty
          ? const Center(
              child: Text(
                'No logs yet',
                style: TextStyle(fontSize: 28, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${log.levelIcon} [${log.formattedTime}]',
                        style: TextStyle(
                          fontSize: 16,
                          color: log.color,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          log.message,
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
