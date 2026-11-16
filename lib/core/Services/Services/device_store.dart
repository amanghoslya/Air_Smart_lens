import 'package:shared_preferences/shared_preferences.dart';

/// Small settings kept on the phone, as the prototype kept them in the browser's storage:
/// the welcome poster shown last, Pairs / Pieces, saved powers, the button beside each power (QR code or
/// Favorite), dark mode and the sound switch.
abstract class DeviceStore {
  String? getString(String key);
  void setString(String key, String value);
}

/// Keeps nothing between starts (tests, previews).
class MemoryStore implements DeviceStore {
  final Map<String, String> _m = {};
  @override
  String? getString(String key) => _m[key];
  @override
  void setString(String key, String value) => _m[key] = value;
}

/// The phone's shared preferences.
class PrefsStore implements DeviceStore {
  final SharedPreferences _p;
  PrefsStore._(this._p);

  static Future<DeviceStore> open() async {
    try {
      return PrefsStore._(await SharedPreferences.getInstance());
    } catch (_) {
      return MemoryStore(); // a platform without preferences: run without them
    }
  }

  @override
  String? getString(String key) => _p.getString(key);
  @override
  void setString(String key, String value) => _p.setString(key, value);
}
