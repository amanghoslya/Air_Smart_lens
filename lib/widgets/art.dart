import 'package:flutter/material.dart';

import '../core/Data/Model/brands.dart';
import '../core/Utils/format.dart';
import '../core/Data/Model/models.dart';
import '../state/app_scope.dart';

/// A brand photograph from assets/images/brand with optional fallback.
class BrandImg extends StatelessWidget {
  final String k;
  final String? fallback;
  final BoxFit fit;
  final Alignment alignment;
  final String? semantic;
  const BrandImg(
    this.k, {
    super.key,
    this.fallback,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.semantic,
  });
  @override
  Widget build(BuildContext context) => Image.asset(
    envAlias.containsKey(k) ? 'assets/images/envelopes/${envAlias[k]}.jpg' : 'assets/images/brand/$k.jpg',
    fit: fit,
    alignment: alignment,
    semanticLabel: semantic,
    excludeFromSemantics: semantic == null,
    errorBuilder: (_, _, _) {
      if (fallback != null && fallback!.isNotEmpty && fallback != k) {
        return Image.asset(
          envAlias.containsKey(fallback) ? 'assets/images/envelopes/${envAlias[fallback]}.jpg' : 'assets/images/brand/$fallback.jpg',
          fit: fit,
          alignment: alignment,
          semanticLabel: semantic,
          excludeFromSemantics: semantic == null,
          errorBuilder: (_, _, _) => const SizedBox(),
        );
      }
      return const SizedBox();
    },
  );
}

/// The envelope photo of a range (2 Nov price file: one per range), or of the product's first range;
/// the lens art when there is none.
String? envOf(Product p, [int? li]) {
  final l = li != null && li >= 0 && li < p.lines.length ? p.lines[li] : null;
  return l?.env ?? p.env;
}

class ProductArt extends StatelessWidget {
  final Product p;
  final int? li;
  final double lensFraction;
  const ProductArt(this.p, {super.key, this.li, this.lensFraction = .72});
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final e = envOf(p, li);
    if (e != null && s.data.envelopes.contains(e)) {
      return Image.asset('assets/images/envelopes/$e.jpg', fit: BoxFit.cover, width: double.infinity, height: double.infinity, excludeFromSemantics: true);
    }
    return FractionallySizedBox(
      widthFactor: lensFraction,
      child: LensArt(tint: coatTint(p)),
    );
  }
}

Color coatTint(Product p) => Color(coatColorHex[coatKey(p)] ?? 0xFF9BA3AE).withValues(alpha: 0xB3 / 255);

/// `.lens`: a glass disc whose reflection takes the coating's colour.
class LensArt extends StatelessWidget {
  final Color tint;
  const LensArt({super.key, required this.tint});
  @override
  Widget build(BuildContext context) => AspectRatio(aspectRatio: 1, child: CustomPaint(painter: _LensArtPainter(tint)));
}

class _LensArtPainter extends CustomPainter {
  final Color tint;
  _LensArtPainter(this.tint);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final r = Offset.zero & size;
    final circle = Path()..addOval(r);
    // outer drop shadow: 0 6px 14px rgba(40,48,64,.16)
    canvas.drawPath(
      circle.shift(const Offset(0, 6)),
      Paint()
        ..color = const Color(0x29283040)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
    canvas.save();
    canvas.clipPath(circle);
    // base glass: rgba(250,251,252,.7) 0 50%, rgba(196,202,210,.75) 72%, rgba(128,138,152,.85) 100%
    canvas.drawRect(
      r,
      Paint()
        ..shader = RadialGradient(
          radius: .707,
          colors: const [Color(0xB3FAFBFC), Color(0xB3FAFBFC), Color(0xBFC4CAD2), Color(0xD980889A)],
          stops: const [0, .5, .72, 1],
        ).createShader(r),
    );
    // coating reflection at 66% 72%
    canvas.drawRect(
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(.32, .44),
          radius: .977,
          colors: [tint, tint.withValues(alpha: 0)],
          stops: const [0, .62],
        ).createShader(r),
    );
    // highlight at 34% 28%
    canvas.drawRect(
      r,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-.32, -.44),
          radius: .977,
          colors: [Color(0xF2FFFFFF), Color(0xF2FFFFFF), Color(0x00FFFFFF)],
          stops: [0, .08, .26],
        ).createShader(r),
    );
    // inset 0 -6px 12px rgba(120,130,145,.25)
    canvas.drawPath(
      Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(r.inflate(20))
        ..addOval(r.translate(0, -6)),
      Paint()
        ..color = const Color(0x40788291)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.restore();
    // inset 0 0 0 1px rgba(255,255,255,.7)
    canvas.drawOval(
      r.deflate(.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0xB3FFFFFF),
    );
    // :after ring at 7%
    canvas.drawOval(
      r.deflate(w * .07 + .5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0xA6FFFFFF),
    );
  }

  @override
  bool shouldRepaint(_LensArtPainter old) => old.tint != tint;
}
