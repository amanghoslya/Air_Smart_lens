/// Small helpers that reproduce JavaScript number behaviour exactly.
///
/// The original app builds grid keys such as `-2/-0.5@90|1.25` from JS numbers
/// and seeds simulated quantities from a hash of those strings, so the Dart
/// port must turn numbers into the same text JavaScript does.
library;

/// `String(n)` in JavaScript: `-2.0` -> `-2`, `0.5` -> `0.5`, `-0.0` -> `0`.
String jsNum(num v) {
  if (v is int) return v.toString();
  final d = v.toDouble();
  if (d == 0) return '0';
  if (d.isFinite && d == d.truncateToDouble() && d.abs() < 1e21) {
    return d.toInt().toString();
  }
  return d.toString();
}

/// `Math.round` in JavaScript (halves round up, towards +infinity).
int jsRound(num v) => (v + 0.5).floor();

/// `+(v).toFixed(digits)`: round to [digits] decimals and back to a number.
double toFixedNum(num v, [int digits = 2]) => double.parse(v.toStringAsFixed(digits));

/// FNV-1a over UTF-16 code units, as `hash()` in the HTML app, scaled to 0..1.
double jsHash(String s) {
  var h = 2166136261;
  for (final c in s.codeUnits) {
    h ^= c;
    h = (h * 16777619) & 0xFFFFFFFF;
  }
  return h / 4294967295;
}

/// A stable sort (JavaScript's Array.prototype.sort is stable; Dart's is not
/// guaranteed to be), so ties keep their original order as in the web app.
void stableSort<T>(List<T> list, int Function(T a, T b) compare) {
  final indexed = List.generate(list.length, (i) => (i, list[i]));
  indexed.sort((x, y) {
    final c = compare(x.$2, y.$2);
    return c != 0 ? c : x.$1.compareTo(y.$1);
  });
  for (var i = 0; i < list.length; i++) {
    list[i] = indexed[i].$2;
  }
}

/// Sign of a JS comparator result given as a double.
int cmpNum(num a) => a < 0 ? -1 : (a > 0 ? 1 : 0);

/// `a.localeCompare(b)` as browsers do it for the range codes of the price file (ICU root collation, simplified):
/// spaces, then punctuation (− . / …), then symbols (+ = …), then digits, then letters (case only breaks ties,
/// lower case first). Used to break ties in Shop by range, so the order is the prototype's.
int jsLocaleCompare(String a, String b) {
  const punct = '_-,;:!?.\'"()[]{}@*/\\&#%`^';
  const sym = '+<=>|~\$';
  (int, int) w(int ch) {
    final s = String.fromCharCode(ch);
    if (s.trim().isEmpty) return (0, ch);
    final i = punct.indexOf(s);
    if (i >= 0) return (1, i);
    final j = sym.indexOf(s);
    if (j >= 0) return (2, j);
    if (ch >= 48 && ch <= 57) return (3, ch);
    final lo = s.toLowerCase();
    if (lo != s.toUpperCase()) return (4, lo.codeUnitAt(0));
    return (5, ch);
  }

  final x = a.codeUnits, y = b.codeUnits;
  for (var i = 0; i < x.length && i < y.length; i++) {
    final p = w(x[i]), q = w(y[i]);
    if (p.$1 != q.$1) return p.$1 - q.$1;
    if (p.$2 != q.$2) return p.$2 - q.$2;
  }
  if (x.length != y.length) return x.length - y.length;
  for (var i = 0; i < x.length; i++) {
    if (x[i] != y[i]) {
      final lx = String.fromCharCode(x[i]) == String.fromCharCode(x[i]).toLowerCase();
      return lx ? -1 : 1; // lower case first
    }
  }
  return 0;
}
