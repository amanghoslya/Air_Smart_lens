/// Power matching, order grids, prices and cart rules, ported one-to-one from
/// the HTML prototype (functions keep their original names in comments).
library;

import 'dart:math' as math;

import 'format.dart';
import 'js_compat.dart';
import 'models.dart';
import 'stock.dart';

const eps = 1e-6;
const adds = [1.0, 1.25, 1.5, 1.75, 2.0, 2.25, 2.5, 2.75, 3.0];
const ktAxes = [45, 90, 135, 180];

int nearestAxis(int a, List<int> ok) => ok.reduce((b, x) => (x - a).abs() < (b - a).abs() ? x : b);

bool inSpan(double v, List<double> sp, double step) {
  final lo = math.min(sp[0], sp[1]), hi = math.max(sp[0], sp[1]);
  if (v < lo - eps || v > hi + eps) return false;
  final k = (v - sp[0]).abs() / step;
  return (k - jsRound(k)).abs() < eps;
}

bool blockHas(PowerBlock b, double s, double c) => inSpan(s, b.s, b.ss ?? 0.25) && inSpan(c, b.c, b.cs ?? 0.25) && (!b.cross || s.abs() < c.abs() - eps);

List<double> spanVals(List<double> sp, double step) {
  final out = <double>[];
  final n = jsRound((sp[1] - sp[0]).abs() / step);
  final dir = sp[1] >= sp[0] ? 1 : -1;
  for (var i = 0; i <= n; i++) {
    out.add(toFixedNum(sp[0] + dir * i * step));
  }
  return out;
}

String rowLabel(double s, double c, int ax) {
  if (c == 0) return fmt(s);
  if (s == 0) return 'CYL ${fmt(c)}${ax != 0 ? ' ×$ax' : ''}';
  return '${fmt(s)} ${fmt(c)}${ax != 0 ? ' ×$ax' : ''}';
}

/// "Plano", "−2 SPH", "−6−2", "Cross"...
String rangeCode(double sph, double cyl) {
  if (sph == 0 && cyl == 0) return 'Plano';
  if (cyl == 0) return '${sph < 0 ? minus : '+'}${jsNum(sph.abs())} SPH';
  final cross = (sph > 0 && cyl < 0) || (sph < 0 && cyl > 0);
  if (cross) return 'Cross';
  final a = sph.abs();
  final s = a <= 6
      ? 6
      : a <= 8
          ? 8
          : a <= 10
              ? 10
              : a <= 12
                  ? 12
                  : a <= 15
                      ? 15
                      : 20;
  final ca = cyl.abs();
  final c = ca <= 2
      ? 2
      : ca <= 4
          ? 4
          : 6;
  return '${sph < 0 ? minus : '+'}$s${cyl < 0 ? minus : '+'}$c';
}

int round10(int a) {
  final r = jsRound(a / 10) * 10;
  return r == 0 ? 180 : r;
}

/// Everything that needs the catalogue: matching, grids, prices, sentences.
class LensLogic {
  final List<Product> catalog;
  final Map<String, SuperMaster> superMasters;
  final StockService stock;
  final Customer customer;
  final Map<int, Product> extraProducts = {};

  LensLogic({required this.catalog, required this.superMasters, required this.stock, required this.customer});

  Product product(int pid) => extraProducts[pid] ?? catalog[pid - 1];

  /// `tier(n)`: the shop's price after its tier discount.
  int tier(num n) => jsRound(n * customer.tierFactor);

  // ---------------- matching ----------------

  bool axisOk(Product p, PowerBlock b, Rx rx) {
    if (b.ax == null || b.ax == 0 || rx.cyl == 0) return true;
    if (p.ptype == LensType.kt) return nearestAxis(rx.axis, ktAxes) == b.ax;
    var d = ((rx.axis % 180) - (b.ax! % 180)).abs();
    d = math.min(d, 180 - d);
    return d <= 5;
  }

  bool lineMatches(Product p, int li, Rx rx) {
    final l = p.lines[li];
    if (l.boxes.isEmpty) return false;
    if (p.ptype != LensType.sv && !(rx.add >= 1 - eps && rx.add <= 3 + eps)) return false;
    return l.boxes.any((b) => blockHas(b, rx.sph, rx.cyl) && axisOk(p, b, rx));
  }

  int exactLine(Product p, Rx rx) {
    for (var i = 0; i < p.lines.length; i++) {
      if (lineMatches(p, i, rx)) return i;
    }
    return -1;
  }

  /// Nearest power (answer 15 b, tightened 5 Nov 2026): at most one step (0.25) on the sphere and one step on the
  /// cylinder. A nearby power always keeps what the slip has: a cylinder (with its axis) is never dropped to 0 or
  /// turned to the other sign, a sphere is never dropped to 0 or turned to the other sign, and no cylinder is added
  /// to a sphere-only slip. Lower powers and single-field changes are tried first.
  List<({double ds, double dc, double t})> nearDeltas(Rx rx) {
    const d = [-0.25, 0.0, 0.25];
    int away(double v, double dd) => dd != 0 && (v + dd).abs() > v.abs() ? 1 : 0;
    final out = <({double ds, double dc, double t, double k})>[];
    for (final ds in d) {
      for (final dc in d) {
        if (ds == 0 && dc == 0) continue;
        if (!nearOk(rx, ds, dc)) continue;
        final t = ds.abs() + dc.abs();
        out.add((ds: ds, dc: dc, t: t, k: t * 10 + away(rx.sph, ds) * 2 + away(rx.cyl, dc) + (dc == 0 && ds != 0 ? 0.5 : 0)));
      }
    }
    stableSort(out, (a, b) => cmpNum(a.k - b.k));
    return out.map((e) => (ds: e.ds, dc: e.dc, t: e.t)).toList();
  }

  /// `nearOk(rx, ds, dc)`: may a nearby power move the sphere by ds and the cylinder by dc? (see [nearDeltas])
  bool nearOk(Rx rx, double ds, double dc) {
    final s = toFixedNum(rx.sph + ds), c = toFixedNum(rx.cyl + dc);
    if (rx.cyl == 0 && c != 0) return false;
    if (rx.cyl != 0 && (c == 0 || c * rx.cyl < 0)) return false;
    if (rx.sph != 0 && (s == 0 || s * rx.sph < 0)) return false;
    if (rx.sph == 0 && s != 0 && rx.cyl == 0) return false;
    return true;
  }

  ({int li, Rx rx, bool diff})? fitLine(Product p, Rx rx) {
    var li = exactLine(p, rx);
    if (li >= 0) return (li: li, rx: rx, diff: false);
    final add = p.ptype == LensType.sv ? rx.add : math.min(3.0, math.max(1.0, rx.add));
    final da = p.ptype == LensType.sv ? 0.0 : (add - rx.add).abs();
    for (final d in nearDeltas(rx)) {
      if (d.t + da > 0.5 + eps || (d.t == 0 && da == 0)) continue;
      final r2 = rx.copyWith(sph: toFixedNum(rx.sph + d.ds), cyl: toFixedNum(rx.cyl + d.dc), add: add);
      li = exactLine(p, r2);
      if (li >= 0) return (li: li, rx: r2, diff: true);
    }
    return null;
  }

  /// RX progressive (made to order): the price file now gives each RX range's powers (2 Nov).
  int mtoLine(Product p, Rx rx) {
    if (!(rx.add >= 1 - eps && rx.add <= 3 + eps)) return -1;
    for (var i = 0; i < p.lines.length; i++) {
      if (p.lines[i].boxes.any((b) => blockHas(b, rx.sph, rx.cyl) && axisOk(p, b, rx))) return i;
    }
    return -1;
  }

  StockStatus pairStock(Match x) => StockStatus.worst(stock.stockOf(x.p, x.li), stock.stockOf(x.p, x.liL));

  List<Match> matchProducts(String lt, Rx rx, Rx? rxL) {
    final out = <Match>[];
    for (final p in catalog) {
      if (p.ptype != lt) continue;
      if (p.rx) {
        Rx ax(Rx r) => r.copyWith(axis: round10(r.axis));
        final li = mtoLine(p, rx);
        final liL = rxL != null ? mtoLine(p, rxL) : li;
        if (li >= 0 && liL >= 0) {
          out.add(Match(p: p, li: li, liL: liL, uR: ax(rx), uL: rxL != null ? ax(rxL) : null, mto: true));
        }
        continue;
      }
      final r = fitLine(p, rx);
      if (r == null) continue;
      final l = rxL != null ? fitLine(p, rxL) : r;
      if (l == null) continue;
      out.add(Match(p: p, li: r.li, liL: l.li, uR: r.rx, uL: rxL != null ? l.rx : null, dR: r.diff, dL: l.diff, diff: r.diff || l.diff));
    }
    int grp(Match x) => x.mto
        ? 2
        : x.diff
            ? 1
            : 0;
    int rank(Match x) => StockStatus.rank(pairStock(x));
    double pr(Match x) => ((x.p.lines[x.li].price ?? 9e9) + (x.p.lines[x.liL].price ?? 9e9)) / 2;
    stableSort(out, (a, b) {
      final g = grp(a) - grp(b);
      if (g != 0) return g;
      final k = rank(a) - rank(b);
      if (k != 0) return k;
      return cmpNum(pr(a) - pr(b));
    });
    return out;
  }

  bool orderable(Match x) => !const ['soon', 'na'].contains(pairStock(x).state);

  /// The code shown for a power: the price-file code most matching products use.
  String lineCode(List<Match> matches, String eye, Rx rx) {
    final pools = <bool Function(Match)>[(x) => !x.mto && !x.diff && orderable(x), (x) => !x.mto && orderable(x), (x) => !x.mto];
    var use = <Match>[];
    for (final f in pools) {
      use = matches.where(f).toList();
      if (use.isNotEmpty) break;
    }
    if (use.isEmpty) return rangeCode(rx.sph, rx.cyl);
    final cnt = <String, int>{}; // insertion-ordered, like a JS object
    for (final x in use) {
      final r = x.p.lines[eye == 'L' ? x.liL : x.li].range;
      cnt[r] = (cnt[r] ?? 0) + 1;
    }
    final entries = cnt.entries.toList();
    stableSort(entries, (a, b) => b.value - a.value);
    return prettyCode(entries.first.key);
  }

  String rxCode(List<Match> matches, Rx rx, Rx? l) {
    final cR = lineCode(matches, 'R', rx);
    if (l == null) return cR;
    final cL = lineCode(matches, 'L', l);
    return cL == cR ? cR : 'R $cR · L $cL';
  }

  // ---------------- order grids ----------------

  /// The grid of a line's own range. SV = SPH rows × CYL columns;
  /// KT/progressive = SPH/CYL rows × ADD columns.
  PowerGrid lineGridOwn(Product p, int li) {
    final l = p.lines[li];
    final isAdd = p.ptype != LensType.sv;
    final rows = <String, GridRow>{};
    final cols = <double>{};
    final colKeys = <String>{};
    final cells = <String>{};
    for (final b in l.boxes) {
      for (final s in spanVals(b.s, b.ss ?? 0.25)) {
        for (final c in spanVals(b.c, b.cs ?? 0.25)) {
          if (b.cross && !(s.abs() < c.abs() - eps)) continue;
          if (isAdd) {
            final rk = '${jsNum(s)}/${jsNum(c)}${b.ax != null && b.ax != 0 ? '@${b.ax}' : ''}';
            rows.putIfAbsent(rk, () => GridRow(key: rk, s: s, c: c, ax: b.ax ?? 0, label: rowLabel(s, c, b.ax ?? 0)));
            for (final a in adds) {
              if (colKeys.add(jsNum(a))) cols.add(a);
              cells.add('$rk|${jsNum(a)}');
            }
          } else {
            final rk = jsNum(s);
            rows.putIfAbsent(rk, () => GridRow(key: rk, s: s, c: 0, ax: 0, label: fmt(s)));
            if (colKeys.add(jsNum(c))) cols.add(c);
            cells.add('$rk|${jsNum(c)}');
          }
        }
      }
    }
    final axes = rows.values.map((r) => r.ax).toSet();
    if (axes.length <= 1) {
      for (final r in rows.values) {
        r.label = rowLabel(r.s, r.c, 0);
      }
    }
    final rList = rows.values.toList();
    stableSort(rList, (x, y) {
      if (isAdd) {
        if (x.ax != y.ax) return x.ax - y.ax;
        final c = cmpNum(x.c.abs() - y.c.abs());
        if (c != 0) return c;
        return cmpNum(x.s.abs() - y.s.abs());
      }
      return cmpNum(x.s.abs() - y.s.abs());
    });
    final cList = cols.toList();
    stableSort(cList, (x, y) {
      final a = cmpNum(x.abs() - y.abs());
      return a != 0 ? a : cmpNum(x - y);
    });
    return PowerGrid(isAdd: isAdd, rows: rList, cols: cList, cells: cells);
  }

  /// The grid shown for bulk orders: the linked Super Master's full standard
  /// grid with powers outside the line's own range greyed out.
  PowerGrid lineGrid(Product p, int li) {
    final own = lineGridOwn(p, li);
    final sm = superMasters[p.lines[li].sm];
    if (sm == null || sm.add != own.isAdd) return own;
    final rows = <GridRow>[];
    final cells = <String>{};
    final axes = sm.rows.map((r) => r.ax ?? 0).toSet();
    for (final r in sm.rows) {
      final ax = r.ax ?? 0;
      final key = sm.add ? '${jsNum(r.s)}/${jsNum(r.c ?? 0)}${ax != 0 ? '@$ax' : ''}' : jsNum(r.s);
      if (rows.any((x) => x.key == key)) continue;
      rows.add(GridRow(key: key, s: r.s, c: sm.add ? (r.c ?? 0) : 0, ax: ax, label: sm.add ? rowLabel(r.s, r.c ?? 0, axes.length > 1 ? ax : 0) : fmt(r.s)));
    }
    for (final r in rows) {
      for (final c in sm.cols) {
        final k = '${r.key}|${jsNum(c)}';
        final sph = r.s, cyl = sm.add ? r.c : c;
        if (sm.cross && !(sph.abs() < cyl.abs() - eps)) continue;
        if (own.cells.contains(k)) cells.add(k);
      }
    }
    for (final k in own.cells) {
      if (!cells.contains(k)) return own; // a power outside the standard grid
    }
    return PowerGrid(isAdd: own.isAdd, rows: rows, cols: sm.cols, cells: cells, sm: p.lines[li].sm, smt: sm.title);
  }

  // ---------------- cart ----------------

  /// `pushLine(m, qR, qL)`: a parcel-order line (quantities in lenses per eye).
  CartLine makeLine(Match m, double qR, double qL, {required Rx asked, Rx? askedL}) {
    final p = m.p;
    final l = p.lines[m.li], lL = p.lines[m.liL];
    final st = pairStock(m);
    final pR = (p.apiId != null ? (l.price ?? 0) : tier(l.price ?? 0)) / 2;
    final pL = (p.apiId != null ? (lL.price ?? 0) : tier(lL.price ?? 0)) / 2;
    final pairs = (qR + qL) / 2;
    return CartLine(
      kind: 'one',
      pid: p.id,
      li: m.li,
      liL: m.liL,
      qR: qR,
      qL: qL,
      qty: pairs,
      price: (qR * pR + qL * pL) / pairs,
      rx: m.uR,
      rxL: m.uL,
      diff: m.diff,
      wantR: m.diff ? asked : null,
      wantL: m.diff ? askedL : null,
      stock: st.state,
    );
  }

  /// `fillPast(seed)`: rebuild a past stock order's cells from its seed.
  Map<String, double> fillPast(String seed, int pid, int li) {
    final p = product(pid);
    final gr = lineGrid(p, li);
    final g = <String, double>{};
    final sorted = gr.cells.toList(); // insertion order, as the JS Set
    for (final k in sorted) {
      final h = jsHash(seed + k);
      if (h < 0.3 && stock.cellStock(p, li, k).state == 'in') {
        g[k] = h < 0.08
            ? 10
            : h < 0.18
                ? 5
                : 2;
      }
    }
    return g;
  }

  /// `pushGrid()`: a stock-order line from a filled grid. Sold-out boxes are taken out first (they become
  /// pre-orders, see `AppState.pushGrid`). [eye] is 'P', or 'R' / 'L' for a one-eye progressive grid,
  /// whose quantities are lenses (a pair is two).
  CartLine? makeGridLine(int pid, int li, Map<String, double> grid, {String eye = 'P'}) {
    final p = product(pid);
    final l = p.lines[li];
    final qty = grid.values.fold<double>(0, (a, b) => a + b);
    if (qty == 0) return null;
    final anyZero = grid.keys.any((k) => stock.cellStock(p, li, k).state == 'zero');
    final e = p.ptype == LensType.prog ? eye : 'P';
    return CartLine(
      kind: 'grid',
      eye: e,
      lenses: e == 'P' ? null : qty,
      pid: p.id,
      li: li,
      qty: e == 'P' ? qty : qty / 2,
      cells: grid.length,
      price: tier(l.price ?? 0).toDouble(),
      list: l.price ?? 0,
      stock: anyZero ? 'zero' : 'in',
      grid: Map.of(grid),
    );
  }

  /// `lineAvail(c)`: how many of the ordered pairs can be supplied now.
  double lineAvail(CartLine c) {
    if (c.kind == 'rxreq' || c.stock == 'mto') return c.qty;
    final p = product(c.pid!);
    if (c.kind == 'grid') {
      var a = 0.0;
      c.grid.forEach((k, q) {
        final st = stock.cellStock(p, c.li, k);
        a += math.min(q, st.state == 'in' ? (st.qty ?? 0).toDouble() : 0.0);
      });
      return a;
    }
    final st = powStock(Match(p: p, li: c.li, liL: c.liL ?? c.li, uR: c.rx, uL: c.rxL));
    return st.state == 'in' ? math.min(c.qty, (st.qty ?? 0).toDouble()) : 0;
  }

  /// `capLine(c)`: keep only what can be supplied now. Returns false if nothing is left.
  bool capLine(CartLine c) {
    final p = product(c.pid!);
    if (c.kind == 'grid') {
      final g = <String, double>{};
      c.grid.forEach((k, q) {
        final st = stock.cellStock(p, c.li, k);
        final a = st.state == 'in' ? math.min(q, (st.qty ?? 0).toDouble()) : 0.0;
        if (a != 0) g[k] = a;
      });
      c.grid = g;
      c.qty = g.values.fold<double>(0, (a, b) => a + b);
      if (c.eye == 'R' || c.eye == 'L') {
        c.lenses = c.qty;
        c.qty = c.qty / 2;
      }
      c.cells = g.length;
      c.stock = 'in';
    } else {
      final a = lineAvail(c);
      if (a < c.qty) {
        final f = a / c.qty;
        c.qR = c.qR * f;
        c.qL = c.qL * f;
        c.qty = a;
      }
    }
    return c.qty > 0;
  }

  /// `capCart()`: returns the number of pairs dropped.
  double capCart(List<CartLine> cart) {
    var dropped = 0.0;
    cart.removeWhere((c) {
      if (c.kind == 'rxreq' || c.stock == 'mto') return false;
      final before = c.qty;
      final keep = capLine(c);
      dropped += before - c.qty;
      return !keep;
    });
    return dropped;
  }

  // ---------------- text ----------------

  String _typ(String pt) => pt == LensType.sv
      ? 'single vision'
      : pt == LensType.kt
          ? 'KT'
          : 'progressive';

  String _pw(Rx x, String pt) => '${fmt(x.sph)} sphere${x.cyl != 0 ? ' with ${fmt(x.cyl)} cylinder' : ''}'
      '${pt != LensType.sv && x.cyl != 0 ? ' at ${x.axis}°' : ''}'
      '${pt != LensType.sv ? ', add ${fmt(x.add)}' : ''}';

  /// One plain sentence describing a cart line (shown in the cart and review).
  String sentence(CartLine c) {
    if (c.kind == 'one') {
      final p = product(c.pid!);
      if (p.ptype != LensType.prog) {
        // SV and KT: right and left are the same lens; a line is a number of pairs.
        final l = p.lines[c.li];
        final n = c.qty == 0.5 ? 'half a pair (one lens)' : '${jsNum(c.qty)} pair${c.qty == 1 ? '' : 's'}';
        return '${shortName(p)} ${_typ(p.ptype)}${l.dia != null ? ', ${l.dia} mm' : ''}. ${_pw(c.rx, p.ptype)}, $n.';
      }
    }
    final pt = c.kind == 'rxreq' ? c.lt! : product(c.pid!).ptype;
    final typ = _typ(pt);
    if (c.kind == 'rxreq') {
      return 'RX request, $typ. ${c.rxL != null ? 'Right eye ${_pw(c.rx, pt)}; left eye ${_pw(c.rxL!, pt)}' : 'Right and left eye ${_pw(c.rx, pt)}'}. Our staff will call with the lens, price and time.';
    }
    final p = product(c.pid!);
    final l = p.lines[c.li];
    if (c.kind == 'grid') {
      final eyeTxt = c.eye == 'R'
          ? ', right eye only'
          : c.eye == 'L'
              ? ', left eye only'
              : '';
      return '${shortName(p)} $typ lenses$eyeTxt, ${l.range} range${l.dia != null ? ', ${l.dia} mm' : ''} — box quantities across ${c.cells} power${c.cells == 1 ? '' : 's'}.';
    }
    final qR = c.qR, qL = c.qL, r = c.rx, lx = c.rxL ?? c.rx;
    String n(double q) => q == 1 ? '1 lens' : '${jsNum(q)} lenses';
    final lL = p.lines[c.liL ?? c.li];
    final dia =
        !identical(lL, l) ? ((l.dia != null || lL.dia != null) ? ', ${l.dia ?? '–'} / ${lL.dia ?? '–'} mm' : '') : (l.dia != null ? ', ${l.dia} mm' : '');
    final head = '${shortName(p)} $typ$dia';
    final asked =
        c.diff && c.wantR != null ? ' Prescribed: ${c.wantL != null ? 'right ${_pw(c.wantR!, pt)}; left ${_pw(c.wantL!, pt)}' : _pw(c.wantR!, pt)}.' : '';
    if (c.rxL == null && qR == qL) return '$head. Right and left eye ${_pw(r, pt)}, ${n(qR)} each.$asked';
    final parts = <String>[];
    if (qR != 0) parts.add('right eye ${_pw(r, pt)}, ${n(qR)}');
    if (qL != 0) parts.add('left eye ${_pw(lx, pt)}, ${n(qL)}');
    var body = parts.join('; ');
    if (body.startsWith('r')) {
      body = 'R${body.substring(1)}';
    } else if (body.startsWith('l')) {
      body = 'L${body.substring(1)}';
    }
    return '$head. $body.$asked';
  }

  /// Total lenses in a line.
  double lensCount(CartLine c) => c.qR + c.qL;

  // ---------------- per-power stock (30 Oct) ----------------

  /// `cellKey(p, li, rx)`: the grid key of a power inside one range (same as the bulk grid's boxes).
  String cellKey(Product p, int li, Rx rx) {
    if (p.ptype == LensType.sv) return '${jsNum(rx.sph)}|${jsNum(rx.cyl)}';
    PowerBlock? ax;
    for (final b in p.lines[li].boxes) {
      if (b.ax != null && b.ax != 0 && rx.cyl != 0 && blockHas(b, rx.sph, rx.cyl)) {
        ax = b;
        break;
      }
    }
    return '${jsNum(rx.sph)}/${jsNum(rx.cyl)}${ax != null ? '@${ax.ax}' : ''}|${jsNum(rx.add)}';
  }

  /// `cellPower(p, k)`: the power of a grid key.
  Rx cellPower(Product p, String k) {
    final parts = k.split('|');
    if (p.ptype == LensType.sv) return Rx(sph: double.parse(parts[0]), cyl: double.parse(parts[1]), axis: 180, add: 2);
    final m = RegExp(r'^(-?[\d.]+)/(-?[\d.]+)(?:@(\d+))?$').firstMatch(parts[0])!;
    return Rx(
      sph: double.parse(m.group(1)!),
      cyl: double.parse(m.group(2)!),
      axis: m.group(3) != null ? int.parse(m.group(3)!) : 180,
      add: double.parse(parts[1]),
    );
  }

  /// `powStock(m)`: the status of the exact power(s) of a match: N/A or Sold out wins, then Low stock.
  StockStatus powStock(Match? m) {
    if (m == null || m.mto) return StockStatus(m != null && m.mto ? 'mto' : 'in');
    final a = stock.cellStock(m.p, m.li, cellKey(m.p, m.li, m.uR));
    final b = m.uL != null ? stock.cellStock(m.p, m.liL, cellKey(m.p, m.liL, m.uL!)) : a;
    for (final o in const ['na', 'zero']) {
      if (a.state == o) return a;
      if (b.state == o) return b;
    }
    return a.low ? a : b;
  }

  /// `naAlts(m)` (5 Nov 2026): for a power that is not kept, the stocked powers one step (0.25) away on the sphere or
  /// on the cylinder in the same range, each with its full power and a label. Same limits as [nearOk].
  List<({Rx rx, String label, bool low})> naAlts(Match m) {
    final gr = lineGrid(m.p, m.li);
    final u = m.uR;
    final out = <({Rx rx, String label, bool low})>[];
    final tries = <(String, double, String)>[
      ('sph', -0.25, 'Sphere one step down'),
      ('sph', 0.25, 'Sphere one step up'),
      if (u.cyl != 0) ('cyl', -0.25, 'Cylinder one step ${u.cyl < 0 ? 'up' : 'down'}'),
      if (u.cyl != 0) ('cyl', 0.25, 'Cylinder one step ${u.cyl < 0 ? 'down' : 'up'}'),
    ];
    for (final (f, d, label) in tries) {
      final ds = f == 'sph' ? d : 0.0, dc = f == 'cyl' ? d : 0.0;
      if (!nearOk(u, ds, dc)) continue;
      final rx = u.copyWith(sph: toFixedNum(u.sph + ds), cyl: toFixedNum(u.cyl + dc));
      final k = cellKey(m.p, m.li, rx);
      if (!gr.cells.contains(k)) continue;
      final st = stock.cellStock(m.p, m.li, k);
      if (st.state == 'in') out.add((rx: rx, label: label, low: st.low));
    }
    return out;
  }

  /// `pairPrice(p, li, liL)`: price per pair of a power at the shop's tier.
  int? pairPrice(Product p, int li, int? liL) {
    final a = p.lines[li].price, b = p.lines[liL ?? li].price;
    if (a == null || b == null || a == 0 || b == 0) return null;
    if (p.apiId != null) return jsRound((a + b) / 2);
    return tier((a + b) / 2);
  }

  /// `fromPrice(p)`: the lowest price of a product.
  int? fromPrice(Product p) {
    final ps = [
      for (final l in p.lines)
        if (l.price != null && l.price != 0) l.price!,
    ];
    if (ps.isEmpty) return null;
    final m = ps.reduce(math.min);
    return p.apiId != null ? m : tier(m);
  }

  // ---------------- Shop by range (3 Nov) ----------------

  final _rangeIdx = <String, List<RangeGroup>>{};

  /// Every range code of one lens type with the lenses made in it, grouped and sorted as the prototype.
  List<RangeGroup> rangeIndex(String t) => _rangeIdx[t] ??= _buildRangeIndex(t);

  List<RangeGroup> _buildRangeIndex(String t) {
    final m = <String, RangeGroup>{};
    for (final p in catalog.where((p) => p.ptype == t)) {
      for (var li = 0; li < p.lines.length; li++) {
        final l = p.lines[li];
        final k = l.range.trim();
        m.putIfAbsent(k, () => RangeGroup(code: k, read: l.read, group: rangeGroupOf(k, t))).items.add((p: p, li: li));
      }
    }
    final r = m.values.toList();
    for (final g in r) {
      final ps = [
        for (final x in g.items)
          if (x.p.lines[x.li].price != null && x.p.lines[x.li].price != 0) x.p.lines[x.li].price!,
      ];
      g.from = ps.isEmpty ? null : tier(ps.reduce(math.min));
    }
    double mag(String c) {
      final n = RegExp(r'[+-]?\d+(\.\d+)?').allMatches(c).map((x) => double.parse(x.group(0)!)).toList();
      return n.isEmpty ? 0 : n[0].abs() * 100 + (n.length > 1 && n[1] != 0 ? n[1].abs() : 0);
    }

    stableSort(r, (a, b) {
      final g = rangeGroupOrder.indexOf(a.group) - rangeGroupOrder.indexOf(b.group);
      if (g != 0) return g;
      final d = cmpNum(mag(a.code) - mag(b.code));
      if (d != 0) return d;
      return jsLocaleCompare(a.code, b.code);
    });
    return r;
  }

  // ---------------- QR codes: VOC1 (29 Oct) ----------------

  String _pwCode(Rx x, String pt) {
    String n(double v) {
      final t = v.toStringAsFixed(2);
      return t == '-0.00' ? '0.00' : t;
    }

    return [n(x.sph), n(x.cyl), x.cyl != 0 && pt != LensType.sv ? x.axis : 180, pt == LensType.sv ? '0.00' : n(x.add)].join('|');
  }

  /// `qrCodeFor(m, eye)`: VOC1|product|eye|range|sph|cyl|axis|add (and the left eye's range and power when different).
  String qrCodeFor(Product p, int li, Rx uR, String eye, {int? liL, Rx? uL}) {
    final pt = p.ptype;
    return 'VOC1|${p.id}|${pt == LensType.prog ? eye : 'P'}|$li|${_pwCode(uR, pt)}${uL != null ? '|${liL ?? li}|${_pwCode(uL, pt)}' : ''}';
  }

  /// `parseScan(code)`: a VOC1 code back to lens, eye, range and power, or an error for the customer.
  ScanResult parseScan(String code) {
    final t = code.trim().replaceAll(RegExp(r'\s+'), '').replaceAll(RegExp('[−–]'), '-').split('|');
    bool num(String v) => v.isNotEmpty && double.tryParse(v) != null;
    if (t[0] != 'VOC1' || !(t.length == 8 || t.length == 13) || !RegExp(r'^[PRL]$').hasMatch(t[2]) || !t.sublist(3).every(num)) {
      return const ScanResult.error('This is not a Vishal lens code.');
    }
    final id = int.tryParse(t[1]) ?? 0;
    if (id < 1 || id > catalog.length) return const ScanResult.error('This lens is no longer in the catalogue.');
    final p = product(id);
    ({int li, Rx rx}) grp(int i) {
      final ax = double.parse(t[i + 3]).toInt(), ad = double.parse(t[i + 4]);
      return (
        li: double.parse(t[i]).toInt(),
        rx: Rx(sph: double.parse(t[i + 1]), cyl: double.parse(t[i + 2]), axis: ax == 0 ? 180 : ax, add: p.ptype == LensType.sv || ad == 0 ? 2 : ad),
      );
    }

    final r = grp(3);
    final l = t.length == 13 ? grp(8) : null;
    final eye = p.ptype == LensType.prog ? t[2] : 'P';
    for (final g in [r, if (l != null) l]) {
      if (g.li < 0 || g.li >= p.lines.length) return ScanResult.error('This range is no longer stocked for ${shortName(p)}.');
      if (!lineMatches(p, g.li, g.rx)) return ScanResult.error('This power is no longer in ${shortName(p)} ${rg(p.lines[g.li].range)}. Call the order desk.');
    }
    return ScanResult(p: p, eye: eye, li: r.li, rx: r.rx, liL: l?.li ?? r.li, rxL: l?.rx);
  }
}

/// One range code in Shop by range, with every lens made in it.
class RangeGroup {
  final String code;
  final String read;
  final String group;
  final List<({Product p, int li})> items = [];
  int? from;
  RangeGroup({required this.code, required this.read, required this.group});
}

const rangeGroupOrder = ['Minus', 'Plus', 'Sphere only', 'Minus sphere with ADD', 'Plus sphere with ADD', 'Cylinder only', 'Compound', 'Cross'];

/// `rgGroup(code, t)`: the section of a range code in Shop by range.
String rangeGroupOf(String code, String t) {
  final c = code.toUpperCase();
  if (c.contains('CROSS')) return 'Cross';
  if (c.contains('/ADD')) return c.startsWith('-') ? 'Minus sphere with ADD' : 'Plus sphere with ADD';
  if (t != LensType.sv && (c.contains('COMP') || RegExp(r'^[+-]\d+[+-]\d+(\s|$)').hasMatch(c))) return 'Compound';
  if (c.contains('CYL')) return 'Cylinder only';
  if (c.endsWith('SPH')) return 'Sphere only';
  return c.startsWith('-') ? 'Minus' : 'Plus';
}

/// A scanned VOC1 code: the lens, eye, range and power, or an error.
class ScanResult {
  final String? err;
  final Product? p;
  final String eye;
  final int li;
  final Rx? rx;
  final int liL;
  final Rx? rxL;
  const ScanResult({this.p, this.eye = 'P', this.li = 0, this.rx, this.liL = 0, this.rxL}) : err = null;
  const ScanResult.error(this.err)
      : p = null,
        eye = 'P',
        li = 0,
        rx = null,
        liL = 0,
        rxL = null;
  bool get ok => err == null;
}
