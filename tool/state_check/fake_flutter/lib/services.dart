import 'dart:io';

class _Bundle {
  Future<String> loadString(String k) async => File(k).readAsStringSync();
}

final rootBundle = _Bundle();
