import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../core/format.dart';
import '../core/models.dart';
import '../services/qr_label.dart';
import '../state/app_scope.dart';
import '../state/app_state.dart';
import 'art.dart';
import 'icons.dart';
import 'sheets.dart';
import 'theme.dart';
import 'widgets.dart';

const _typeName = LensType.names;

/// `.favbtn`: a pill with a heart, "Save to favorites" / "Saved to favorites".
class FavBtn extends StatelessWidget {
  final bool on;
  final String onText, offText;
  final VoidCallback onTap;
  final EdgeInsets margin;
  const FavBtn({
    super.key,
    required this.on,
    required this.onTap,
    this.onText = 'Saved to favorites',
    this.offText = 'Save to favorites',
    this.margin = const EdgeInsets.only(top: 12),
  });
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: margin,
      child: Semantics(
        button: true,
        toggled: on,
        child: Pressable(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 15, 8),
            decoration: BoxDecoration(
              color: c.card,
              border: Border.all(color: on ? c.ink : c.line),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgIcon(Ic.heart, size: 18, color: c.ink, filled: on),
                const SizedBox(width: 8),
                Text(
                  on ? onText : offText,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.ink),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// `powBtn(code)`: beside each added power, a QR code button (make a label) or, when the side menu says so, a
/// heart that saves that exact power to Favorites.
class PowBtn extends StatelessWidget {
  final String code;
  const PowBtn(this.code, {super.key});
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    if (s.qrMake) return IconBtn(Ic.qr, size: 20, label: 'QR code for this power', onTap: () => showQrSheet(context, code));
    final on = s.wishP.contains(code);
    return IconBtn(
      Ic.heart,
      size: 19,
      filled: on,
      label: on ? 'Remove this power from favorites' : 'Save this power to favorites',
      onTap: () => s.togglePowerFav(code),
    );
  }
}

/// A QR code drawn as modules (error correction M), black on white with a quiet zone.
class QrView extends StatelessWidget {
  final String code;
  final double size;
  const QrView(this.code, {super.key, this.size = 160});
  @override
  Widget build(BuildContext context) {
    final m = qrMatrix(code);
    return Semantics(
      image: true,
      label: 'QR code',
      child: Container(
        width: size,
        height: size,
        color: Colors.white,
        padding: EdgeInsets.all(size / (m.length + 8) * 4 / 2),
        child: CustomPaint(painter: _QrPainter(m)),
      ),
    );
  }
}

class _QrPainter extends CustomPainter {
  final List<List<bool>> m;
  _QrPainter(this.m);
  @override
  void paint(Canvas canvas, Size size) {
    final n = m.length, cell = size.width / n;
    final p = Paint()..color = Colors.black;
    final path = Path();
    for (var y = 0; y < n; y++) {
      for (var x = 0; x < n; x++) {
        if (m[y][x]) path.addRect(Rect.fromLTWH(x * cell, y * cell, cell + .3, cell + .3));
      }
    }
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_QrPainter old) => old.m != m;
}

/// `openQRSheet(code)`: the label for one power: envelope photo, lens, range, eye, power and the QR. Download PDF
/// shares an A6 PDF (save it, print it, send it on WhatsApp).
void showQrSheet(BuildContext context, String code) {
  final s = AppScope.read(context);
  final i = s.qrInfo(code);
  if (i == null) return;
  s.rememberQR(code);
  showAppSheet(context, (ctx) {
    final c = ctx.c;
    final env = envOf(i.p, i.li);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        sheetTitle(ctx, 'QR code for this power'),
        const Muted(
          'Download it, print it and keep it at the counter. Scanning it opens this lens with the power filled in; you only type the quantity.',
          margin: EdgeInsets.only(bottom: 12),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.line),
          ),
          child: Column(
            children: [
              if (env != null && s.data.envelopes.contains(env))
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.asset('assets/images/envelopes/$env.jpg', height: 110, fit: BoxFit.contain),
                  ),
                ),
              Text(
                'VISHAL OPTICAL CO.',
                style: TextStyle(fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w600, color: const Color(0xFF9A9CA3)),
              ),
              const SizedBox(height: 4),
              Text(
                i.name,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1B2130)),
              ),
              Text('${_typeName[i.p.ptype]} · ${i.range}', style: const TextStyle(fontSize: 12.5, color: Color(0xFF5D6370))),
              Text(i.eyeTxt, style: const TextStyle(fontSize: 12.5, color: Color(0xFF5D6370))),
              const SizedBox(height: 6),
              for (final pw in i.pw)
                Text(
                  pw,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1B2130), fontFeatures: kTabular),
                ),
              const SizedBox(height: 10),
              QrView(code, size: 176),
              const SizedBox(height: 6),
              SelectableText(
                code,
                style: const TextStyle(fontSize: 10.5, color: Color(0xFF9A9CA3), fontFamily: 'monospace'),
              ),
            ],
          ),
        ),
        sheetFoot([Btn('Close', ghost: true, onTap: () => Navigator.of(ctx).pop()), Btn('Download PDF', onTap: () => _saveLabel(ctx, s, i))]),
      ],
    );
  });
}

Future<void> _saveLabel(BuildContext context, AppState s, QrInfo i) async {
  final t = LabelText(name: i.name, typeAndRange: '${_typeName[i.p.ptype]} · ${i.range}', eyeTxt: i.eyeTxt, pw: i.pw);
  Uint8List? jpg;
  final env = envOf(i.p, i.li);
  if (env != null && s.data.envelopes.contains(env)) {
    try {
      jpg = (await rootBundle.load('assets/images/envelopes/$env.jpg')).buffer.asUint8List();
    } catch (_) {}
  }
  final name = labelFileName(t);
  final bytes = labelPdf(i.code, t, envelopeJpeg: jpg);
  final box = context.mounted ? context.findRenderObject() as RenderBox? : null;
  try {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(bytes, mimeType: 'application/pdf', name: name)],
        fileNameOverrides: [name],
        subject: 'QR label: ${i.name}',
        sharePositionOrigin: box != null ? box.localToGlobal(Offset.zero) & box.size : null,
      ),
    );
  } catch (_) {
    s.toast('The PDF could not be shared here.');
  }
}

/// `rangeRow(p, i)`: one range of a lens. Tap to order in it (parcel or bulk); the heart saves it to Favorites.
class RangeRow extends StatelessWidget {
  final Product p;
  final int li;
  final bool withName;
  const RangeRow(this.p, this.li, {super.key, this.withName = false});
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = context.c;
    final l = p.lines[li];
    final st = s.stock.stockOf(p, li);
    final on = s.wishR.contains('${p.id}:$li');
    return RowCard(
      thumb: withName ? ThumbBox(child: ProductArt(p, li: li)) : null,
      titleWidget: Text(
        '${withName ? '${shortName(p)} · ' : ''}${rg(l.range)}',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.ink, fontFeatures: kTabular),
      ),
      sub: '${withName ? '${_typeName[p.ptype]} · ' : ''}${l.read}${l.dia != null ? ' · ${l.dia} mm' : ''}',
      onTap: () => showRangeSheet(context, p, li),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (l.price != null && s.showPrice)
                Text(
                  money(s.logic.tier(l.price!)),
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: c.ink, fontFeatures: kTabular),
                ),
              StockTag(st, left: 0),
            ],
          ),
          IconBtn(
            Ic.heart,
            size: 19,
            filled: on,
            label: on ? 'Remove this range from favorites' : 'Save this range to favorites',
            onTap: () => s.toggleWishRange(p.id, li),
          ),
        ],
      ),
    );
  }
}

/// `rangepick`: a range was tapped. 6 Nov: no Parcel / Bulk question; it opens the power wheels inside that range
/// (Wheels or Power chart), and the cart asks Order as: Parcel / Bulk.
void showRangeSheet(BuildContext context, Product p, int li) {
  AppScope.read(context).parcelInRange(p.id, li);
}

/// `naBox(m)`: an N/A power (not kept: too little demand). One step either side in the same range, or the same
/// power in another brand.
class NaBox extends StatelessWidget {
  final Match m;
  final bool fromProduct;
  const NaBox(this.m, {super.key, required this.fromProduct});
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = context.c;
    final al = s.logic.naAlts(m);
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(16), boxShadow: c.e1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          eyebrow(context, 'N/A · not kept in this power'),
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 4),
            child: Text(
              '${shortName(m.p)} is not kept in ${powerTxt(m.uR, m.p.ptype)}.',
              style: TextStyle(fontWeight: FontWeight.w600, color: c.ink),
            ),
          ),
          Text(
            'There is too little demand for this power to keep it. Choose a power one step (0.25) away on the sphere or the cylinder, or the same power in another brand.',
            style: AppText.small(c),
          ),
          const SizedBox(height: 12),
          if (al.isNotEmpty)
            Row(
              children: [
                for (var i = 0; i < al.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: Pressable(
                      onTap: () => s.naAlt(al[i].rx, fromProduct: fromProduct),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                        decoration: BoxDecoration(
                          color: c.card,
                          border: Border.all(color: c.line),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Column(
                          children: [
                            Text(
                              powerTxt(al[i].rx, m.p.ptype),
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.ink, fontFeatures: kTabular),
                            ),
                            Text(
                              '${al[i].label}${al[i].low ? ' · low stock' : ''}',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: c.ink2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            )
          else
            Text('No stocked power one step away in this range.', style: AppText.small(c)),
          const SizedBox(height: 8),
          Btn('Same power in other brands', onTap: s.naOther),
        ],
      ),
    );
  }
}

/// `brandCard(p, name)`: a lens in a brand's list: open it, save it, see its ranges at a glance (tap one to order
/// in it), or open them all with hearts.
class BrandProductCard extends StatelessWidget {
  final Product p;
  final String name;
  const BrandProductCard(this.p, this.name, {super.key});
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = context.c;
    final on = s.wish.contains(p.id);
    final open = s.bopen.contains(p.id);
    final ls = p.lines;
    const nShow = 6;
    final from = s.logic.fromPrice(p);
    Widget chip(int i) {
      final fav = s.wishR.contains('${p.id}:$i');
      return Semantics(
        button: true,
        label: '${rg(ls[i].range)}, ${ls[i].read}',
        child: GestureDetector(
          onTap: () => showRangeSheet(context, p, i),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: c.card,
              border: Border.all(color: fav ? c.ink : c.line),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (fav) ...[SvgIcon(Ic.heart, size: 12, color: c.ink, filled: true), const SizedBox(width: 4)],
                Text(
                  rg(ls[i].range),
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.ink, fontFeatures: kTabular),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 6, 12),
      decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(16), boxShadow: c.e1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Pressable(
                  onTap: () => s.openProduct(p.id),
                  child: Row(
                    children: [
                      ThumbBox(child: ProductArt(p)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: c.ink),
                            ),
                            Text('${_typeName[p.ptype]} · ${titlecase(p.base)}', style: AppText.small(c)),
                            if (s.showPrice && from != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 3),
                                child: Text(
                                  'From ${money(from)}',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.ink, fontFeatures: kTabular),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              IconBtn(Ic.heart, filled: on, label: on ? 'Remove from favorites' : 'Save to favorites', onTap: () => s.toggleWish(p.id)),
            ],
          ),
          if (ls.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(2, 10, 6, 6),
              child: Row(
                children: [
                  Expanded(child: Text('${ls.length} range${ls.length == 1 ? '' : 's'}', style: AppText.small(c))),
                  LinkBtn(open ? 'Hide details' : 'Details and favorites', onTap: () => s.toggleBrandCard(p.id)),
                ],
              ),
            ),
            if (open)
              Padding(padding: const EdgeInsets.only(right: 6), child: Gap(gap: 6, [for (var i = 0; i < ls.length; i++) RangeRow(p, i)]))
            else
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (var i = 0; i < ls.length && i < nShow; i++) chip(i),
                  if (ls.length > nShow)
                    GestureDetector(
                      onTap: () => s.toggleBrandCard(p.id),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: c.card2, borderRadius: BorderRadius.circular(999)),
                        child: Text(
                          '+${ls.length - nShow} more',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.ink2),
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ],
      ),
    );
  }
}

/// Range tabs of a lens (bulk grid, and the power chart in Order by power): each tab shows the total typed in it.
class RangeTabs extends StatefulWidget {
  final Product p;
  final int li;
  final ValueChanged<int> onTap;
  final String? Function(int i) badge;
  final bool soon; // bulk: a range without a price says "soon"
  const RangeTabs({super.key, required this.p, required this.li, required this.onTap, required this.badge, this.soon = false});
  @override
  State<RangeTabs> createState() => _RangeTabsState();
}

class _RangeTabsState extends State<RangeTabs> {
  final _on = GlobalKey();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _on.currentContext;
      if (ctx != null) Scrollable.ensureVisible(ctx, alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final s = AppScope.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Strip(
        bleed: false,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        children: [
          for (var i = 0; i < widget.p.lines.length; i++)
            () {
              final x = widget.p.lines[i];
              final on = i == widget.li;
              final small =
                  '${x.dia != null ? '${x.dia} mm' : ''}${x.price != null && s.showPrice
                      ? ' · ${money(s.logic.tier(x.price!))}'
                      : x.price != null || !widget.soon
                      ? ''
                      : ' · soon'}';
              final dim = !widget.soon && const ['na', 'soon'].contains(s.stock.stockOf(widget.p, i).state);
              final b = widget.badge(i);
              return GestureDetector(
                key: on ? _on : null,
                onTap: () => widget.onTap(i),
                child: Opacity(
                  opacity: dim ? .55 : 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: on ? c.navy : c.card,
                      border: Border.all(color: on ? c.navy : c.line),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              rg(x.range),
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: on ? c.onNavy : c.ink, fontFeatures: kTabular),
                            ),
                            if (b != null)
                              Container(
                                margin: const EdgeInsets.only(left: 6),
                                constraints: const BoxConstraints(minWidth: 18),
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                decoration: BoxDecoration(color: on ? c.onNavy : c.good, borderRadius: BorderRadius.circular(999)),
                                child: Text(
                                  b,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11,
                                    height: 18 / 11,
                                    fontWeight: FontWeight.w600,
                                    color: on ? c.navy : Colors.white,
                                    fontFeatures: kTabular,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        Text(small, style: TextStyle(fontSize: 10.5, color: on ? c.onNavy.withValues(alpha: .8) : c.ink2)),
                      ],
                    ),
                  ),
                ),
              );
            }(),
        ],
      ),
    );
  }
}
