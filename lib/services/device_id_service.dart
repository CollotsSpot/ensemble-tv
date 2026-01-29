import 'package:device_info_plus/device_info_plus.dart';
import 'package:uuid/uuid.dart';

/// Service for getting device ID.
class DeviceIdService {
  static final _uuid = const Uuid();
  static String? _cachedDeviceId;

  static Future<String> getDeviceId() async {
    if (_cachedDeviceId != null) {
      return _cachedDeviceId!;
    }

    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      _cachedDeviceId = androidInfo.id;
      return _cachedDeviceId!;
    } catch (e) {
      // Fallback to UUID
      _cachedDeviceId = _uuid.v4();
      return _cachedDeviceId!;
    }
  }
}
