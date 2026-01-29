import 'dart:async';
import 'dart:io';

/// Helper for retrying operations with exponential backoff.
class RetryHelper {
  static Future<T> retry<T>(
    Future<T> Function()? operation, {
    int maxAttempts = 3,
    Duration initialDelay = const Duration(seconds: 1),
    Duration maxDelay = const Duration(seconds: 30),
    int initialDelaySeconds = 1,
    int maxDelaySeconds = 30,
    bool Function(Object)? shouldRetry,
    Future<T> Function()? operation2,
  }) async {
    // Use operation2 if provided (named parameter), otherwise use operation (positional)
    final op = operation ?? operation2;
    if (op == null) {
      throw ArgumentError('Either operation or operation2 must be provided');
    }
    int attempts = 0;
    Duration delay = initialDelay;

    while (true) {
      attempts++;

      try {
        return await op();
      } catch (e) {
        if (attempts >= maxAttempts) {
          rethrow;
        }

        // Check if we should retry this error
        if (shouldRetry != null && !shouldRetry(e)) {
          rethrow;
        }

        if (e is SocketException ||
            e is TimeoutException ||
            e is HttpException) {
          // Retry for network errors
          await Future.delayed(delay);
          delay = Duration(
            milliseconds: (delay.inMilliseconds * 2).clamp(
              initialDelay.inMilliseconds,
              maxDelay.inMilliseconds,
            ),
          );
        } else {
          rethrow;
        }
      }
    }
  }

  // Stub methods for compatibility with copied code
  static Future<T> retryNetwork<T>({required Future<T> Function() operation}) =>
      retry(null, operation2: operation);

  static Future<T> retryCritical<T>({required Future<T> Function() operation}) =>
      retry(null, operation2: operation);
}
