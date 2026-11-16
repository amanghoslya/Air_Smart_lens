import 'package:flutter/material.dart';

import '../../core/brands.dart';
import '../../core/format.dart';
import '../../core/models.dart';
import '../../state/app_state.dart';
import '../art.dart';
import '../parts.dart';
import '../shell.dart';
import '../theme.dart';
import '../widgets.dart';
import 'start_screens.dart' show PhotoCard;

// ---------------------------------------------------------------- Shop by range (3 Nov)
// Shop › Shop by range: the lens type, then every range code of that type (grouped: minus, plus, compound …), then
// every lens made in the chosen range, by brand. Tapping a lens opens the same Parcel / Bulk sheet as a brand page.

const _rangeTypes = [(LensType.sv, 'max1_face', 'Single vision'), (LensType.kt, 'vishal1_face', 'KT'), (LensType.prog, 'kopperx1_face', 'Progressive')];

ScreenView rangeTypeScreen(BuildContext context, AppState s) => ScreenView([
  const Hd('Shop by range', right: BagBtn()),
  const Muted('Choose the lens type, then the range', align: TextAlign.center, margin: EdgeInsets.only(bottom: 12)),
  Gap([
    for (final x in _rangeTypes)
      PhotoCard(
        title: x.$3,
        sub: '${s.logic.rangeIndex(x.$1).length} ranges',
        count: '${s.catalog.where((p) => p.ptype == x.$1).length} products',
        image: x.$2,
        onTap: () => s.pickRangeType(x.$1),
      ),
  ]),
]);

ScreenView rangeListScreen(BuildContext context, AppState s) {
  final c = context.c;
  final t = s.rgType;
  final r = s.logic.rangeIndex(t);
  final groups = <String>[];
  for (final g in r) {
    if (!groups.contains(g.group)) groups.add(g.group);
  }
  return ScreenView([
    Hd('${LensType.names[t]} ranges', right: const BagBtn()),
    Strip(
      bleed: false,
      children: [for (final x in _rangeTypes) ChipBtn(x.$3, on: t == x.$1, onTap: () => s.pickRangeType(x.$1, stay: true))],
    ),
    Muted('${r.length} ranges. Tap one to see every lens made in it.', margin: const EdgeInsets.only(top: 6, bottom: 4)),
    for (final g in groups) ...[
      Sec('$g · ${r.where((x) => x.group == g).length}'),
      Gap([
        for (var i = 0; i < r.length; i++)
          if (r[i].group == g)
            RowCard(
              titleWidget: Text(
                rg(r[i].code),
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.ink, fontFeatures: kTabular),
              ),
              sub: r[i].read,
              extra: [
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: '${r[i].items.length} lens${r[i].items.length == 1 ? '' : 'es'}'),
                        if (s.showPrice && r[i].from != null) ...[
                          TextSpan(text: ' · from ${money(r[i].from!)}'),
                          TextSpan(
                            text: ' / pair',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: c.ink2),
                          ),
                        ],
                      ],
                    ),
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.ink, fontFeatures: kTabular),
                  ),
                ),
              ],
              chevron: true,
              onTap: () => s.pickRangeCode(i),
            ),
      ]),
    ],
  ]);
}

ScreenView rangeProdsScreen(BuildContext context, AppState s) {
  final c = context.c;
  final t = s.rgType;
  final all = s.logic.rangeIndex(t);
  if (all.isEmpty) return rangeListScreen(context, s);
  final r = all[s.rgI.clamp(0, all.length - 1)];
  final byB = [
    for (final b in s.brands)
      if (r.items.any((x) => x.p.brand == b)) (b, r.items.where((x) => x.p.brand == b).toList()),
  ];
  return ScreenView([
    Hd(rg(r.code), right: const BagBtn()),
    Muted(
      '${LensType.names[t]} · ${r.items.length} lens${r.items.length == 1 ? '' : 'es'} made in this range',
      align: TextAlign.center,
      margin: const EdgeInsets.only(bottom: 4),
    ),
    Muted(r.read, align: TextAlign.center, margin: const EdgeInsets.only(bottom: 6)),
    for (final (b, arr) in byB) ...[
      Sec('${bname(b)} · ${arr.length}'),
      Gap([
        for (final x in arr)
          Builder(
            builder: (context) {
              final l = x.p.lines[x.li];
              final st = s.stock.stockOf(x.p, x.li);
              final sub = [if (l.dia != null) '${l.dia} mm', if (l.read != r.read) l.read].join(' · ');
              return RowCard(
                thumb: ThumbBox(child: ProductArt(x.p, li: x.li)),
                title: shortName(x.p),
                sub: sub.isEmpty ? null : sub,
                extra: [
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (l.price != null && l.price != 0 && s.showPrice) ...[
                          Text(
                            money(s.logic.tier(l.price!)),
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.ink, fontFeatures: kTabular),
                          ),
                          Text(' / pair', style: TextStyle(fontSize: 12, color: c.ink2)),
                        ],
                        StockTag(st),
                      ],
                    ),
                  ),
                ],
                chevron: true,
                onTap: () => showRangeSheet(context, x.p, x.li),
              );
            },
          ),
      ]),
    ],
    const Muted(
      'Tap a lens to order in this range as a parcel (power wheels or the power chart) or in bulk (the power grid).',
      margin: EdgeInsets.only(top: 12),
    ),
  ]);
}
