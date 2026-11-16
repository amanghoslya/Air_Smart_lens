// Minimal stand-in for package:flutter/foundation.dart, to run AppState on the plain Dart VM.
typedef VoidCallback = void Function();
const bool kDebugMode = true;
void debugPrint(String? m, {int? wrapWidth}) {}

class ChangeNotifier {
  final _l = <VoidCallback>[];
  void addListener(VoidCallback f) => _l.add(f);
  void removeListener(VoidCallback f) => _l.remove(f);
  void notifyListeners() {
    for (final f in List.of(_l)) {
      f();
    }
  }

  void dispose() {}
}

abstract class ValueListenable<T> {
  T get value;
}

class ValueNotifier<T> extends ChangeNotifier implements ValueListenable<T> {
  T _v;
  ValueNotifier(this._v);
  @override
  T get value => _v;
  set value(T v) {
    if (v == _v) return;
    _v = v;
    notifyListeners();
  }
}
