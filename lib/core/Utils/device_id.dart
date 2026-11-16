import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

/// Helper to get real device info and identifier for API requests.
class DeviceHelper {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  static String? _cachedId;
  static String? _cachedName;

  /// Returns real device unique identifier (e.g. androidInfo.id or iosInfo.identifierForVendor)
  static Future<String> getDeviceId() async {
    if (_cachedId != null && _cachedId!.isNotEmpty) {
      return _cachedId!;
    }
    try {
      if (Platform.isAndroid) {
        final android = await _deviceInfo.androidInfo;
        _cachedId = android.id;
        return _cachedId!;
      } else if (Platform.isIOS) {
        final ios = await _deviceInfo.iosInfo;
        _cachedId = ios.identifierForVendor ?? 'ios_device';
        return _cachedId!;
      }
    } catch (_) {}

    _cachedId = 'app_${DateTime.now().millisecondsSinceEpoch}';
    return _cachedId!;
  }

  /// Returns the platform identifier accepted by backend ('app' or 'web')
  static String getPlatform() {
    return 'app';
  }

  /// Returns the real device name (e.g. "Samsung SM-S918B", "Google Pixel 7", "iPhone 14 Pro")
  static Future<String> getDeviceName() async {
    if (_cachedName != null && _cachedName!.isNotEmpty) {
      return _cachedName!;
    }
    try {
      if (Platform.isAndroid) {
        final android = await _deviceInfo.androidInfo;
        final brand = android.brand.trim();
        final model = android.model.trim();
        if (brand.isNotEmpty && model.isNotEmpty) {
          final capBrand = brand[0].toUpperCase() + brand.substring(1);
          _cachedName = model.toLowerCase().contains(brand.toLowerCase())
              ? model
              : '$capBrand $model';
        } else {
          _cachedName = model.isNotEmpty
              ? model
              : (brand.isNotEmpty ? brand : 'Android Device');
        }
        return _cachedName!;
      } else if (Platform.isIOS) {
        final ios = await _deviceInfo.iosInfo;
        _cachedName = ios.name.isNotEmpty
            ? ios.name
            : (ios.model.isNotEmpty ? ios.model : 'iOS Device');
        return _cachedName!;
      }
    } catch (_) {}

    _cachedName = 'Mobile App';
    return _cachedName!;
  }
}
