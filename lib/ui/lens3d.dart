import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../core/brands.dart';

/// The glass lens drawn in 3D, as in the HTML app: a meniscus lens (convex
/// front, concave back) of 14 rings × 56 segments, lit per facet, see-through,
/// with the coating colour gathering towards the edge and crisp highlights.
class LensMesh {
  static const rings = 14, seg = 56, cf = 0.34, cb = 0.2, e = 0.06;
  // each quad: 4 points (x,y,z) and a kind: 0 front, 1 back, 2 edge
  static final List<(List<List<double>>, int)> quads = _build();

  static List<(List<List<double>>, int)> _build() {
    List<List<double>> ring(int k, double Function(double r) f) {
      final r = k / rings;
      return List.generate(seg, (s) {
        final a = s / seg * math.pi * 2;
        return [r * math.cos(a), r * math.sin(a), f(r)];
      });
    }

    final front = <List<List<double>>>[], back = <List<List<double>>>[];
    for (var k = 0; k <= rings; k++) {
      front.add(ring(k, (r) => e + cf * (1 - r * r)));
      back.add(ring(k, (r) => -e + cb * (1 - r * r)));
    }
    final q = <(List<List<double>>, int)>[];
    for (var k = 0; k < rings; k++) {
      for (var s = 0; s < seg; s++) {
        final s2 = (s + 1) % seg;
        q.add(([front[k][s], front[k + 1][s], front[k + 1][s2], front[k][s2]], 0));
        q.add(([back[k][s], back[k][s2], back[k + 1][s2], back[k + 1][s]], 1));
      }
    }
    for (var s = 0; s < seg; s++) {
      final s2 = (s + 1) % seg;
      q.add(([front[rings][s], back[rings][s], back[rings][s2], front[rings][s2]], 2));
    }
    return q;
  }
}

List<Offset> _hull(List<Offset> pts) {
  final p = pts.toList()..sort((a, b) => a.dx != b.dx ? a.dx.compareTo(b.dx) : a.dy.compareTo(b.dy));
  double cr(Offset o, Offset a, Offset b) => (a.dx - o.dx) * (b.dy - o.dy) - (a.dy - o.dy) * (b.dx - o.dx);
  final lo = <Offset>[], up = <Offset>[];
  for (final q in p) {
    while (lo.length >= 2 && cr(lo[lo.length - 2], lo[lo.length - 1], q) <= 0) {
      lo.removeLast();
    }
    lo.add(q);
  }
  for (var i = p.length - 1; i >= 0; i--) {
    final q = p[i];
    while (up.length >= 2 && cr(up[up.length - 2], up[up.length - 1], q) <= 0) {
      up.removeLast();
    }
    up.add(q);
  }
  up.removeLast();
  lo.removeLast();
  return [...lo, ...up];
}

const _lumToAlpha = ColorFilter.matrix(<double>[
  0, 0, 0, 0, 0, //
  0, 0, 0, 0, 0, //
  0, 0, 0, 0, 0, //
  1, 0, 0, 0, 0,
]);

/// `lensRender(g, cx, cy, sc, th, ph, tint)`. th = tilt from flat (90 = standing),
/// ph = spin about the vertical. [behind] redraws what is behind the lens, so it
/// can be shown slightly magnified through the glass.
void lensRender(Canvas g, double cx, double cy, double sc, double th, double ph, List<int> tint, {void Function(Canvas)? behind}) {
  const el = 14 * math.pi / 180;
  final ce = math.cos(el), se = math.sin(el);
  const l0 = [-0.42, -0.6, 0.68];
  final ln = math.sqrt(l0[0] * l0[0] + l0[1] * l0[1] + l0[2] * l0[2]);
  final lu = l0.map((v) => v / ln).toList();
  final v = [0.0, -ce, se];
  final t = th * math.pi / 180, f = ph * math.pi / 180;
  final ct = math.cos(t), st = math.sin(t), cf = math.cos(f), sf = math.sin(f);

  final faces = <({List<Offset> p, List<double> n, int kind, double d})>[];
  final edgePts = <Offset>[];
  for (final qd in LensMesh.quads) {
    final w = qd.$1.map((q) {
      final x = q[0], y = q[1] * ct - q[2] * st, z = q[1] * st + q[2] * ct;
      return [x * cf - y * sf, x * sf + y * cf, z];
    }).toList();
    final pts = <Offset>[];
    var d = 0.0;
    for (final p in w) {
      pts.add(Offset(cx + p[0] * sc, cy - (p[2] * ce + p[1] * se) * sc));
      d += p[1] * ce - p[2] * se;
    }
    d /= 4;
    final a = [w[2][0] - w[0][0], w[2][1] - w[0][1], w[2][2] - w[0][2]];
    final b = [w[3][0] - w[1][0], w[3][1] - w[1][1], w[3][2] - w[1][2]];
    var n = [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]];
    var nl = math.sqrt(n[0] * n[0] + n[1] * n[1] + n[2] * n[2]);
    if (nl == 0) nl = 1;
    n = n.map((x) => x / nl).toList();
    if (qd.$2 == 2) edgePts.addAll(pts);
    if (n[0] * v[0] + n[1] * v[1] + n[2] * v[2] > 0) faces.add((p: pts, n: n, kind: qd.$2, d: d));
  }
  faces.sort((x, y) => y.d.compareTo(x.d));
  final outline = _hull(edgePts);
  if (outline.length < 3) return;
  final path = Path()..addPolygon(outline, true);
  final bounds = path.getBounds().inflate(3);
  if (bounds.width < 2 || bounds.height < 2) return;

  // 1. what is behind the lens, slightly magnified
  if (behind != null) {
    final mag = 1 + 0.10 * math.sin(t).abs();
    g.save();
    g.clipPath(path);
    g.translate(cx, cy);
    g.scale(mag, mag);
    g.translate(-cx, -cy);
    behind(g);
    g.restore();
  }

  // 2. the glass: colour and opacity per facet, joined through a luminance mask
  final hv = [lu[0] + v[0], lu[1] + v[1], lu[2] + v[2]];
  final hn = math.sqrt(hv[0] * hv[0] + hv[1] * hv[1] + hv[2] * hv[2]);
  final pos = Float32List(faces.length * 12);
  final col = Int32List(faces.length * 6);
  final alp = Int32List(faces.length * 6);
  var pi = 0, ci = 0;
  for (final fc in faces) {
    final n = fc.n;
    final nv = math.max(0.0, n[0] * v[0] + n[1] * v[1] + n[2] * v[2]);
    final dif = math.max(0.0, n[0] * lu[0] + n[1] * lu[1] + n[2] * lu[2]);
    final nh = math.max(0.0, (n[0] * hv[0] + n[1] * hv[1] + n[2] * hv[2]) / hn);
    final spec = (fc.kind == 0 ? 0.85 : 0.45) * math.pow(nh, 34) + 0.2 * math.pow(nh, 8);
    final fres = math.pow(1 - nv, 2).toDouble();
    List<double> c;
    double a;
    if (fc.kind == 2) {
      final k = 200 + 45 * dif;
      c = [k, k + 4, k + 8];
      a = 0.78;
    } else {
      final sheen = math.min(0.92, 0.66 + 0.3 * fres);
      final base = [236, 241, 246].map((x) => x * (0.9 + 0.1 * dif)).toList();
      c = [for (var i = 0; i < 3; i++) base[i] * (1 - sheen) + tint[i] * sheen];
      a = math.min(1.0, (fc.kind == 0 ? 0.36 : 0.2) + 0.55 * fres);
    }
    c = c.map((x) => math.min(255.0, x * (1 - spec) + 255 * spec)).toList();
    a = math.min(1.0, a + spec * 0.95);
    final cv = 0xFF000000 | (c[0].round() << 16) | (c[1].round() << 8) | c[2].round();
    final al = (a * 255).round();
    final av = 0xFF000000 | (al << 16) | (al << 8) | al;
    final p = fc.p;
    for (final idx in const [0, 1, 2, 0, 2, 3]) {
      pos[pi++] = p[idx].dx;
      pos[pi++] = p[idx].dy;
      col[ci] = cv;
      alp[ci] = av;
      ci++;
    }
  }
  final vc = ui.Vertices.raw(VertexMode.triangles, pos, colors: col);
  final va = ui.Vertices.raw(VertexMode.triangles, pos, colors: alp);
  g.saveLayer(bounds, Paint()..imageFilter = ui.ImageFilter.blur(sigmaX: 0.55, sigmaY: 0.55));
  g.saveLayer(bounds, Paint()..colorFilter = _lumToAlpha);
  g.drawRect(bounds, Paint()..color = const Color(0xFF000000));
  g.drawVertices(va, BlendMode.dst, Paint());
  g.restore();
  g.saveLayer(bounds, Paint()..blendMode = BlendMode.srcIn);
  g.drawVertices(vc, BlendMode.dst, Paint());
  g.restore();
  g.restore();
  vc.dispose();
  va.dispose();

  // 3. a fine bright line along the rim
  g.drawPath(
    path,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = const Color(0x8CFFFFFF),
  );
}

double _ease(double t) => t < 0.5 ? 2 * t * t : 1 - math.pow(-2 * t + 2, 2) / 2;
double _clamp(double v, [double a = 0, double b = 1]) => math.max(a, math.min(b, v));

List<int> _mix(List<int> a, List<int> b, double e) => [for (var k = 0; k < 3; k++) (a[k] + (b[k] - a[k]) * e).round()];

/// u 0..1 runs once through all coatings, then eases onto the ordered one.
List<int> coatCycle(double u, int endIdx) {
  final seq = [...coats.map((c) => c.$2), coats[endIdx].$2];
  final x = math.max(0.0, math.min(seq.length - 1 - 1e-6, u * (seq.length - 1)));
  final i = x.floor(), t = x - i, e = t * t * (3 - 2 * t);
  return _mix(seq[i], seq[i + 1], e);
}

// ---------------------------------------------------------------- loader lens

/// The loader: the glass lens spins on its edge while the coating colours cycle.
class LoaderLens extends StatefulWidget {
  final double size;
  const LoaderLens({super.key, this.size = 110});
  @override
  State<LoaderLens> createState() => _LoaderLensState();
}

class _LoaderLensState extends State<LoaderLens> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  double _t = 0;
  @override
  void initState() {
    super.initState();
    _ticker = createTicker((d) => setState(() => _t = d.inMicroseconds / 1000))..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.of(context).disableAnimations;
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: CustomPaint(painter: _LoaderPainter(reduced ? 350 : _t)),
    );
  }
}

class _LoaderPainter extends CustomPainter {
  final double t;
  _LoaderPainter(this.t);
  @override
  void paint(Canvas g, Size size) {
    final w0 = size.width, h0 = size.height;
    final spin = t / 1700 * 360, bob = math.sin(t / 420) * 2.2;
    final ci = (t / 700) % coats.length;
    final i = ci.floor() % coats.length;
    final k = ci - ci.floor(), e = k * k * (3 - 2 * k);
    final tint = _mix(coats[i].$2, coats[(i + 1) % coats.length].$2, e);
    final cx = w0 / 2, cy = h0 / 2 - 6 + bob, w = math.cos(spin * math.pi / 180).abs() * 0.75 + 0.25;
    g.drawOval(
      Rect.fromCenter(center: Offset(cx, h0 - 12), width: (26 * w + 6) * 2, height: 10),
      Paint()
        ..color = const Color(0x291E222C)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    lensRender(g, cx, cy, 31, 90, spin, tint);
  }

  @override
  bool shouldRepaint(_LoaderPainter old) => old.t != t;
}

// ---------------------------------------------------------------- confetti

class ConfettiBurst {
  final Offset origin; // global position
  final List<Color> colors;
  final int id;
  const ConfettiBurst(this.origin, this.colors, this.id);
}

/// The shell listens to this and draws the confetti over the whole screen.
final confettiBus = ValueNotifier<ConfettiBurst?>(null);

class ConfettiLayer extends StatefulWidget {
  const ConfettiLayer({super.key});
  @override
  State<ConfettiLayer> createState() => _ConfettiLayerState();
}

class _Particle {
  double x, y, vx, vy, w, h, r, vr;
  final Color c;
  final bool round;
  _Particle(this.x, this.y, this.vx, this.vy, this.w, this.h, this.r, this.vr, this.c, this.round);
}

class _ConfettiLayerState extends State<ConfettiLayer> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  List<_Particle> _p = [];
  Duration _start = Duration.zero, _last = Duration.zero;
  double _t = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick);
    confettiBus.addListener(_burst);
  }

  void _burst() {
    final b = confettiBus.value;
    if (b == null || !mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final o = box.globalToLocal(b.origin);
    final rnd = math.Random();
    final col = [...b.colors, const Color(0xFF1D2433), const Color(0xFFC9A227), const Color(0xFF7DB7E8), const Color(0xFFE58A3A)];
    _p = List.generate(110, (_) {
      final a = -math.pi / 2 + (rnd.nextDouble() - 0.5) * 1.9, v = 260 + rnd.nextDouble() * 360;
      return _Particle(
        o.dx + (rnd.nextDouble() - 0.5) * 30,
        o.dy,
        math.cos(a) * v,
        math.sin(a) * v,
        5 + rnd.nextDouble() * 5,
        3 + rnd.nextDouble() * 4,
        rnd.nextDouble() * 6.28,
        (rnd.nextDouble() - 0.5) * 14,
        col[rnd.nextInt(col.length)],
        rnd.nextDouble() < 0.3,
      );
    });
    _start = Duration.zero;
    _last = Duration.zero;
    _t = 0;
    if (_ticker.isActive) _ticker.stop();
    _ticker.start();
  }

  void _tick(Duration el) {
    final dt = math.max(0, math.min(40, (el - _last).inMicroseconds / 1000)) / 1000;
    _last = el;
    _t = (el - _start).inMicroseconds / 1e6;
    final h = context.size?.height ?? 800;
    var alive = 0;
    for (final p in _p) {
      p.vy += 520 * dt;
      p.vx *= 0.985;
      p.vy *= 0.985;
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.r += p.vr * dt;
      if (p.y < h + 20) alive++;
    }
    if (alive == 0 || _t >= 2.8) {
      _ticker.stop();
      _p = [];
    }
    setState(() {});
  }

  @override
  void dispose() {
    confettiBus.removeListener(_burst);
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: SizedBox.expand(child: CustomPaint(painter: _ConfettiPainter(_p, _t))),
  );
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> p;
  final double t;
  _ConfettiPainter(this.p, this.t);
  @override
  void paint(Canvas g, Size size) {
    final alpha = _clamp(2.6 - t);
    for (final q in p) {
      g.save();
      g.translate(q.x, q.y);
      g.rotate(q.r);
      final paint = Paint()..color = q.c.withValues(alpha: q.c.a * alpha);
      if (q.round) {
        g.drawCircle(Offset.zero, q.h * 0.7, paint);
      } else {
        g.scale(1, math.cos(q.r * 1.7).abs() + 0.15);
        g.drawRect(Rect.fromCenter(center: Offset.zero, width: q.w, height: q.h), paint);
      }
      g.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => true;
}

// ---------------------------------------------------------------- order packed

/// Order placed: the lens spins above an open envelope while its coating runs
/// through Evergreen, Opal, Kopper X, Solara Gold, Volt and Shine, settles on the
/// coating of this order, drops in, the flap folds shut, the Vishal seal presses
/// on and confetti rises. Tap to replay. Reduced motion: the sealed envelope only.
class EnvelopeDrop extends StatefulWidget {
  final int endIdx;
  final VoidCallback? onWhoosh, onThud, onCelebrate;
  const EnvelopeDrop({super.key, required this.endIdx, this.onWhoosh, this.onThud, this.onCelebrate});
  @override
  State<EnvelopeDrop> createState() => _EnvelopeDropState();
}

class _EnvelopeDropState extends State<EnvelopeDrop> with SingleTickerProviderStateMixin {
  static const w = 280.0, h = 262.0;
  static const a = 350.0, spin = 1650.0, drop = 650.0, close = 600.0, seal = 380.0;
  late final Ticker _ticker;
  double _ph = 0, _lastMs = 0;
  bool _fired = false, _whoosh = false, _thud = false, _done = false;
  _Frame? _frame;
  String _label = '';
  double _labelOpacity = 1;
  final _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_step);
    WidgetsBinding.instance.addPostFrameCallback((_) => _restart());
  }

  void _restart() {
    if (!mounted) return;
    if (MediaQuery.of(context).disableAnimations) {
      setState(() {
        _done = true;
        _frame = _fin;
        _label = '';
      });
      return;
    }
    _ph = 0;
    _lastMs = 0;
    _fired = _whoosh = _thud = _done = false;
    if (_ticker.isActive) _ticker.stop();
    _ticker.start();
  }

  _Frame get _fin => _Frame(lensY: 0, lensS: 0, th: 90, ph: 0, tint: coats[widget.endIdx].$2, flap: 1, seal: 1, dy: 0, sq: 0, alpha: 1);

  void _step(Duration el) {
    final t = el.inMicroseconds / 1000;
    final dt = math.max(0, math.min(40, t - _lastMs)) / 1000;
    _lastMs = t;
    const et = h - 128 - 14, eh = 128.0;
    final st = _Frame(lensY: et - 48, lensS: 40, th: 90, ph: 0, tint: coats[0].$2, flap: 0, seal: 0, dy: 0, sq: 0, alpha: 1);
    final end = widget.endIdx;
    if (t < a) {
      final u = _ease(t / a);
      st.alpha = u;
      st.dy = 10 * (1 - u);
      st.lensS = 40 * u;
      _ph += dt * 420;
    } else if (t < a + spin) {
      final u = (t - a) / spin;
      _ph += dt * (520 * (1 - u) + 60);
      st.lensY = et - 48 + 3 * math.sin(t / 180);
      final cu = _clamp(u / 0.95);
      st.tint = coatCycle(cu, end);
      final idx = math.min(coats.length, (cu * coats.length).floor());
      _label = idx < coats.length ? coats[idx].$1 : coats[end].$1;
      _labelOpacity = 1;
    } else if (t < a + spin + drop) {
      if (!_whoosh) {
        _whoosh = true;
        widget.onWhoosh?.call();
      }
      final u = _ease((t - a - spin) / drop);
      st.tint = coats[end].$2;
      final target = _ph + ((360 - (_ph % 360)) % 360);
      _ph = _ph + (target - _ph) * math.min(1, dt * 9);
      st.lensY = et - 48 + (et + eh * 0.52 - (et - 48)) * u;
      st.lensS = 40 - 6 * u;
      _labelOpacity = 1 - u;
    } else if (t < a + spin + drop + close) {
      final u = _ease((t - a - spin - drop) / close);
      st.tint = coats[end].$2;
      st.lensY = et + eh * 0.52;
      st.lensS = 34;
      st.flap = u;
      _ph = (_ph / 360).round() * 360;
      _labelOpacity = 0;
    } else if (t < a + spin + drop + close + seal) {
      if (!_thud) {
        _thud = true;
        widget.onThud?.call();
      }
      final u = (t - a - spin - drop - close) / seal;
      st.lensS = 0;
      st.flap = 1;
      st.tint = coats[end].$2;
      var s = u < 0.6 ? 1.25 * math.sin(u / 0.6 * math.pi / 2) : 1.0;
      s = math.min(1.25, s);
      if (u > 0.6) s = 1.25 - 0.25 * ((u - 0.6) / 0.4);
      st.seal = s;
      st.sq = math.sin(u * math.pi) * 0.9;
      if (!_fired && u > 0.35) {
        _fired = true;
        widget.onCelebrate?.call();
        final box = _key.currentContext?.findRenderObject() as RenderBox?;
        if (box != null) {
          final origin = box.localToGlobal(Offset(box.size.width / 2, box.size.height * 0.66));
          confettiBus.value = ConfettiBurst(
            origin,
            coats.map((c) => Color.fromARGB(255, c.$2[0], c.$2[1], c.$2[2])).toList(),
            DateTime.now().microsecondsSinceEpoch,
          );
        }
      }
    } else {
      _ticker.stop();
      setState(() {
        _frame = _fin;
        _done = true;
      });
      return;
    }
    st.ph = _ph;
    setState(() => _frame = st);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink2 = dark ? const Color(0xFFB5B8BF) : const Color(0xFF5D6370);
    return GestureDetector(
      onTap: _restart,
      child: Semantics(
        label: 'Order placed',
        image: true,
        child: SizedBox(
          key: _key,
          width: w,
          height: h,
          child: Stack(
            children: [
              CustomPaint(size: const Size(w, h), painter: _EnvelopePainter(_frame, dark)),
              if (!_done)
                Positioned(
                  top: 2,
                  left: 0,
                  right: 0,
                  child: AnimatedOpacity(
                    opacity: _labelOpacity,
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      _label.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, letterSpacing: 11 * .14, fontWeight: FontWeight.w600, color: ink2),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Frame {
  double lensY, lensS, th, ph, flap, seal, dy, sq, alpha;
  List<int> tint;
  _Frame({
    required this.lensY,
    required this.lensS,
    required this.th,
    required this.ph,
    required this.tint,
    required this.flap,
    required this.seal,
    required this.dy,
    required this.sq,
    required this.alpha,
  });
}

class _EnvelopePainter extends CustomPainter {
  final _Frame? f;
  final bool dark;
  _EnvelopePainter(this.f, this.dark);

  @override
  void paint(Canvas g, Size size) {
    final st = f;
    if (st == null) return;
    const w = 280.0, h = 262.0, ew = 196.0, eh = 128.0;
    const ex = (w - ew) / 2, et = h - eh - 14, cx = w / 2, v0 = et + eh * 0.56;
    final p = dark
        ? (
            back: const Color(0xFF2A2E37),
            inner: const Color(0xFF343944),
            front: const Color(0xFFECE6DA),
            side: const Color(0xFFE3DCCE),
            flap: const Color(0xFFF2ECE1),
            line: const Color(0x1F000000),
            shadow: const Color(0x73000000),
          )
        : (
            back: const Color(0xFFE6DED0),
            inner: const Color(0xFFD9CFBE),
            front: const Color(0xFFFBF8F2),
            side: const Color(0xFFF3EEE4),
            flap: const Color(0xFFFFFDF8),
            line: const Color(0x243C321E),
            shadow: const Color(0x2E28241C),
          );
    void poly(List<Offset> pts, Color fill, [Color? stroke]) {
      final path = Path()..addPolygon(pts, true);
      g.drawPath(path, Paint()..color = fill);
      if (stroke != null) {
        g.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = stroke,
        );
      }
    }

    if (st.alpha < 1) g.saveLayer(Offset.zero & size, Paint()..color = Color.fromRGBO(0, 0, 0, st.alpha));
    g.save();
    g.translate(cx, et + eh + st.dy);
    g.scale(1 + 0.04 * st.sq, 1 - 0.06 * st.sq);
    g.translate(-cx, -(et + eh));
    g.drawOval(
      Rect.fromCenter(center: Offset(cx, et + eh + 6 + st.dy), width: ew * 0.48 * 2, height: 14),
      Paint()
        ..color = p.shadow
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    final top = et + st.dy, bot = et + eh + st.dy, lx = ex, rx = ex + ew, vv = v0 + st.dy;
    void backAndFlap(Canvas c) {
      final pathB = Path()..addPolygon([Offset(lx, top), Offset(rx, top), Offset(rx, bot), Offset(lx, bot)], true);
      c.drawPath(pathB, Paint()..color = p.back);
      if (st.flap < 0.5) {
        final k = 1 - st.flap * 2, apex = top - eh * 0.52 * k;
        c.drawPath(Path()..addPolygon([Offset(lx, top), Offset(rx, top), Offset(cx, apex)], true), Paint()..color = p.inner);
      }
    }

    poly([Offset(lx, top), Offset(rx, top), Offset(rx, bot), Offset(lx, bot)], p.back);
    if (st.flap < 0.5) {
      final k = 1 - st.flap * 2, apex = top - eh * 0.52 * k;
      poly([Offset(lx, top), Offset(rx, top), Offset(cx, apex)], p.inner, p.line);
    }
    if (st.lensS > 0) {
      g.save();
      g.clipRect(Rect.fromLTWH(0, 0, w, bot - 2));
      lensRender(g, cx, st.lensY + st.dy, st.lensS, st.th, st.ph, st.tint, behind: backAndFlap);
      g.restore();
    }
    poly([Offset(lx, top + 2), Offset(cx, vv), Offset(lx, bot)], p.side, p.line);
    poly([Offset(rx, top + 2), Offset(cx, vv), Offset(rx, bot)], p.side, p.line);
    poly([Offset(lx, bot), Offset(cx, vv - 6), Offset(rx, bot)], p.front, p.line);
    if (st.flap >= 0.5) {
      final k = (st.flap - 0.5) * 2, apex = top + eh * 0.6 * k;
      poly([Offset(lx, top), Offset(rx, top), Offset(cx, apex)], p.flap, p.line);
      if (st.seal > 0.05) {
        final r = 13 * st.seal, sy = apex - 3;
        g.drawCircle(Offset(cx, sy), r, Paint()..color = const Color(0xFF1D2433));
        if (r > 5) {
          g.drawCircle(
            Offset(cx, sy),
            r - 3,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1
              ..color = const Color(0x40FFFFFF),
          );
        }
        final tp = TextPainter(
          text: TextSpan(
            text: 'V',
            style: TextStyle(fontFamily: 'CormorantGaramond', fontWeight: FontWeight.w600, fontSize: (15 * st.seal).roundToDouble(), color: Colors.white),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(g, Offset(cx - tp.width / 2, sy + 1 - tp.height / 2));
      }
    }
    g.restore();
    if (st.alpha < 1) g.restore();
  }

  @override
  bool shouldRepaint(_EnvelopePainter old) => true;
}

/// For tests: whether the mesh was built.
@visibleForTesting
int get lensQuadCount => LensMesh.quads.length;
