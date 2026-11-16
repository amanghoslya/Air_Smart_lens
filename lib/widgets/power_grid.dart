import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/Utils/format.dart';
import '../core/Utils/js_compat.dart';
import '../core/Data/Model/models.dart';
import '../core/Utils/quantity.dart';
import '../state/app_state.dart';
import 'theme.dart';

String gridKey(GridRow r, double col) => '${r.key}|${jsNum(col)}';

/// A power grid of one range: rows of powers by columns of CYL (single vision) or ADD (KT and progressive). The
/// header row and the first column stay in place while the body scrolls. Each box is a number field, so the
/// phone's own number keyboard opens; Next moves to the next box. Used by bulk ordering (whole numbers) and by
/// the power chart inside a range (29 Oct; halves allowed).
///
/// Boxes show the status of their power (30 Oct): N/A (not kept, cannot be typed in), sold out (striped: typing
/// pre-orders it), low stock (a small dot). Hatched: not in this range.
class PowerGridView extends StatefulWidget {
  final AppState s;
  final Product p;
  final int li;
  final PowerGrid gr;
  final Map<String, double> values; // stored quantity per box (pairs, or lenses for one eye)
  final int mul; // shown = stored × mul (pieces of single vision / KT)
  final bool decimals; // the power chart takes halves
  final ValueChanged<String> onSelect;
  final void Function(String k, double shown) onType;
  final void Function(String k, double shown)? onLeave; // round on leaving a box
  final double maxHeight;
  const PowerGridView({
    super.key,
    required this.s,
    required this.p,
    required this.li,
    required this.gr,
    required this.values,
    required this.onSelect,
    required this.onType,
    this.onLeave,
    this.mul = 1,
    this.decimals = false,
    this.maxHeight = 330,
  });
  @override
  State<PowerGridView> createState() => _PowerGridViewState();
}

class _PowerGridViewState extends State<PowerGridView> {
  static const cellW = 46.0, rowH = 37.0, headH = 31.0;
  final _h = ScrollController(), _v = ScrollController(), _hHead = ScrollController(), _vCol = ScrollController();
  final Map<String, TextEditingController> _ctl = {};
  final Map<String, FocusNode> _fn = {};

  @override
  void initState() {
    super.initState();
    _h.addListener(() {
      if (_hHead.hasClients) _hHead.jumpTo(_h.offset);
    });
    _v.addListener(() {
      if (_vCol.hasClients) _vCol.jumpTo(_v.offset);
    });
  }

  @override
  void dispose() {
    for (final c in _ctl.values) {
      c.dispose();
    }
    for (final f in _fn.values) {
      f.dispose();
    }
    _h.dispose();
    _v.dispose();
    _hHead.dispose();
    _vCol.dispose();
    super.dispose();
  }

  String _shown(String k) {
    final q = widget.values[k];
    return q != null && q > 0 ? nfmt(q * widget.mul) : '';
  }

  TextEditingController _c(String k) => _ctl.putIfAbsent(k, () => TextEditingController(text: _shown(k)));
  FocusNode _f(String k) => _fn.putIfAbsent(k, () {
    final n = FocusNode();
    n.addListener(() {
      if (n.hasFocus) {
        widget.onSelect(k);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final c = _c(k);
          c.selection = TextSelection(baseOffset: 0, extentOffset: c.text.length);
        });
      } else if (widget.onLeave != null) {
        widget.onLeave!(k, double.tryParse(_c(k).text) ?? 0);
      }
      if (mounted) setState(() {});
    });
    return n;
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final s = widget.s;
    final gr = widget.gr;
    final st = <String, StockStatus>{for (final k in gr.cells) k: s.stock.cellStock(widget.p, widget.li, k)};
    final openKeys = [
      for (final r in gr.rows)
        for (final col in gr.cols)
          if (gr.cells.contains(gridKey(r, col)) && st[gridKey(r, col)]!.state != 'na') gridKey(r, col),
    ];
    // keep the boxes in step with the order (Clear, Pairs / Pieces)
    for (final k in openKeys) {
      final want = _shown(k);
      final ctl = _c(k);
      final focused = _fn[k]?.hasFocus ?? false;
      if (!focused && ctl.text != want) ctl.text = want;
    }
    final labelStyle = TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.ink, fontFeatures: kTabular);
    var firstW = 58.0;
    for (final r in gr.rows) {
      final tp = TextPainter(
        text: TextSpan(text: r.label, style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      firstW = firstW < tp.width + 13 ? tp.width + 13 : firstW;
    }
    final head = gr.isAdd ? 'SPH/CYL · ADD' : 'SPH · CYL';
    final headTp = TextPainter(
      text: TextSpan(text: head, style: labelStyle.copyWith(fontSize: 11)),
      textDirection: TextDirection.ltr,
    )..layout();
    if (headTp.width + 13 > firstW) firstW = headTp.width + 13;
    final total = headH + gr.rows.length * rowH;
    final height = total + 2 > widget.maxHeight ? widget.maxHeight : total + 2;
    final border = BorderSide(color: c.line);
    final headStyle = TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: c.ink2, fontFeatures: kTabular);

    Widget cell(String k, GridRow r, double col) {
      final box = BoxDecoration(
        border: Border(bottom: border, right: border),
      );
      if (!gr.cells.contains(k)) {
        return Semantics(
          label: 'Not in this range',
          child: Container(
            width: cellW,
            height: rowH,
            decoration: box,
            child: CustomPaint(painter: Hatch(c.line)),
          ),
        );
      }
      final cs = st[k]!;
      if (cs.state == 'na') {
        return Semantics(
          label: 'N/A: not kept in this power',
          child: Container(
            width: cellW,
            height: rowH,
            decoration: box.copyWith(color: c.sunk),
            alignment: Alignment.center,
            child: Text(
              'N/A',
              style: TextStyle(fontSize: 10, letterSpacing: .4, fontWeight: FontWeight.w600, color: c.mute),
            ),
          ),
        );
      }
      final f = _f(k);
      final has = (widget.values[k] ?? 0) > 0;
      final so = cs.state == 'zero';
      final idx = openKeys.indexOf(k);
      final last = idx == openKeys.length - 1;
      return Container(
        width: cellW,
        height: rowH,
        decoration: box.copyWith(
          color: f.hasFocus
              ? c.card
              : so && has
              ? c.warnSoft
              : has
              ? c.sunk
              : Colors.transparent,
        ),
        foregroundDecoration: f.hasFocus ? BoxDecoration(border: Border.all(color: c.ink, width: 2)) : null,
        child: Stack(
          children: [
            if (so && !has && !f.hasFocus) Positioned.fill(child: CustomPaint(painter: Hatch(c.warnSoft, gap: 9, width: 6))),
            if (cs.low)
              Positioned(
                top: 4.5,
                right: 4.5,
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(color: c.warn, shape: BoxShape.circle),
                ),
              ),
            Semantics(
              label:
                  '${r.label} ${fmt(col)}${so
                      ? ', sold out: typing here pre-orders it'
                      : cs.low
                      ? ', low stock'
                      : ''}',
              child: TextField(
                controller: _c(k),
                focusNode: f,
                keyboardType: TextInputType.numberWithOptions(decimal: widget.decimals),
                textInputAction: last ? TextInputAction.done : TextInputAction.next,
                inputFormatters: widget.decimals
                    ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d?')), LengthLimitingTextInputFormatter(5)]
                    : [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: so ? c.warn : c.ink, fontFeatures: kTabular),
                cursorWidth: 1.5,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isCollapsed: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  hintText: '·',
                  hintStyle: TextStyle(color: c.mute, fontWeight: FontWeight.w400),
                ),
                onChanged: (v) => widget.onType(k, double.tryParse(v.replaceAll(',', '.')) ?? 0),
                onSubmitted: (_) {
                  if (!last) {
                    _f(openKeys[idx + 1]).requestFocus();
                  } else {
                    f.unfocus();
                  }
                },
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: height,
      decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(14), boxShadow: c.e1),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          SizedBox(
            height: headH,
            child: Row(
              children: [
                Container(
                  width: firstW,
                  height: headH,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(
                    color: c.card2,
                    border: Border(bottom: border, right: border),
                  ),
                  child: Text(head, maxLines: 1, style: headStyle),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _hHead,
                    scrollDirection: Axis.horizontal,
                    physics: const NeverScrollableScrollPhysics(),
                    child: Row(
                      children: [
                        for (final col in gr.cols)
                          Container(
                            width: cellW,
                            height: headH,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: c.card2,
                              border: Border(bottom: border),
                            ),
                            child: Text(fmt(col), style: headStyle),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                SizedBox(
                  width: firstW,
                  child: SingleChildScrollView(
                    controller: _vCol,
                    physics: const NeverScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        for (final r in gr.rows)
                          Container(
                            width: firstW,
                            height: rowH,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            alignment: Alignment.centerLeft,
                            decoration: BoxDecoration(
                              color: c.card2,
                              border: Border(bottom: border, right: border),
                            ),
                            child: Text(r.label, maxLines: 1, softWrap: false, style: labelStyle),
                          ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Scrollbar(
                    controller: _v,
                    child: SingleChildScrollView(
                      controller: _v,
                      child: SingleChildScrollView(
                        controller: _h,
                        scrollDirection: Axis.horizontal,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final r in gr.rows) Row(children: [for (final col in gr.cols) cell(gridKey(r, col), r, col)]),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Diagonal hatching: powers outside the range, and sold-out boxes.
class Hatch extends CustomPainter {
  final Color color;
  final double gap, width;
  Hatch(this.color, {this.gap = 5 * 1.414, this.width = 1});
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = width;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    for (var x = -size.height; x < size.width; x += gap) {
      canvas.drawLine(Offset(x, size.height), Offset(x + size.height, 0), p);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(Hatch old) => old.color != color || old.gap != gap || old.width != width;
}

/// `legendHTML()`: Low stock · Sold out: pre-order · N/A: not kept.
class GridLegend extends StatelessWidget {
  const GridLegend({super.key});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    Widget key(Widget sw, String t) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        sw,
        const SizedBox(width: 6),
        Text(t, style: TextStyle(fontSize: 11.5, color: c.ink2)),
      ],
    );
    BoxDecoration sq(Color bg) => BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(3),
      border: Border.all(color: c.line),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 8, 2, 0),
      child: Wrap(
        spacing: 12,
        runSpacing: 6,
        children: [
          key(
            Container(
              width: 16,
              height: 12,
              decoration: sq(c.card2),
              alignment: Alignment.center,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: c.warn, shape: BoxShape.circle),
              ),
            ),
            'Low stock',
          ),
          key(
            Container(
              width: 16,
              height: 12,
              decoration: sq(c.card2),
              child: CustomPaint(painter: Hatch(c.warnSoft, gap: 6, width: 4)),
            ),
            'Sold out: pre-order',
          ),
          key(
            Container(
              width: 22,
              height: 12,
              decoration: sq(c.sunk),
              alignment: Alignment.center,
              child: Text(
                'N/A',
                style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: c.mute),
              ),
            ),
            'Not kept',
          ),
        ],
      ),
    );
  }
}

/// `pwBlocks(T, lt)`: the chosen power, field by field: SPH, CYL (with axis for KT and progressive), ADD.
class PowerBlocks extends StatelessWidget {
  final Rx t;
  final String lt;
  const PowerBlocks(this.t, this.lt, {super.key});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final f = <(String, String)>[
      ('SPH', fmt(t.sph)),
      if (t.cyl != 0) ('CYL', fmt(t.cyl)),
      if (t.cyl != 0 && lt != LensType.sv) ('AXIS', '${t.axis}°'),
      if (lt != LensType.sv) ('ADD', fmt(t.add)),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final x in f)
          Container(
            constraints: const BoxConstraints(minWidth: 64),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(10), boxShadow: c.e1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  x.$1,
                  style: TextStyle(fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.w600, color: c.mute),
                ),
                Text(
                  x.$2,
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: c.ink, fontFeatures: kTabular),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// `.pcsel`: the selected box of a grid: its power, its quantity, and whether it is sold out.
class SelectedBox extends StatelessWidget {
  final Product p;
  final int li;
  final String? k;
  final String qtyWord; // '' when nothing typed
  final StockStatus? st;
  final Rx? power;
  final String empty;
  final String title;
  const SelectedBox({
    super.key,
    required this.p,
    required this.li,
    required this.k,
    required this.qtyWord,
    this.st,
    this.power,
    required this.empty,
    this.title = 'Selected',
  });
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final so = st?.state == 'zero';
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: c.card2, borderRadius: BorderRadius.circular(12)),
      child: k == null || power == null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TAP A BOX', style: AppText.eyebrow(c)),
                const SizedBox(height: 4),
                Text(empty, style: AppText.small(c)),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${qtyWord.isNotEmpty ? '$title · $qtyWord' : title}${so ? ' · sold out, pre-order${st!.eta != null ? ' · back in ${st!.eta}' : ''}' : ''}'
                      .toUpperCase(),
                  style: AppText.eyebrow(c),
                ),
                const SizedBox(height: 6),
                PowerBlocks(power!, p.ptype),
              ],
            ),
    );
  }
}
