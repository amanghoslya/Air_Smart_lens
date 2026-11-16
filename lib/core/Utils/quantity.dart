/// Quantity rules (24 Oct) and axis steps (23–24 Oct), pure Dart.
///
/// Single vision and KT: pairs only, in steps of 0.5 (0.5 = one lens; right and
/// left are the same lens). Progressive: the eye is chosen on the power screen
/// (pair, right only or left only), so the quantity is pairs, right lenses or
/// left lenses.
library;

import 'dart:math' as math;

import 'js_compat.dart';
import '../Data/Model/models.dart';

/// Quantity kind: 'H' half-pair steps (SV/KT), 'P' pairs, 'R' right lenses, 'L' left lenses.
String qKind(String lensType, String peye) => lensType == LensType.prog ? peye : 'H';

double qMin(String k) => k == 'H' ? 0.5 : 1;

double qStepN(String k, double n, int d) {
  final st = k == 'H' ? 0.5 : 1.0;
  return math.max(qMin(k), double.parse((n + d * st).toStringAsFixed(1)));
}

({double r, double l}) toLR(String k, double n) => k == 'R'
    ? (r: n, l: 0.0)
    : k == 'L'
    ? (r: 0.0, l: n)
    : (r: n, l: n);

double pairsOf(String k, double n) => k == 'R' || k == 'L' ? n / 2 : n;

/// Pairs or pieces (30 Oct): the customer counts in whichever they prefer. Stored quantities stay in pairs;
/// a piece is one lens. Only single vision and KT ('H') switch; progressive counts a pair in pairs and one eye
/// in pieces.
bool isPcs(String k, String unit) => unit == 'pcs' && k == 'H';
int uMul(String k, String unit) => isPcs(k, unit) ? 2 : 1;

/// `nfmt(v)`: up to one decimal, no trailing zero.
String nfmt(num v) => jsNum(double.parse(v.toStringAsFixed(1)));

String qWord(String k, double n, {String unit = 'pairs'}) {
  if (k == 'H' && unit == 'pcs') return '${nfmt(n * 2)} piece${n * 2 == 1 ? '' : 's'}';
  if (k == 'R') return '${jsNum(n)} right lens${n == 1 ? '' : 'es'}';
  if (k == 'L') return '${jsNum(n)} left lens${n == 1 ? '' : 'es'}';
  if (n == 0.5) return 'half a pair';
  final s = jsNum(n).replaceFirst('.5', '½').replaceFirst(RegExp(r'^0½'), '½');
  return '$s pair${n == 1 ? '' : 's'}';
}

String lineQtyTxt(CartLine c) {
  final qR = c.qR, qL = c.qL;
  if (qR == qL) return qWord('P', c.qty);
  if (qL == 0) return qWord('R', qR);
  if (qR == 0) return qWord('L', qL);
  return 'R ${jsNum(qR)} · L ${jsNum(qL)} lenses';
}

/// KT is made only at 45°, 90°, 135° and 180°; progressive in 5° steps, 5° to 180°.
/// The axis is never 0.
List<int> axisValues(String lensType) => lensType == LensType.kt ? const [45, 90, 135, 180] : List.generate(36, (i) => (i + 1) * 5);

int nearestAx(int a, String lensType) {
  final ax = axisValues(lensType);
  a = ((a % 180) + 180) % 180;
  if (a == 0) a = 180;
  int dist(int x) => math.min((x - a).abs(), 180 - (x - a).abs());
  return ax.reduce((b, x) => dist(x) < dist(b) ? x : b);
}

/// `wvals(a, b, s)`
List<double> wvals(double a, double b, double s) {
  final o = <double>[];
  for (var v = a; v <= b + 1e-9; v += s) {
    o.add(toFixedNum(v));
  }
  return o;
}

final _sph = wvals(-20, 10, 0.25);
final _cyl = wvals(-6, 6, 0.25);
final _add = wvals(0.75, 4, 0.25);

/// Values of one scroll wheel: plus powers on top, so SPH and CYL run high to low.
List<double> wheelValues(String field, String lensType) => switch (field) {
  'axis' => axisValues(lensType).map((e) => e.toDouble()).toList(),
  'sph' => _sph.reversed.toList(),
  'cyl' => _cyl.reversed.toList(),
  _ => _add,
};

/// `snap(v, step, lo, hi)`
double snapTo(double v, double step, double lo, double hi) {
  v = jsRound(v / step) * step;
  return toFixedNum(math.min(hi, math.max(lo, v)));
}

/// Tick sound kind for a wheel step: 'edge' at the ends, 'major' on whole powers.
String tickKind(String f, double v, double min, double max, String lensType) {
  if ((v - min).abs() < 1e-6 || (v - max).abs() < 1e-6) return 'edge';
  if (f == 'axis') return (lensType == LensType.kt || v % 30 == 0) ? 'major' : 'minor';
  return (v.abs() - v.abs().roundToDouble()).abs() < 1e-6 ? 'major' : 'minor';
}
