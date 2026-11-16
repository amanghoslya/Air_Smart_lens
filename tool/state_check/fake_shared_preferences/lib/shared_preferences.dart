class SharedPreferences {
  static Future<SharedPreferences> getInstance() async => SharedPreferences();
  String? getString(String k) => null;
  Future<bool> setString(String k, String v) async => true;
  Future<bool> remove(String k) async => true;
}
