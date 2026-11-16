import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// The line icons of the HTML app, drawn from the same SVG path data (24×24 viewBox),
/// so the Flutter app keeps the exact icons without an SVG package.
class IconDef {
  final List<String> parts; // 'M..' path data, 'c cx cy r' circles, 'r x y w h rx' rects
  final double stroke;
  final bool fill;
  const IconDef(this.parts, {this.stroke = 1.6, this.fill = false});
}

class Ic {
  // ICON
  static const back = IconDef(['M15 5l-7 7 7 7'], stroke: 1.7);
  static const arrow = IconDef(['M5 12h14M13 6l6 6-6 6'], stroke: 1.8);
  static const search = IconDef(['c 11 11 6.5', 'M20 20l-4.2-4.2'], stroke: 1.7);
  static const bag = IconDef(['M5 8h14l-1.2 12H6.2z', 'M9 8a3 3 0 0 1 6 0']);
  static const heart = IconDef(['M12 20s-7-4.4-7-10a4 4 0 0 1 7-2.6A4 4 0 0 1 19 10c0 5.6-7 10-7 10z']);
  static const chev = IconDef(['M9 6l6 6-6 6'], stroke: 1.7);
  static const glasses = IconDef(['c 7 14 3.5', 'c 17 14 3.5', 'M10.5 14h3M3.5 13l1.5-5M20.5 13l-1.5-5']);
  static const rx = IconDef(['c 12 12 8', 'M12 7v10M7 12h10']);
  static const boxes = IconDef(['M3 12h8v8H3zM13 12h8v8h-8zM8 4h8v8H8z']);
  static const eye = IconDef(['M2.5 12S6 5.5 12 5.5 21.5 12 21.5 12 18 18.5 12 18.5 2.5 12 2.5 12z', 'c 12 12 3']);
  static const sun = IconDef(['c 12 12 4', 'M12 2.5v2.5M12 19v2.5M2.5 12H5M19 12h2.5M5.3 5.3l1.8 1.8M16.9 16.9l1.8 1.8M5.3 18.7l1.8-1.8M16.9 7.1l1.8-1.8']);
  static const shield = IconDef(['M12 3l7 3v5.5c0 4.4-3 7.8-7 9.5-4-1.7-7-5.1-7-9.5V6z', 'M9 12l2 2 4-4']);
  static const screen = IconDef(['r 3.5 5 17 11 1.5', 'M9 20h6M12 16v4']);
  static const drop = IconDef(['M12 3.5s6 6.6 6 10.5a6 6 0 0 1-12 0c0-3.9 6-10.5 6-10.5z']);
  static const edit = IconDef(['M4 20h4L19 9l-4-4L4 16z']);
  static const trash = IconDef(['M5 7h14M10 7V4.5h4V7M7 7l1 13h8l1-13']);
  static const check = IconDef(['M5 12.5l4.5 4.5L19 7.5'], stroke: 2);
  static const truck = IconDef(['M2.5 6.5h11v10h-11zM13.5 10h4l3 3v3.5h-7', 'c 7 17.5 1.8', 'c 17 17.5 1.8']);
  static const play = IconDef(['M8 5.5v13l10-6.5z'], fill: true);
  static const menu = IconDef(['M4 7h16M4 12h16M4 17h10'], stroke: 1.7);
  // 29 Oct – 3 Nov
  static const x = IconDef(['M6.5 6.5l11 11M17.5 6.5l-11 11'], stroke: 1.9);
  static const qr = IconDef(['M4 4h6v6H4zM14 4h6v6h-6zM4 14h6v6H4z', 'M14 14h2v2h-2zM18 14h2M14 18v2M18 18h2v2h-2']);
  static const moon = IconDef(['M20 14.5A8 8 0 0 1 9.5 4a8 8 0 1 0 10.5 10.5z']);
  static const rangeGrid = IconDef(['r 3.5 4.5 17 15 2.5', 'M3.5 9.5h17M3.5 14.5h17M9 4.5v15M14.5 4.5v15']);
  // tab bar
  static const home = IconDef(['M4 10.5 12 4l8 6.5V20h-5.5v-5.5h-5V20H4z']);
  static const orders = IconDef(['r 5 4 14 16 2', 'M9 9h6M9 13h6M9 17h3']);
  static const account = IconDef(['c 12 8.5 3.5', 'M5 20c1.2-3.6 4-5.2 7-5.2s5.8 1.6 7 5.2']);
  // sound switch
  static const soundOn = IconDef(['M4 9.5h3.5L12 5.5v13l-4.5-4H4z', 'M15.5 9a4 4 0 0 1 0 6M18 6.5a7.5 7.5 0 0 1 0 11'], stroke: 1.7);
  static const soundOff = IconDef(['M4 9.5h3.5L12 5.5v13l-4.5-4H4z', 'M16 9.5l5 5M21 9.5l-5 5'], stroke: 1.7);
  static const bug = IconDef(['c 12 13 5', 'M12 8V5M9 6.5 7.5 5M15 6.5 16.5 5M7 13H4M20 13h-3M7.5 17.5 5 19.5M16.5 17.5l2.5 2']);

  // MI: menu icons
  static const mi = <String, IconDef>{
    'user': IconDef(['M12 12a3.5 3.5 0 1 0 0-7 3.5 3.5 0 0 0 0 7zM5 20c1.2-3.6 4-5.2 7-5.2s5.8 1.6 7 5.2']),
    'box': IconDef(['r 5 4 14 16 2', 'M9 9h6M9 13h6M9 17h3']),
    'clock': IconDef(['c 12 12 8', 'M12 7.5V12l3 2']),
    'heart': heart,
    'tag': IconDef(['M4 4h7l9 9-7 7-9-9z', 'c 8.5 8.5 1.3']),
    'book': IconDef(['M5 4.5h10a3 3 0 0 1 3 3V20H8a3 3 0 0 1-3-3z', 'M5 17a3 3 0 0 1 3-3h10']),
    'swap': IconDef(['M5 8h13l-3.5-3.5M19 16H6l3.5 3.5']),
    'file': IconDef(['M7 3.5h7l4 4V20.5H7z', 'M14 3.5v4h4M10 12h5M10 16h5']),
    'chart': IconDef(['M4.5 19.5h15M7 16v-5M11.5 16V7M16 16v-8']),
    'pie': IconDef(['M12 4a8 8 0 1 0 8 8h-8z', 'M14 2.8a8 8 0 0 1 7.2 7.2H14z']),
    'image': IconDef(['r 4 5 16 14 2', 'M4 16l4.5-4.5 4 4 2.5-2.5L20 18', 'c 15.5 9.5 1.4']),
    'video': IconDef(['r 3.5 6 12 12 2', 'M15.5 10.5l5-3v9l-5-3']),
    'award': IconDef(['c 12 9 5', 'M8.8 13l-1.3 7.5L12 18l4.5 2.5-1.3-7.5']),
    'team': IconDef(['c 9 9 3', 'c 17 10 2.4', 'M3.5 19c.9-3 3-4.5 5.5-4.5s4.6 1.5 5.5 4.5M15 15c2.3 0 4 1.2 5 4']),
    'globe': IconDef(['c 12 12 8', 'M4 12h16M12 4c2.4 2.4 2.4 13.6 0 16M12 4c-2.4 2.4-2.4 13.6 0 16']),
    'lang': IconDef(['M4 6h9M8.5 4v2c0 4-2 7-4.5 8.5M6.5 10c1 2 3 3.5 5.5 4.5M13.5 20l3.5-9 3.5 9M14.7 17h4.6']),
    'phone': IconDef(['M6 4h3.5l1.5 4-2 1.5a10 10 0 0 0 5.5 5.5l1.5-2 4 1.5V18a2 2 0 0 1-2 2A15 15 0 0 1 4 6a2 2 0 0 1 2-2z']),
    'help': IconDef(['c 12 12 8', 'M9.6 9.5a2.5 2.5 0 1 1 3.4 2.3c-.7.3-1 .8-1 1.5v.4M12 16.8v.2']),
    'info': IconDef(['c 12 12 8', 'M12 11v5M12 8v.2']),
    'doc': IconDef(['M7 3.5h10v17H7z', 'M10 8h4M10 12h4M10 16h2']),
    'out': IconDef(['M14 4.5H6v15h8M10.5 12H20M17 9l3 3-3 3']),
    'qr': qr,
    'moon': moon,
  };

  /// Feature icons used on the product page.
  static const feat = <String, IconDef>{'sun': sun, 'screen': screen, 'shield': shield, 'drop': drop, 'eye': eye};
}

class SvgIcon extends StatelessWidget {
  final IconDef icon;
  final double size;
  final Color? color;
  final bool filled; // fill the outline too (the wished heart)
  const SvgIcon(this.icon, {super.key, this.size = 21, this.color, this.filled = false});

  @override
  Widget build(BuildContext context) {
    final col = color ?? DefaultTextStyle.of(context).style.color ?? const Color(0xFF1B2130);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _IconPainter(icon, col, filled)),
    );
  }
}

class _IconPainter extends CustomPainter {
  final IconDef icon;
  final Color color;
  final bool filled;
  _IconPainter(this.icon, this.color, this.filled);

  static final _cache = <String, Path>{};

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 24);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = icon.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    for (final part in icon.parts) {
      final path = _cache.putIfAbsent(part, () => _shape(part));
      if (icon.fill) {
        canvas.drawPath(path, fill);
      } else {
        if (filled) canvas.drawPath(path, fill);
        canvas.drawPath(path, stroke);
      }
    }
  }

  static Path _shape(String s) {
    if (s.startsWith('c ')) {
      final v = s.substring(2).split(' ').map(double.parse).toList();
      return Path()..addOval(Rect.fromCircle(center: Offset(v[0], v[1]), radius: v[2]));
    }
    if (s.startsWith('r ')) {
      final v = s.substring(2).split(' ').map(double.parse).toList();
      return Path()..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(v[0], v[1], v[2], v[3]), Radius.circular(v[4])));
    }
    return parseSvgPath(s);
  }

  @override
  bool shouldRepaint(_IconPainter old) => old.icon != icon || old.color != color || old.filled != filled;
}

/// A compact SVG path-data parser (M L H V C S Q T A Z, absolute and relative).
Path parseSvgPath(String d) {
  final tokens = RegExp(r'[MmLlHhVvCcSsQqTtAaZz]|-?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?').allMatches(d).map((m) => m.group(0)!).toList();
  final path = Path();
  var i = 0;
  var cmd = '';
  var x = 0.0, y = 0.0, sx = 0.0, sy = 0.0;
  double? cx2, cy2; // last control point for S/T
  String prev = '';
  bool isCmd(String t) => RegExp(r'^[A-Za-z]$').hasMatch(t);
  double n() => double.parse(tokens[i++]);
  int flag() {
    // flags may be packed like "0 1" or "01"
    final t = tokens[i];
    if (t.length > 1 && (t.startsWith('0') || t.startsWith('1')) && !t.contains('.')) {
      tokens[i] = t.substring(1);
      return int.parse(t[0]);
    }
    i++;
    return double.parse(t).round();
  }

  while (i < tokens.length) {
    if (isCmd(tokens[i])) {
      cmd = tokens[i++];
    }
    final rel = cmd == cmd.toLowerCase();
    switch (cmd.toUpperCase()) {
      case 'M':
        final nx = n() + (rel ? x : 0), ny = n() + (rel ? y : 0);
        path.moveTo(nx, ny);
        x = sx = nx;
        y = sy = ny;
        cmd = rel ? 'l' : 'L';
        cx2 = null;
        break;
      case 'L':
        x = n() + (rel ? x : 0);
        y = n() + (rel ? y : 0);
        path.lineTo(x, y);
        cx2 = null;
        break;
      case 'H':
        x = n() + (rel ? x : 0);
        path.lineTo(x, y);
        cx2 = null;
        break;
      case 'V':
        y = n() + (rel ? y : 0);
        path.lineTo(x, y);
        cx2 = null;
        break;
      case 'C':
        final x1 = n() + (rel ? x : 0), y1 = n() + (rel ? y : 0);
        final x2 = n() + (rel ? x : 0), y2 = n() + (rel ? y : 0);
        final ex = n() + (rel ? x : 0), ey = n() + (rel ? y : 0);
        path.cubicTo(x1, y1, x2, y2, ex, ey);
        cx2 = x2;
        cy2 = y2;
        x = ex;
        y = ey;
        break;
      case 'S':
        final rx1 = (cx2 != null && 'CS'.contains(prev.toUpperCase())) ? 2 * x - cx2 : x;
        final ry1 = (cy2 != null && 'CS'.contains(prev.toUpperCase())) ? 2 * y - cy2 : y;
        final x2 = n() + (rel ? x : 0), y2 = n() + (rel ? y : 0);
        final ex = n() + (rel ? x : 0), ey = n() + (rel ? y : 0);
        path.cubicTo(rx1, ry1, x2, y2, ex, ey);
        cx2 = x2;
        cy2 = y2;
        x = ex;
        y = ey;
        break;
      case 'Q':
        final x1 = n() + (rel ? x : 0), y1 = n() + (rel ? y : 0);
        final ex = n() + (rel ? x : 0), ey = n() + (rel ? y : 0);
        path.quadraticBezierTo(x1, y1, ex, ey);
        cx2 = x1;
        cy2 = y1;
        x = ex;
        y = ey;
        break;
      case 'T':
        final x1 = (cx2 != null && 'QT'.contains(prev.toUpperCase())) ? 2 * x - cx2 : x;
        final y1 = (cy2 != null && 'QT'.contains(prev.toUpperCase())) ? 2 * y - cy2 : y;
        final ex = n() + (rel ? x : 0), ey = n() + (rel ? y : 0);
        path.quadraticBezierTo(x1, y1, ex, ey);
        cx2 = x1;
        cy2 = y1;
        x = ex;
        y = ey;
        break;
      case 'A':
        final rx = n(), ry = n(), rot = n();
        final large = flag(), sweep = flag();
        final ex = n() + (rel ? x : 0), ey = n() + (rel ? y : 0);
        path.arcToPoint(Offset(ex, ey), radius: Radius.elliptical(rx, ry), rotation: rot, largeArc: large == 1, clockwise: sweep == 1);
        x = ex;
        y = ey;
        cx2 = null;
        break;
      case 'Z':
        path.close();
        x = sx;
        y = sy;
        cx2 = null;
        break;
      default:
        i++;
    }
    prev = cmd;
  }
  return path;
}

/// Degrees to radians.
double rad(num d) => d * math.pi / 180;
