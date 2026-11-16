import 'package:flutter/material.dart';

import '../../core/brands.dart';
import '../../core/format.dart';
import '../../core/models.dart';
import '../../core/quantity.dart';
import '../../core/search.dart';
import '../../state/app_state.dart';
import '../art.dart';
import '../icons.dart';
import '../parts.dart';
import '../power_grid.dart';
import '../shell.dart';
import '../theme.dart';
import '../widgets.dart';
import 'parcel_screens.dart' show typeName, CodeBadge;
import 'start_screens.dart' show PhotoCard;

// ---------------------------------------------------------------- lens type

ScreenView stockTypeScreen(BuildContext context, AppState s) {
  final c = context.c;
  const cards = [
    (LensType.sv, 'max1_face', 'Single vision', 'Grid: sphere × cylinder'),
    (LensType.kt, 'vishal1_face', 'KT', 'Grid: power × ADD'),
    (LensType.prog, 'kopperx1_face', 'Progressive', 'Grid: power × ADD'),
  ];
  return ScreenView([
    Hd('Bulk ordering', right: SearchBtn(onTap: s.stockSearch)),
    const Sec('My products · straight to the ranges', margin: EdgeInsets.only(top: 4, bottom: 8)),
    Strip(
      gap: 10,
      padding: const EdgeInsets.only(bottom: 4),
      children: [
        for (final pid in s.data.meta.favs)
          () {
            final p = s.product(pid);
            return Pressable(
              onTap: () => s.pickProduct(p.id),
              child: Container(
                width: 104,
                height: 156,
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
                decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(14), boxShadow: c.e1),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ThumbBox(w: 88, h: 72, child: ProductArt(p)),
                    const SizedBox(height: 6),
                    Text(
                      shortName(p),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, height: 1.2, color: c.ink),
                    ),
                    const SizedBox(height: 2),
                    Text(typeName[p.ptype]!, style: TextStyle(fontSize: 10.5, color: c.ink2)),
                  ],
                ),
              ),
            );
          }(),
      ],
    ),
    const Sec('Or choose the lens type'),
    Gap([
      for (final x in cards)
        PhotoCard(title: x.$3, sub: x.$4, count: '${s.catalog.where((p) => p.ptype == x.$1).length} products', image: x.$2, onTap: () => s.pickStockType(x.$1)),
    ]),
  ]);
}

// ---------------------------------------------------------------- product

ScreenView stockPickScreen(BuildContext context, AppState s) {
  final t = s.stype;
  final q = s.q.trim();
  var ps = s.catalog.where((p) => t == null || p.ptype == t).toList();
  if (q.isNotEmpty) ps = ps.where((p) => lensMatch(p, q)).toList();
  Widget prow(Product p) {
    final fp = s.fromPrice(p);
    return RowCard(
      thumb: ThumbBox(child: ProductArt(p)),
      title: shortName(p),
      sub: '${typeName[p.ptype]} · ${p.lines.length} range${p.lines.length == 1 ? '' : 's'}${s.showPrice && fp != null ? ' · from ${money(fp)}' : ''}',
      chevron: true,
      onTap: () => s.pickProduct(p.id),
    );
  }

  final groups = [for (final b in s.brands) (b, ps.where((p) => p.brand == b).toList())].where((g) => g.$2.isNotEmpty).toList();
  return ScreenView([
    Hd(t != null ? typeName[t]! : 'All products', right: const BagBtn()),
    Transform.translate(
      offset: const Offset(0, -6),
      child: const Muted('Bulk order · choose the product', align: TextAlign.center, margin: EdgeInsets.only(bottom: 4)),
    ),
    SearchBox(initial: s.q, hint: 'Search: opal, photo, 1.67', onChanged: s.setQuery),
    if (t != null)
      Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Strip(
          bleed: false,
          children: [
            for (final x in const [(LensType.sv, 'Single vision'), (LensType.kt, 'KT'), (LensType.prog, 'Progressive')])
              ChipBtn(x.$2, on: t == x.$1, onTap: () => s.switchStockType(x.$1)),
          ],
        ),
      ),
    if (ps.isNotEmpty)
      for (final g in groups) ...[
        Sec('${bname(g.$1)} · ${g.$2.length}'),
        Gap([for (final p in g.$2) prow(p)]),
      ]
    else
      const EmptyState('No products', 'Try another word or lens type.'),
  ]);
}

// ---------------------------------------------------------------- range

ScreenView stockRangeScreen(BuildContext context, AppState s) {
  final c = context.c;
  final pid = s.bulk.pid ?? s.data.meta.repeat;
  final p = s.product(pid);
  return ScreenView([
    const Hd('Choose a range', right: BagBtn()),
    Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RowCard(
        thumb: ThumbBox(child: ProductArt(p)),
        title: shortName(p),
        sub: p.name,
      ),
    ),
    const Sec('Stocked ranges'),
    Gap([
      for (var i = 0; i < p.lines.length; i++)
        () {
          final l = p.lines[i];
          final st = s.stock.stockOf(p, i);
          final dim = const ['na', 'soon', 'mto'].contains(st.state);
          return RowCard(
            dim: dim,
            onTap: dim ? null : () => s.pickRange(i),
            titleWidget: Text(
              rg(l.range),
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: c.ink, fontFeatures: kTabular),
            ),
            sub: '${l.read}${l.dia != null ? ' · ${l.dia} mm' : ''}',
            extra: [
              PriceLineText(
                price: l.price != null && s.showPrice ? money(s.logic.tier(l.price!)) : '',
                suffix: l.price != null && s.showPrice ? ' / pair' : '',
                tag: StockTag(st),
              ),
            ],
            chevron: true,
          );
        }(),
    ]),
  ]);
}

// ---------------------------------------------------------------- power grid

ScreenView gridScreen(BuildContext context, AppState s) {
  final c = context.c;
  final p = s.product(s.bulk.pid!);
  final li = s.bulk.li;
  final l = p.lines[li];
  final gr = s.logic.lineGrid(p, li);
  final g = s.bulk.grid;
  final tot = g.values.fold<double>(0, (a, b) => a + b);
  final e = s.gEye;
  final mul = e == 'H' ? uMul('H', s.unit) : 1;
  final gUnit = e == 'H'
      ? (s.unit == 'pcs' ? 'pieces' : 'pairs')
      : e == 'P'
      ? 'pairs'
      : 'pieces · ${e == 'R' ? 'right' : 'left'} eye';
  String gWord(double q) => e == 'H'
      ? qWord('H', q, unit: s.unit)
      : e == 'P'
      ? qWord('P', q)
      : '${nfmt(q)} piece${q == 1 ? '' : 's'} · ${e == 'R' ? 'right' : 'left'} eye';
  final order = [
    for (final r in gr.rows)
      for (final col in gr.cols)
        if ((g[gridKey(r, col)] ?? 0) > 0) gridKey(r, col),
  ];
  final sel = s.bulk.sel;
  final wished = s.wishR.contains('${p.id}:$li');
  return ScreenView(
    [
      Hd(shortName(p), right: const BagBtn()),
      // 5 Nov: each range tab keeps its quantities and shows their total
      Bleed(
        child: RangeTabs(
          p: p,
          li: li,
          onTap: s.rangeTab,
          badge: (i) {
            final q = i == li ? tot : AppState.bulkTot(s.bulk.grids[i]);
            return q > 0 ? nfmt(q * mul) : null;
          },
          soon: true,
        ),
      ),
      if (p.ptype == LensType.prog) ...[
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Seg(items: const [('P', 'BE · both eyes'), ('R', 'Right eye'), ('L', 'Left eye')], value: s.bulk.eye, onTap: s.setBulkEye),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Text('QUANTITIES IN', style: AppText.eyebrow(c).copyWith(fontSize: 11)),
              const SizedBox(width: 14),
              Text(
                e == 'P' ? 'Pairs' : 'Pieces · ${e == 'R' ? 'right eye' : 'left eye'}',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.ink),
              ),
            ],
          ),
        ),
      ] else
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: UnitSwitch(unit: s.unit, onUnit: s.setUnit, label: 'Quantities in'),
        ),
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: 'Range '),
                    TextSpan(
                      text: rg(l.range),
                      style: TextStyle(fontWeight: FontWeight.w700, color: c.ink, fontFeatures: kTabular),
                    ),
                  ],
                ),
                style: AppText.small(c),
              ),
            ),
            FavBtn(on: wished, onText: 'Range saved', offText: 'Save range', margin: EdgeInsets.zero, onTap: () => s.toggleWishRange(p.id, li)),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: DefaultTextStyle.merge(
          style: TextStyle(fontSize: 12, color: c.ink2, height: 1.45),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.read),
              if (gr.sm != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [CodeBadge(gr.sm!, size: 11), Text(" Standard grid ${gr.smt}: greyed cells are outside this product's range.")],
                  ),
                ),
            ],
          ),
        ),
      ),
      PowerGridView(
        key: ValueKey('grid-${p.id}-$li-$e-${s.unit}'),
        s: s,
        p: p,
        li: li,
        gr: gr,
        values: g,
        mul: mul,
        onSelect: s.gridSelect,
        onType: s.gridType,
      ),
      const GridLegend(),
      SelectedBox(
        p: p,
        li: li,
        k: sel,
        title: 'Selected box',
        qtyWord: sel != null && (g[sel] ?? 0) > 0 ? gWord(g[sel]!) : '',
        st: sel != null ? s.stock.cellStock(p, li, sel) : null,
        power: sel != null ? s.logic.cellPower(p, sel) : null,
        empty: 'Its power shows here',
      ),
      Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Row(children: [Btn('Clear', ghost: true, onTap: tot > 0 ? s.gridClear : null)]),
      ),
      if (order.isNotEmpty) ...[
        Sec('In this grid · ${order.length} power${order.length == 1 ? '' : 's'}'),
        Gap([
          for (final k in order)
            RowCard(
              titleWidget: Text(
                powerTxt(s.logic.cellPower(p, k), p.ptype),
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: c.ink, fontFeatures: kTabular),
              ),
              extra: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: gWord(g[k]!)),
                      if (s.stock.cellStock(p, li, k).state == 'zero')
                        TextSpan(
                          text: ' · pre-order',
                          style: TextStyle(fontWeight: FontWeight.w700, color: c.warn),
                        ),
                    ],
                  ),
                  style: AppText.small(c),
                ),
              ],
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PowBtn(s.cellCode(k)),
                  IconBtn(Ic.trash, size: 18, label: 'Remove', onTap: () => s.gridRemove(k)),
                ],
              ),
            ),
        ]),
      ],
      const Muted(
        "Tap a box and type the quantity with the phone's number keyboard; Next on the keyboard moves to the next box. Hatched: not in this range.",
        margin: EdgeInsets.only(top: 10),
      ),
    ],
    foot: () {
      // 5 Nov: the footer counts every range with quantities
      final all = s.bulkAll;
      final allTot = all.fold<double>(0, (a, x) => a + AppState.bulkTot(x.$2));
      final val = all.fold<double>(0, (a, x) {
        final q = AppState.bulkTot(x.$2);
        return a + (e == 'R' || e == 'L' ? q / 2 : q) * s.logic.tier(p.lines[x.$1].price ?? 0);
      });
      final nr = all.length;
      return Expanded(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: nfmt(allTot * mul),
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: c.ink, fontFeatures: kTabular),
                        ),
                        TextSpan(
                          text: ' $gUnit${nr > 1 ? ' · $nr ranges' : ''}',
                          style: TextStyle(fontSize: 12, color: c.ink2),
                        ),
                      ],
                    ),
                  ),
                  if (s.showPrice)
                    Text(
                      money(val),
                      style: TextStyle(fontSize: 12, color: c.ink2, fontFeatures: kTabular),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Btn(nr > 1 ? 'Add $nr ranges to cart' : 'Add to cart', expand: false, minWidth: 170, onTap: allTot > 0 ? s.addGrid : null),
          ],
        ),
      );
    }(),
  );
}
