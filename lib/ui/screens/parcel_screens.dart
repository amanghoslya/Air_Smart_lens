import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:air_smart_lens/Screens/Home_Screen/Provider/catalogProvider.dart';
import 'package:air_smart_lens/Screens/Home_Screen/Provider/productDetailsProvider.dart';
import 'package:air_smart_lens/core/Data/responseModel/catalogResModel.dart' as catalog_res;
import 'package:air_smart_lens/core/Data/responseModel/productDetailsResModel.dart';

import '../../core/brands.dart';
import '../../core/format.dart';
import '../../core/models.dart';
import '../../core/quantity.dart';
import '../../state/app_scope.dart';
import '../../state/app_state.dart';
import '../art.dart';
import '../lens3d.dart' show LoaderLens;
import '../parts.dart';
import '../power_grid.dart';
import '../icons.dart';
import '../shell.dart';
import '../theme.dart';
import '../wheels.dart';
import '../widgets.dart';

const typeName = LensType.names;

// ---------------------------------------------------------------- power

ScreenView rxScreen(BuildContext context, AppState s) {
  final c = context.c;
  final lt = s.lens;
  final cols = s.rxCols;
  final fx = s.only != null ? s.product(s.only!) : null;
  final pe = qKind(lt, s.peye);
  final l = s.rxL;
  final info = s.rxModeInfo(lt);
  final mode = info.mode;
  final lk = s.lockInfo;
  final lkR = lk != null && lk.li != null ? fx!.lines[lk.li!] : null;
  final fxm = s.fxMatch(info.m);
  final pso = fxm != null && !fxm.mto ? s.logic.powStock(fxm) : null;
  final so = pso?.state == 'zero', na = pso?.state == 'na';
  final code = lkR != null
      ? rg(lkR.range)
      : mode == 'rx'
          ? 'Outside stocked ranges'
          : mode == 'mto'
              ? 'Made to order'
              : s.logic.rxCode(info.m, s.rx, l);
  final tl = typeName[lt]!.toLowerCase();
  final note = lkR != null
      ? (fxm != null
          ? '${s.stock.stockOf(fx!, lk!.li!).state == 'in' ? 'Available' : StockStatus.labels[s.stock.stockOf(fx, lk.li!).state]} in this range. Only its powers can be chosen: ${lkR.read}.'
          : 'This power is not in ${rg(lkR.range)}.')
      : fx != null
          ? (fxm != null
              ? '${shortName(fx)} ${fxm.mto ? 'is made to order in this power' : fxm.diff ? 'has the nearest power, ${s.diffText(fxm, lt)}' : 'stocks this power'}.'
              : '${shortName(fx)} does not stock this power. Change the power, or see other lenses.')
          : switch (mode) {
              'ok' =>
                '${info.nEx} lens${info.nEx == 1 ? '' : 'es'} stock${info.nEx == 1 ? 's' : ''} this power.${info.nNear > 0 ? ' ${info.nNear} more in a nearby power.' : ''}',
              'near' => 'No lens has exactly this power. ${info.nNear} ha${info.nNear == 1 ? 's' : 've'} one a step (0.25) away.',
              'mto' => 'No stocked lens has this power; the RX progressive can be made to order.',
              'listed' => 'Lenses list this power but none can be ordered right now.',
              _ => lt == LensType.prog
                  ? 'No lens has this power. It can be sent as an RX request; our staff will check it with the lab and call with the price and date.'
                  : 'No $tl lens is stocked in this power, and $tl lenses are not made to order.',
            };
  final rxm = s.rxMode;
  final qa = fx != null && !rxm;
  final ch = qa && lk != null && s.pview == 'chart';
  final inCart = <(CartLine, int)>[
    if (fx != null)
      for (var i = 0; i < s.cart.length; i++)
        if (s.cart[i].kind == 'one' && s.cart[i].pid == fx.id) (s.cart[i], i),
  ].reversed.toList(); // newest first (5 Nov)
  final preHere = <(PreOrder, int)>[
    if (fx != null)
      for (var i = 0; i < s.pre.length; i++)
        if (s.pre[i].kind == 'power' && s.pre[i].pid == fx.id) (s.pre[i], i),
  ];
  String pTxt(CartLine x) => x.rxL != null
      ? 'R ${powerTxt(x.rx, lt)} · L ${powerTxt(x.rxL!, lt)}'
      : (x.qR != 0 && x.qL == 0
              ? 'R '
              : x.qR == 0 && x.qL != 0
                  ? 'L '
                  : '') +
          powerTxt(x.rx, lt);
  final unit = qa && fxm != null && !fxm.mto ? s.logic.pairPrice(fxm.p, fxm.li, fxm.liL) : null;

  // the power table: only for an RX progressive with a different left eye
  final activeEye = s.eye == 'L' && l != null ? 'L' : 'R';
  Widget cell(String eye, String f) {
    final t = eye == 'L' ? (l ?? s.rx) : s.rx;
    return LiveCell(s: s, eye: eye, f: f, value: t.field(f), on: activeEye == eye && s.field == f, same: eye == 'L' && l == null);
  }

  Widget tRow(String title, String sub, String cellEye) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            SizedBox(
              width: 64,
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '$title\n',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.ink),
                    ),
                    TextSpan(
                      text: sub,
                      style: TextStyle(fontSize: 12, color: c.ink2),
                    ),
                  ],
                ),
              ),
            ),
            for (final f in cols)
              Expanded(
                child: Padding(padding: const EdgeInsets.symmetric(horizontal: 2), child: cell(cellEye, f)),
              ),
          ],
        ),
      );
  final showTable = rxm && lt == LensType.prog && pe == 'P';
  final table = Padding(
    padding: const EdgeInsets.only(top: 14, bottom: 4),
    child: Column(
      children: [
        Row(
          children: [
            const SizedBox(width: 64),
            for (final f in cols)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    fieldAbbr[f]!,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: c.ink2),
                  ),
                ),
              ),
          ],
        ),
        tRow('Right', 'OD', 'R'),
        tRow('Left', 'OS', 'L'),
      ],
    ),
  );

  final codeKind = mode == 'near' || mode == 'mto'
      ? 'warn'
      : mode == 'rx'
          ? 'bad'
          : '';
  final wished = lk != null && lk.li != null && s.wishR.contains('${fx!.id}:${lk.li}');
  final blocks = <Widget>[
    Hd(
      rxm
          ? 'RX progressive'
          : qa
              ? 'Add powers'
              : 'Parcel order',
    ),
    if (rxm) const Muted('Progressive · made at the lab', align: TextAlign.center, margin: EdgeInsets.only(bottom: 10)),
    if (fx != null)
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('For ${shortName(fx)}', style: AppText.small(c)),
            if (lkR != null) ...[
              Text(' · range ', style: AppText.small(c)),
              Text(
                rg(lkR.range),
                style: AppText.small(c).copyWith(fontWeight: FontWeight.w700, color: c.ink, fontFeatures: kTabular),
              ),
              Text(' · ', style: AppText.small(c)),
              LinkBtn('All ranges', onTap: s.unlockRange, size: 12.5),
            ] else if (qa)
              Text(' · same lens, any of its ranges', style: AppText.small(c)),
          ],
        ),
      ),
    if (qa && lk != null)
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Expanded(
              child: Seg(items: const [('wheel', 'Wheels'), ('chart', 'Power chart')], value: s.pview, onTap: s.setPview),
            ),
            if (lkR != null && !ch) ...[
              const SizedBox(width: 10),
              FavBtn(on: wished, onText: 'Range saved', offText: 'Save range', margin: EdgeInsets.zero, onTap: () => s.toggleWishRange(fx.id, lk.li!)),
            ],
          ],
        ),
      ),
    if (!rxm)
      Seg(
        items: const [(LensType.sv, 'Single vision'), (LensType.kt, 'KT'), (LensType.prog, 'Progressive')],
        value: lt,
        onTap: s.segLens,
        disabled: (v) => fx != null && fx.ptype != v,
      ),
    if (lt == LensType.prog)
      Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Seg(items: const [('P', 'BE · both eyes'), ('R', 'Right eye'), ('L', 'Left eye')], value: pe, onTap: s.setPeye),
      ),
    if (showTable) table,
    if (l != null && pe == 'P')
      Align(
        alignment: Alignment.centerRight,
        child: LinkBtn('Left same as right', onTap: s.leftSameAsRight),
      ),
    if (ch) PowerChart(s: s) else const PowerWheels(),
    // 5 Nov: Order by power for a whole lens shows every range under the wheels (6 Nov: only there)
    if (fx != null && !rxm && !ch && s.byPow && lkR == null) RangeStrip(s: s, p: fx),
    if (s.needCyl)
      NoteBox.text(
        'Sphere is off, so this is a cylinder-only power: set the cylinder${lt != LensType.sv ? ', the axis and the ADD' : ''}.',
        kind: 'warn',
        margin: const EdgeInsets.only(top: 10),
      ),
    if (rxm)
      NoteBox.text(_rxModeNote(s, lt))
    else ...[
      if (!(lkR != null && fxm != null)) ...[
        // the range code row is for every lens; with one lens chosen the note says it
        if (fx == null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              children: [
                Text('Range', style: TextStyle(fontSize: 12.5, color: c.ink2)),
                const SizedBox(width: 8),
                CodeBadge(code, kind: codeKind),
              ],
            ),
          ),
        NoteBox(
          kind: lkR != null
              ? (fxm != null ? '' : 'bad')
              : mode == 'rx' || (fx != null && fxm == null)
                  ? 'bad'
                  : mode == 'near'
                      ? 'warn'
                      : '',
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  note +
                      (lt == LensType.kt && s.rx.cyl != 0 && lk == null
                          ? ' KT is stocked at 45°, 90°, 135° and 180°; the axis is rounded to the nearest.'
                          : ''),
                ),
              ),
              if (fx != null)
                GestureDetector(
                  onTap: s.clearLens,
                  child: Semantics(
                    button: true,
                    label: 'Remove this lens and choose from every lens',
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: SvgIcon(Ic.x, size: 16, color: c.ink2),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
      if (!qa)
        InfoBox(
          margin: const EdgeInsets.only(top: 10),
          child: QtyCtl(kind: pe, n: s.aq, onStep: s.aqStep, unit: s.unit, onUnit: s.setUnit, onTyped: s.setAq),
        ),
    ],
    if (qa && pso != null && !ch && !so && !na)
      Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: c.card2, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Expanded(
              child: Text('This power', style: TextStyle(fontSize: 13, color: c.ink2)),
            ),
            StockTag(pso, left: 0),
          ],
        ),
      ),
    if (qa && so && !ch)
      NoteBox(
        kind: 'warn',
        margin: const EdgeInsets.only(top: 10),
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Sold out in this power${pso!.eta != null ? ' · back in ${pso.eta}' : ''}. ',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const TextSpan(text: 'Pre-order it: it is held for you and sent as soon as stock arrives. You pay when it is invoiced.'),
            ],
          ),
        ),
      ),
    if (qa && na && !ch) NaBox(fxm!, fromProduct: false),
    if (qa) ...[
      if (!ch && !na)
        InfoBox(
          margin: const EdgeInsets.only(top: 10),
          child: QtyCtl(kind: pe, n: s.aq, onStep: s.aqStep, unit: s.unit, onUnit: s.setUnit, onTyped: s.setAq),
        ),
      if (!(na && !ch))
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Center(child: LinkBtn('Other lenses for this power', onTap: s.otherLenses)),
        ),
      if (preHere.isNotEmpty) ...[
        const Sec('Pre-ordered for this lens'),
        Gap([
          for (final x in preHere)
            RowCard(
              titleWidget: Text(
                s.preTxt(x.$1).split(' · ').first,
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: c.ink, fontFeatures: kTabular),
              ),
              sub: '${s.preTxt(x.$1).split(' · ').last}${x.$1.eta.isNotEmpty ? ' · back in ${x.$1.eta}' : ''}',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Pill('Pre-order', kind: 'warn'),
                  IconBtn(Ic.trash, size: 18, label: 'Cancel pre-order', onTap: () => s.removePre(x.$2)),
                ],
              ),
            ),
        ]),
      ],
      if (inCart.isNotEmpty) ...[
        const Sec('In your cart for this lens'),
        Gap([
          for (final x in inCart)
            RowCard(
              titleWidget: Text(
                pTxt(x.$1),
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: c.ink, fontFeatures: kTabular),
              ),
              sub: '${lineQtyTxt(x.$1)}${x.$1.diff ? ' · different power' : ''}',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (x.$1.stock != 'mto') PowBtn(s.cartCode(x.$1)),
                  IconBtn(Ic.trash, size: 18, label: 'Remove', onTap: () => s.removeLine(x.$2)),
                ],
              ),
            ),
        ]),
        Muted(
          s.qrMake ? 'The QR button makes a label for that power: print it, scan it next time.' : 'The heart saves that exact power to Favorites.',
          margin: const EdgeInsets.fromLTRB(2, 8, 2, 0),
        ),
      ],
    ],
  ];

  Widget foot;
  final n = s.cart.length;
  if (ch) {
    final t = s.pqTotals;
    foot = Expanded(
      child: Row(
        children: [
          Btn('Check out${n > 0 ? ' ($n)' : ''}', ghost: true, onTap: s.openCart),
          const SizedBox(width: 10),
          Btn(
            '${t.ks.isNotEmpty ? 'Add ${t.ks.length}${t.nr > 1 ? ' · ${t.nr} ranges' : ''}' : 'Add'}${s.showPrice && t.value > 0 ? ' · ${money(t.value)}' : ''}',
            onTap: t.ks.isNotEmpty ? s.chartAdd : null,
          ),
        ],
      ),
    );
  } else if (qa && so) {
    foot = Expanded(
      child: Row(
        children: [
          Btn('Check out${n > 0 ? ' ($n)' : ''}', ghost: true, onTap: s.openCart),
          const SizedBox(width: 10),
          Btn('Pre-order', onTap: s.preAdd),
        ],
      ),
    );
  } else if (qa) {
    foot = Expanded(
      child: Row(
        children: [
          Btn('Check out${n > 0 ? ' ($n)' : ''}', ghost: true, onTap: s.openCart),
          const SizedBox(width: 10),
          Btn(
            'Add${s.showPrice && unit != null ? ' · ${money(unit * pairsOf(pe, s.aq))}' : ''}',
            onTap: fxm != null && !fxm.mto && !na && !s.needCyl ? s.quickAdd : null,
          ),
        ],
      ),
    );
  } else if (rxm) {
    foot = Btn('Continue', onTap: s.needCyl ? null : s.rxDetailsGo);
  } else {
    foot = Btn(mode == 'rx' && fx == null && lt == LensType.prog ? 'Continue to RX request' : 'Continue', onTap: s.needCyl ? null : s.rxContinue);
  }
  return ScreenView(blocks, foot: foot);
}

/// The power chart inside one range (29 Oct): the same grid as bulk ordering; type the quantity of each power.
class PowerChart extends StatelessWidget {
  final AppState s;
  const PowerChart({super.key, required this.s});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final lk = s.chartLK!;
    final p = lk.p, li = lk.li;
    final gr = s.logic.lineGrid(p, li);
    final pe = s.pe;
    final mul = uMul(pe, s.unit);
    final k = s.pcSel;
    // 6 Nov: Order by power: range tabs on top as in bulk; each range keeps its own quantities
    final tabs = s.byPow
        ? Bleed(
            child: RangeTabs(
              p: p,
              li: li,
              onTap: s.chartTab,
              badge: (i) {
                final q = i == li ? s.pq : (s.pqs[i] ?? const <String, double>{});
                final tq = q.values.fold<double>(0, (a, b) => a + b);
                return tq > 0 ? nfmt(tq * mul) : null;
              },
            ),
          )
        : null;
    final box = Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.line),
        boxShadow: c.e1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (pe == 'H')
            UnitSwitch(unit: s.unit, onUnit: s.setUnit, label: 'Quantities in')
          else
            Row(
              children: [
                Text('QUANTITIES IN', style: AppText.eyebrow(c).copyWith(fontSize: 11)),
                const SizedBox(width: 14),
                Text(
                  pe == 'P' ? 'Pairs' : 'Pieces · ${pe == 'R' ? 'right eye' : 'left eye'}',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.ink),
                ),
              ],
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Type ${pe == 'R' || pe == 'L' || isPcs(pe, s.unit) ? 'pieces' : 'pairs'}',
                        style: TextStyle(fontWeight: FontWeight.w600, color: c.ink),
                      ),
                      const TextSpan(text: ' in each power you need'),
                    ],
                  ),
                  style: TextStyle(fontSize: 12, color: c.ink2),
                ),
              ),
              Text(gr.isAdd ? 'SPH / CYL down · ADD across' : 'SPH down · CYL across', style: TextStyle(fontSize: 11.5, color: c.mute)),
            ],
          ),
          const SizedBox(height: 10),
          PowerGridView(
            key: ValueKey('chart-${p.id}-$li-$pe-${s.unit}'),
            s: s,
            p: p,
            li: li,
            gr: gr,
            values: s.pq,
            mul: mul,
            decimals: true,
            onSelect: s.chartSelect,
            onType: (key, v) => s.chartType(key, v),
            onLeave: (key, v) => s.chartType(key, v, round: true),
          ),
          const GridLegend(),
          SelectedBox(
            p: p,
            li: li,
            k: k,
            qtyWord: k != null && (s.pq[k] ?? 0) > 0 ? qWord(pe, s.pq[k]!, unit: s.unit) : '',
            st: k != null ? s.stock.cellStock(p, li, k) : null,
            power: k != null ? s.logic.cellPower(p, k) : null,
            empty: 'Its power shows here; type the quantity in the box',
          ),
        ],
      ),
    );
    return tabs == null ? box : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [const SizedBox(height: 10), tabs, box]);
  }
}

/// Range strip (5 Nov): under the wheels of one lens (Order by power), every range of that lens. The range the
/// dialled power falls in is highlighted, live while a wheel turns; tapping a range moves the wheels into it.
class RangeStrip extends StatefulWidget {
  final AppState s;
  final Product p;
  const RangeStrip({super.key, required this.s, required this.p});
  @override
  State<RangeStrip> createState() => _RangeStripState();
}

class _RangeStripState extends State<RangeStrip> {
  final _keys = <int, GlobalKey>{};
  int _last = -2;

  void _scrollTo(int on) {
    if (on == _last) return;
    _last = on;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _keys[on]?.currentContext;
      if (ctx != null && mounted) Scrollable.ensureVisible(ctx, alignment: .5, duration: const Duration(milliseconds: 200));
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s, p = widget.p;
    final c = context.c;
    return ValueListenableBuilder(
      valueListenable: s.wheelLive,
      builder: (context, live, _) {
        var t = s.padTarget;
        if (live != null) t = t.withField(live.f, live.v);
        final on = s.stripOn(p, t);
        _scrollTo(on);
        return Container(
          margin: const EdgeInsets.only(top: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${p.lines.length} range${p.lines.length == 1 ? '' : 's'} in this lens',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: c.ink),
                    ),
                  ),
                  Text(on >= 0 ? 'In ${rg(p.lines[on].range)}' : 'This power is in none of them', style: AppText.small(c)),
                ],
              ),
              const SizedBox(height: 8),
              Bleed(
                child: Strip(
                  bleed: false,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  children: [
                    for (var i = 0; i < p.lines.length; i++)
                      () {
                        final l = p.lines[i];
                        final sel = i == on;
                        final dim = const ['na', 'soon'].contains(s.stock.stockOf(p, i).state);
                        return Semantics(
                          button: true,
                          selected: sel,
                          child: GestureDetector(
                            key: _keys.putIfAbsent(i, GlobalKey.new),
                            onTap: () => s.rangeJump(i),
                            child: Opacity(
                              opacity: dim ? .5 : 1,
                              child: Container(
                                constraints: const BoxConstraints(maxWidth: 170),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: sel ? c.navy : c.card,
                                  border: Border.all(color: sel ? c.navy : c.line),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      rg(l.range),
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: sel ? c.onNavy : c.ink, fontFeatures: kTabular),
                                    ),
                                    Text(
                                      l.read,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 10.5, color: sel ? c.onNavy.withValues(alpha: .8) : c.ink2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

String _rxModeNote(AppState s, String lt) {
  final m = s.logic.matchProducts(lt, s.rx, s.rxL).where((x) => x.mto).toList();
  return m.isNotEmpty
      ? 'The ${shortName(m.first.p)} is made to order in this power${s.rx.cyl != 0 ? '; the axis is made in 10° steps' : ''}. You will see the price on the next screen.'
      : 'No lab lens in the price list covers this power, so it goes as an RX request. Our staff call you with the lens, lab price and date.';
}

/// `.code`: the price-file code of a power.
class CodeBadge extends StatelessWidget {
  final String text;
  final String kind;
  final double size;
  const CodeBadge(this.text, {super.key, this.kind = '', this.size = 12.5});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final (bg, fg, border) = switch (kind) {
      'warn' => (c.warnSoft, c.warn, Colors.transparent),
      'bad' => (c.badSoft, c.bad, Colors.transparent),
      _ => (c.card, c.ink, c.line),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: size, fontWeight: FontWeight.w600, color: fg, fontFeatures: kTabular),
      ),
    );
  }
}

// ---------------------------------------------------------------- options

ScreenView optionsScreen(BuildContext context, AppState s) {
  final all = s.filtered().all;
  final pool = all.where((x) => s.only == null || x.p.id == s.only).toList();

  return ScreenView([
    const Hd('Lens options', right: BagBtn()),
    ApiLensOptionsBody(s: s, pool: pool),
  ], foot: Expanded(child: ApiLensOptionsFooter(s: s)));
}

class ApiLensOptionsFooter extends ConsumerWidget {
  final AppState s;
  const ApiLensOptionsFooter({super.key, required this.s});

  static LensFilterQuery buildQuery(AppState s) => (
        appLensType: s.lens,
        indicesKey: buildFilterKey(s.optIdx),
        coatingsKey: buildFilterKey(s.optCoat),
      );

  static int _apiTotalCount(catalog_res.CatalogResModel res) {
    final products = res.data?.list ?? const <catalog_res.ListElement>[];
    final total = res.data?.total;
    if (total != null && (total > 0 || products.isEmpty)) return total;
    return products.length;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final baseAsync = ref.watch(lensOptionsProvider(s.lens));
    final hasFilter = s.optIdx.isNotEmpty || s.optCoat.isNotEmpty;
    final query = buildQuery(s);

    // Do not show button before initial lens options API data arrives
    if (baseAsync.isLoading) {
      return const SizedBox.shrink();
    }

    // Whenever a Lens Index or Coating is selected, call the live filtered Catalog API
    final activeAsync = hasFilter ? ref.watch(filteredLensCatalogProvider(query)) : baseAsync;

    void onPressShow() {
      // Trigger live Catalog API call with selected lens type, index & coating on button tap
      ref.invalidate(filteredLensCatalogProvider(query));
      s.toResults();
    }

    return activeAsync.when(
      loading: () => const Row(children: [Btn('Loading...', onTap: null)]),
      error: (_, __) => Row(children: [Btn('Show results', onTap: onPressShow)]),
      data: (res) {
        final count = _apiTotalCount(res);
        final label = 'Show $count lens${count == 1 ? '' : 'es'}';
        return Row(children: [Btn(label, onTap: onPressShow)]);
      },
    );
  }
}

class ApiLensOptionsBody extends ConsumerWidget {
  final AppState s;
  final List<Match> pool;
  const ApiLensOptionsBody({super.key, required this.s, required this.pool});

  static String _formatIndex(num v) => v.toStringAsFixed(2);

  static String _resolveCoatKey(catalog_res.CoatingElement item) => resolveApiCoatingKey(item);

  static Color _parseCoatColor(String? hex, String key) {
    if (hex != null && hex.trim().isNotEmpty) {
      var clean = hex.trim().replaceFirst('#', '').replaceFirst('0x', '').replaceFirst('0X', '');
      if (clean.length == 6) clean = 'FF$clean';
      final parsed = int.tryParse(clean, radix: 16);
      if (parsed != null) return Color(parsed);
    }
    return Color(coatColorHex[key] ?? 0xFFC9CFCC);
  }

  Widget _buildContent(BuildContext context, catalog_res.CatalogResModel? res) {
    final c = context.c;
    final products = res?.data?.list ?? const <catalog_res.ListElement>[];

    // 1. Build Lens Index options (API facets -> API list fallback -> local pool fallback)
    final indexItems = <({String key, String label})>[];
    final seenIdx = <String>{};

    final rawApiIndices = (res?.data?.facets?.indices ?? const <catalog_res.Index>[]).where((e) => e.index != null).toList()
      ..sort((a, b) => a.index!.compareTo(b.index!));

    if (rawApiIndices.isNotEmpty) {
      for (final item in rawApiIndices) {
        final key = _formatIndex(item.index!);
        if (seenIdx.add(key)) {
          final label = (item.label?.trim().isNotEmpty == true) ? item.label!.trim() : (indexNames[key] ?? '');
          indexItems.add((key: key, label: label));
        }
      }
    } else if (products.isNotEmpty) {
      final derived = products.map((p) => p.index).whereType<num>().toSet().toList()..sort();
      for (final v in derived) {
        final key = _formatIndex(v);
        if (seenIdx.add(key)) {
          indexItems.add((key: key, label: indexNames[key] ?? ''));
        }
      }
    } else {
      final localIdxs = pool.map((x) => x.p.index).toSet().toList()..sort();
      for (final i in localIdxs) {
        if (seenIdx.add(i)) {
          indexItems.add((key: i, label: indexNames[i] ?? ''));
        }
      }
    }

    // 2. Build Coating options (API facets -> API list fallback -> local pool fallback)
    final coatItems = <({String key, String name, Color color})>[];
    final seenCoat = <String>{};

    final rawApiCoatings = res?.data?.facets?.coatings ?? const <catalog_res.CoatingElement>[];

    if (rawApiCoatings.isNotEmpty) {
      for (final item in rawApiCoatings) {
        final key = _resolveCoatKey(item);
        if (seenCoat.add(key)) {
          final name = (item.name?.trim().isNotEmpty == true) ? item.name!.trim() : coatName(key);
          final color = _parseCoatColor(item.color, key);
          coatItems.add((key: key, name: name, color: color));
        }
      }
    } else if (products.isNotEmpty) {
      for (final p in products) {
        final raw = (p.coating ?? '').trim();
        if (raw.isEmpty) continue;
        final fake = catalog_res.CoatingElement(name: raw, code: raw);
        final key = _resolveCoatKey(fake);
        if (seenCoat.add(key)) {
          coatItems.add((key: key, name: coatName(key), color: _parseCoatColor(null, key)));
        }
      }
    } else {
      for (final x in pool) {
        final k = coatKey(x.p);
        if (seenCoat.add(k)) {
          coatItems.add((key: k, name: coatName(k), color: Color(coatColorHex[k] ?? 0xFFC9CFCC)));
        }
      }
    }

    final n = indexItems.length.clamp(1, 3);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const HeadRow('Lens index', top: 4),
        if (indexItems.isEmpty)
          const Muted('No lens index available for this lens.', small: false)
        else
          LayoutBuilder(
            builder: (context, cons) {
              final w = (cons.maxWidth - 8 * (n - 1)) / n;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final item in indexItems)
                    GestureDetector(
                      onTap: () => s.toggleIdx(item.key),
                      child: Container(
                        width: w,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                        decoration: BoxDecoration(
                          color: c.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: s.optIdx.contains(item.key) ? c.ink : c.line, width: s.optIdx.contains(item.key) ? 2 : 1),
                        ),
                        child: Column(
                          children: [
                            Text(
                              item.key,
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.ink, fontFeatures: kTabular),
                            ),
                            Text(
                              item.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: c.ink2),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        const HeadRow('Coating'),
        if (coatItems.isEmpty)
          const Muted('No stocked lens for this power.', small: false)
        else
          Gap(gap: 8, [
            for (final item in coatItems)
              RadioCard(
                on: s.optCoat.contains(item.key),
                onTap: () => s.toggleCoat(item.key),
                showDot: false,
                child: Row(
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: s.optCoat.contains(item.key) ? c.ink : c.mute, width: 1.5),
                        color: s.optCoat.contains(item.key) ? c.ink : Colors.transparent,
                      ),
                      alignment: Alignment.center,
                      child: s.optCoat.contains(item.key) ? Text('✓', style: TextStyle(fontSize: 12, height: 1, color: c.card)) : null,
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: item.color),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(item.name, style: TextStyle(color: c.ink)),
                    ),
                  ],
                ),
              ),
          ]),
        const Muted('Leave everything unticked to see every lens for this power.', margin: EdgeInsets.only(top: 12)),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncOptions = ref.watch(lensOptionsProvider(s.lens));

    return asyncOptions.when(
      loading: () => SizedBox(
        height: MediaQuery.of(context).size.height * 0.55,
        child: const Center(
          child: LoaderLens(size: 96),
        ),
      ),
      error: (_, __) => _buildContent(context, null),
      data: (res) => _buildContent(context, res),
    );
  }
}

// ---------------------------------------------------------------- results

Widget matchRow(BuildContext context, AppState s, Match x, {VoidCallback? onTap}) {
  final p = x.p;
  var st = s.logic.pairStock(x);
  if (!x.mto && st.state == 'in') st = s.logic.powStock(x); // 30 Oct: the status of the exact power
  final ok = !const ['na', 'soon', 'zero'].contains(st.state);
  final price = s.logic.pairPrice(p, x.li, x.liL);
  final rangeTxt = x.mto ? 'any axis, 10° steps' : rg(p.lines[x.li].range);
  final subParts = <String>[
    typeName[p.ptype] ?? p.ptype,
    if (p.index.isNotEmpty) '${p.index} index',
    if (rangeTxt.isNotEmpty) rangeTxt,
  ];
  return RowCard(
    dim: !ok,
    onTap: onTap ?? () => s.openMatch(x.mi),
    thumb: ThumbBox(child: ProductArt(p, li: x.li)),
    title: shortName(p),
    sub: subParts.join(' · '),
    extra: [
      PriceLineText(price: price != null && s.showPrice ? money(price) : '', suffix: price != null && s.showPrice ? ' / pair' : '', tag: StockTag(st)),
      if (x.diff) const FlagTag('Different power: check before ordering'),
    ],
    chevron: true,
  );
}

ScreenView resultsScreen(BuildContext context, AppState s) {
  final lt = s.lens;
  final sub =
      '${s.rxL != null ? 'R ${powerTxt(s.rx, lt)} · L ${powerTxt(s.rxL!, lt)}' : 'R and L ${powerTxt(s.rx, lt)}'} · ${qWord(qKind(lt, s.peye), s.aq, unit: s.unit)}';
  final tl = typeName[lt]!;
  return ScreenView([
    Hd(tl, right: const BagBtn()),
    Transform.translate(
      offset: const Offset(0, -6),
      child: Muted(sub, align: TextAlign.center),
    ),
    ApiResultsBody(s: s),
  ]);
}

class ApiResultsBody extends ConsumerWidget {
  final AppState s;
  const ApiResultsBody({super.key, required this.s});

  Widget _buildEmptyAll(BuildContext context, String lt, String tl) {
    final c = context.c;
    if (lt == LensType.prog) {
      return CardBox(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            eyebrow(context, 'RX request'),
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 10),
              child: Text(
                'No stocked or made-to-order progressive has this power.',
                style: TextStyle(fontWeight: FontWeight.w600, color: c.ink),
              ),
            ),
            const Muted(
              'Send this power as an RX request. Our staff will check it with the lab and call you with the price and date.',
              margin: EdgeInsets.only(bottom: 14),
            ),
            Row(children: [Btn('Add RX request to cart', onTap: s.addRxRequest)]),
          ],
        ),
      );
    }
    return CardBox(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          eyebrow(context, 'Not stocked'),
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 10),
            child: Text(
              'No ${tl.toLowerCase()} lens is stocked in this power.',
              style: TextStyle(fontWeight: FontWeight.w600, color: c.ink),
            ),
          ),
          Muted('$tl lenses are not made to order. Try the nearest power, or call the order desk.', margin: const EdgeInsets.only(bottom: 14)),
          Row(children: [Btn('Change the power', ghost: true, onTap: s.back)]),
        ],
      ),
    );
  }

  Widget _buildLocalFallback(BuildContext context) {
    final c = context.c;
    final f = s.filtered();
    final all = f.all, list = f.list;
    final lt = s.lens;
    final tl = typeName[lt]!;
    final ex = list.where((x) => !x.diff && !x.mto).toList();
    final near = list.where((x) => x.diff).toList();
    final mto = list.where((x) => x.mto).toList();
    final nf = s.optIdx.length + s.optCoat.length + (s.only != null ? 1 : 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 6),
          child: Row(
            children: [
              Expanded(child: Text('${list.length} of ${all.length} lens${all.length == 1 ? '' : 'es'}', style: AppText.small(c))),
              if (nf > 0) ...[LinkBtn('Clear filters', onTap: s.clearFilters), Text(' · ', style: AppText.small(c))],
              LinkBtn('Filter${nf > 0 ? ' ($nf)' : ''}', onTap: s.toOptions),
            ],
          ),
        ),
        if (all.isNotEmpty) ...[
          Gap([for (final x in ex) matchRow(context, s, x)]),
          if (near.isNotEmpty) ...[
            const Sec('Nearest stocked power'),
            Gap([for (final x in near) matchRow(context, s, x)]),
          ],
          if (mto.isNotEmpty) ...[
            const Sec('Made to order'),
            Gap([for (final x in mto) matchRow(context, s, x)]),
          ],
          if (list.isEmpty) const EmptyState('Nothing with these options', 'Clear the filters to see every lens.'),
        ] else
          _buildEmptyAll(context, lt, tl),
      ],
    );
  }

  Widget _buildApiList(BuildContext context, catalog_res.CatalogResModel res, {int? baseTotal}) {
    final c = context.c;
    final lt = s.lens;
    final tl = typeName[lt]!;
    final filteredApi = res.data?.list ?? const <catalog_res.ListElement>[];
    final totalAll = baseTotal ?? ((res.data?.total != null && (res.data!.total! > 0 || filteredApi.isEmpty)) ? res.data!.total! : filteredApi.length);
    final apiMatches = [for (final el in filteredApi) s.apiMatchFor(el)];
    final ex = apiMatches.where((x) => !x.mto).toList();
    final mto = apiMatches.where((x) => x.mto).toList();
    final nf = s.optIdx.length + s.optCoat.length + (s.only != null ? 1 : 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 6),
          child: Row(
            children: [
              Expanded(child: Text('${apiMatches.length} of $totalAll lens${totalAll == 1 ? '' : 'es'}', style: AppText.small(c))),
              if (nf > 0) ...[LinkBtn('Clear filters', onTap: s.clearFilters), Text(' · ', style: AppText.small(c))],
              LinkBtn('Filter${nf > 0 ? ' ($nf)' : ''}', onTap: s.toOptions),
            ],
          ),
        ),
        if (apiMatches.isNotEmpty) ...[
          if (ex.isNotEmpty) Gap([for (final x in ex) matchRow(context, s, x, onTap: () => s.openApiMatch(x))]),
          if (mto.isNotEmpty) ...[
            const Sec('Made to order'),
            Gap([for (final x in mto) matchRow(context, s, x, onTap: () => s.openApiMatch(x))]),
          ],
        ] else if (nf > 0)
          const EmptyState('Nothing with these options', 'Clear the filters to see every lens.')
        else
          _buildEmptyAll(context, lt, tl),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ApiLensOptionsFooter.buildQuery(s);
    final asyncFiltered = ref.watch(filteredLensCatalogProvider(query));
    final baseTotal = ref.watch(lensOptionsProvider(s.lens)).valueOrNull?.data?.total;

    return asyncFiltered.when(
      loading: () => SizedBox(
        height: MediaQuery.of(context).size.height * 0.55,
        child: const Center(
          child: LoaderLens(size: 96),
        ),
      ),
      error: (_, __) => _buildLocalFallback(context),
      data: (res) => _buildApiList(context, res, baseTotal: baseTotal),
    );
  }
}

// ---------------------------------------------------------------- product

Widget buildProductBodyWidget(BuildContext context, AppState s, Product p, Match? m, ProdView pv) {
  final c = context.c;
  final wished = s.wish.contains(p.id);
  final feats = featIcons(p);
  final env = envOf(p, m?.li);
  final apiImg = p.imageUrl?.trim().isNotEmpty == true ? p.imageUrl!.trim() : null;
  final hasPhoto = apiImg != null || (env != null && s.data.envelopes.contains(env));

  final head = SizedBox(
    height: hasPhoto ? 270 : 250,
    child: Stack(
      children: [
        Positioned.fill(
          child: ColoredBox(
            color: c.sunk,
            child: Center(
              child: hasPhoto
                  ? ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: 220, maxWidth: MediaQuery.sizeOf(context).width * .78),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [BoxShadow(color: c.shade, blurRadius: 24, offset: const Offset(0, 10))],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: apiImg != null
                            ? Image.network(
                                apiImg,
                                fit: BoxFit.contain,
                                semanticLabel: '${shortName(p)} packaging',
                                errorBuilder: (_, __, ___) => SizedBox(width: 150, child: LensArt(tint: coatTint(p))),
                              )
                            : Image.asset('assets/images/envelopes/$env.jpg', fit: BoxFit.contain, semanticLabel: '${shortName(p)} packaging'),
                      ),
                    )
                  : SizedBox(width: 150, child: LensArt(tint: coatTint(p))),
            ),
          ),
        ),
        Positioned(
          top: 6,
          left: 14,
          child: IconBtn(Ic.back, label: 'Back', onTap: s.back),
        ),
        const Positioned(top: 6, right: 14, child: BagBtn()),
      ],
    ),
  );

  int? price;
  final body = <Widget>[];
  if (m != null) {
    final l = p.lines.isNotEmpty ? p.lines[m.li.clamp(0, p.lines.length - 1)] : PriceLine(range: '', add: '', axis: '', status: 'ok', read: '', boxes: []);
    final lL = p.lines.isNotEmpty ? p.lines[m.liL.clamp(0, p.lines.length - 1)] : l;
    var st = s.logic.pairStock(m);
    price = s.logic.pairPrice(p, m.li, m.liL);
    final ps = s.logic.powStock(m);
    if (ps.state == 'zero' || ps.state == 'na' || (ps.low && st.state == 'in')) st = ps;
    final naP = ps.state == 'na' && !m.mto;
    final soP = st.state == 'zero' && !m.mto;
    final ok = !const ['na', 'soon', 'zero'].contains(st.state) || soP;
    final k = qKind(p.ptype, s.peye);
    final yourPower = m.uL != null
        ? 'R ${powerTxt(m.uR, p.ptype)}\nL ${powerTxt(m.uL!, p.ptype)}'
        : (p.ptype == LensType.prog && s.peye == 'R'
                ? 'R '
                : p.ptype == LensType.prog && s.peye == 'L'
                    ? 'L '
                    : '') +
            powerTxt(m.uR, p.ptype);
    body.addAll([
      Facts([
        ('Your power', Text(yourPower, textAlign: TextAlign.right)),
        (
          'Range',
          Text(
            m.mto
                ? 'Made to order'
                : m.liL != m.li
                    ? 'R ${rg(l.range)} · L ${rg(lL.range)}'
                    : rg(l.range),
            textAlign: TextAlign.right,
          ),
        ),
        if (l.dia != null) ('Diameter', Text('${l.dia} mm')),
        ('Index · material', Text('${p.index}${p.material != null ? ' · ${p.material}' : ''}', textAlign: TextAlign.right)),
        ('Availability', StockTag(st, left: 0)),
      ]),
      if (m.diff)
        NoteBox(
          kind: 'warn',
          child: Text.rich(
            TextSpan(
              children: [
                const TextSpan(
                  text: 'Different power: check before ordering.',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(
                  text:
                      ' This lens is ${s.diffText(m, p.ptype)}; the slip asks for ${s.rxL != null ? 'R ${powerTxt(s.rx, p.ptype)} · L ${powerTxt(s.rxL!, p.ptype)}' : powerTxt(s.rx, p.ptype)}.',
                ),
              ],
            ),
          ),
        ),
      if (m.mto) NoteBox.text('Made at the lab. The axis is made in 10° steps; staff confirm the delivery date.'),
      if (soP)
        NoteBox(
          kind: 'warn',
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Sold out in this power${st.eta != null ? ' · back in ${st.eta}' : ''}. ',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const TextSpan(text: 'Pre-order it: it is held for you and sent as soon as stock arrives.'),
              ],
            ),
          ),
        ),
      if (pv.scan)
        NoteBox(
          child: Row(
            children: [
              SvgIcon(Ic.qr, size: 20, color: c.ink),
              const SizedBox(width: 10),
              const Expanded(child: Text('Scanned from a QR code: lens, range and power are filled in. Type the quantity and add it.')),
            ],
          ),
        ),
      if (ok)
        InfoBox(
          child: QtyCtl(kind: k, n: pv.n, onStep: s.prodQty, unit: s.unit, onUnit: s.setUnit, onTyped: s.setProdN),
        )
      else if (naP)
        NaBox(m, fromProduct: true)
      else
        NoteBox.text('${st.label}: this power cannot be ordered right now.', kind: 'bad'),
    ]);
  } else {
    price = s.logic.fromPrice(p);
    // 5 Nov: Order by power across all the lens's ranges
    final byPow = !p.rx && List.generate(p.lines.length, (i) => i).any((i) => !const ['na', 'soon'].contains(s.stock.stockOf(p, i).state));
    body.addAll([
      if (byPow) _ByPowerButton(p),
      const Sec('Stocked ranges'),
      Muted(
        '${byPow ? 'Or tap' : 'Tap'} a range to set its powers on the wheels or the power chart. The heart saves that range to Favorites.',
        margin: const EdgeInsets.only(bottom: 8),
      ),
      Gap([for (var i = 0; i < p.lines.length; i++) RangeRow(p, i)]),
    ]);
  }

  final sheet = Container(
    decoration: BoxDecoration(
      color: c.raised,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      boxShadow: c.e2,
    ),
    padding: const EdgeInsets.fromLTRB(18, 22, 18, 6),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        eyebrow(context, '${titlecase(p.brand)} · ${typeName[p.ptype]}'),
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 6),
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: '${bname(p.brand)} ${coatShort(p)} ${p.index}'),
                if (p.variant.isNotEmpty)
                  TextSpan(
                    text: '\n${p.variant}',
                    style: TextStyle(fontFamily: kSans, fontSize: 14, fontWeight: FontWeight.w500, color: c.mute, height: 1.8),
                  ),
              ],
            ),
            style: TextStyle(fontFamily: kSerif, fontWeight: FontWeight.w600, fontSize: 28, height: 1.05, color: c.ink),
          ),
        ),
        if (s.showPrice && price != null)
          Text.rich(
            TextSpan(
              children: [
                if (m == null)
                  TextSpan(
                    text: 'from ',
                    style: TextStyle(fontSize: 12, color: c.ink2, fontWeight: FontWeight.w400),
                  ),
                TextSpan(text: money(price)),
                TextSpan(
                  text: ' per pair · your price',
                  style: TextStyle(fontSize: 12, color: c.ink2, fontWeight: FontWeight.w400),
                ),
              ],
            ),
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: c.ink, fontFeatures: kTabular),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: FavBtn(on: wished, onTap: () => s.toggleWish(p.id)),
        ),
        Muted(p.base.trim().isNotEmpty ? '${p.name}. ${titlecase(p.base)}.' : p.name, margin: const EdgeInsets.only(top: 8)),
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final f in feats)
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: c.line),
                        ),
                        alignment: Alignment.center,
                        child: SvgIcon(Ic.feat[f.$1]!, size: 19, color: c.ink),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        f.$2,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11.5, height: 1.25, color: c.ink2),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        ...body,
      ],
    ),
  );

  return Stack(
    children: [
      head,
      Padding(
        padding: EdgeInsets.only(top: (hasPhoto ? 270 : 250) - 18),
        child: sheet,
      ),
    ],
  );
}

Widget? buildProductFootWidget(BuildContext context, AppState s, Product p, Match? m, ProdView pv, {bool expand = true}) {
  if (m == null) return null;
  var st = s.logic.pairStock(m);
  final price = s.logic.pairPrice(p, m.li, m.liL);
  final ps = s.logic.powStock(m);
  if (ps.state == 'zero' || ps.state == 'na' || (ps.low && st.state == 'in')) st = ps;
  final naP = ps.state == 'na' && !m.mto;
  final soP = st.state == 'zero' && !m.mto;
  final ok = !const ['na', 'soon', 'zero'].contains(st.state) || soP;
  final k = qKind(p.ptype, s.peye);

  return soP
      ? Btn('Pre-order', onTap: s.addPreFromProduct, expand: expand, minWidth: expand ? null : double.infinity)
      : ok
          ? Btn(
              'Add to cart${s.showPrice && price != null ? ' · ${money(price * pairsOf(k, pv.n))}' : ''}',
              onTap: s.addToCart,
              expand: expand,
              minWidth: expand ? null : double.infinity,
            )
          : naP
              ? null
              : Btn('Choose another lens', ghost: true, onTap: s.back, expand: expand, minWidth: expand ? null : double.infinity);
}

Widget _buildProductDetailsLoading(BuildContext context, AppState s) {
  return SizedBox(
    height: MediaQuery.of(context).size.height * 0.75,
    child: Stack(
      children: [
        Positioned(
          top: 6,
          left: 14,
          child: IconBtn(Ic.back, label: 'Back', onTap: s.back),
        ),
        const Positioned(top: 6, right: 14, child: BagBtn()),
        const Center(child: LoaderLens(size: 96)),
      ],
    ),
  );
}

class ApiProductView extends ConsumerWidget {
  final AppState s;
  final Product initialProduct;
  const ApiProductView({super.key, required this.s, required this.initialProduct});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apiId = initialProduct.apiId!;
    final asyncDetails = ref.watch(productDetailsProvider(apiId));

    return asyncDetails.when(
      loading: () => _buildProductDetailsLoading(context, s),
      error: (_, __) {
        final pv = s.prod!;
        final m = pv.mi != null && pv.mi! < s.matches.length ? s.matches[pv.mi!] : null;
        return buildProductBodyWidget(context, s, initialProduct, m, pv);
      },
      data: (res) {
        final d = res.data;
        Product p = initialProduct;
        if (d != null) {
          p = s.updateProductFromDetails(d, existing: initialProduct);
        }
        final pv = s.prod!;
        final m = pv.mi != null && pv.mi! < s.matches.length ? s.matches[pv.mi!] : null;
        return buildProductBodyWidget(context, s, p, m, pv);
      },
    );
  }
}

class ApiProductFooter extends ConsumerWidget {
  final AppState s;
  final Product initialProduct;
  const ApiProductFooter({super.key, required this.s, required this.initialProduct});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apiId = initialProduct.apiId!;
    final asyncDetails = ref.watch(productDetailsProvider(apiId));

    return asyncDetails.when(
      loading: () => const Btn('Loading...', onTap: null, expand: false, minWidth: double.infinity),
      error: (_, __) {
        final pv = s.prod!;
        final m = pv.mi != null && pv.mi! < s.matches.length ? s.matches[pv.mi!] : null;
        return buildProductFootWidget(context, s, initialProduct, m, pv, expand: false) ?? const SizedBox.shrink();
      },
      data: (res) {
        final d = res.data;
        Product p = initialProduct;
        if (d != null) {
          p = s.updateProductFromDetails(d, existing: initialProduct);
        }
        final pv = s.prod!;
        final m = pv.mi != null && pv.mi! < s.matches.length ? s.matches[pv.mi!] : null;
        return buildProductFootWidget(context, s, p, m, pv, expand: false) ?? const SizedBox.shrink();
      },
    );
  }
}

ScreenView productScreen(BuildContext context, AppState s) {
  final pv = s.prod;
  if (pv == null) return const ScreenView([Text('No product selected')]);
  final m = pv.mi != null && pv.mi! < s.matches.length ? s.matches[pv.mi!] : null;
  final p = m?.p ?? s.product(pv.pid ?? s.data.meta.favs[0]);

  if (p.apiId != null && p.apiId!.trim().isNotEmpty) {
    return ScreenView(
      [
        Bleed(child: ApiProductView(s: s, initialProduct: p)),
      ],
      foot: Expanded(child: ApiProductFooter(s: s, initialProduct: p)),
    );
  }

  return ScreenView([
    Bleed(child: buildProductBodyWidget(context, s, p, m, pv)),
  ], foot: buildProductFootWidget(context, s, p, m, pv));
}

/// `.facts`: label on the left, value on the right, with a rule above.
class Facts extends StatelessWidget {
  final List<(String, Widget)> rows;
  const Facts(this.rows, {super.key});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.only(top: 14),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: c.ink, fontFeatures: kTabular),
        child: Column(
          children: [
            for (final r in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.$1,
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w400, color: c.ink2),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Align(alignment: Alignment.centerRight, child: r.$2),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// `.bypow`: Order by power on the product page (5 Nov): the wheels for this lens across all its ranges.
class _ByPowerButton extends StatelessWidget {
  final Product p;
  const _ByPowerButton(this.p);
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 4),
      child: Material(
        color: c.navy,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => s.productParcel(p.id),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: .12)),
                  alignment: Alignment.center,
                  child: SvgIcon(Ic.rx, size: 20, color: c.onNavy),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order by power',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.onNavy),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'SPH, CYL${p.ptype != LensType.sv ? ', axis, ADD' : ''} and quantity on the wheels. The app picks the range: all ${p.lines.length} ranges of this lens.',
                        style: TextStyle(fontSize: 12, height: 1.35, color: c.onNavy.withValues(alpha: .8)),
                      ),
                    ],
                  ),
                ),
                SvgIcon(Ic.chev, size: 16, color: c.onNavy),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
