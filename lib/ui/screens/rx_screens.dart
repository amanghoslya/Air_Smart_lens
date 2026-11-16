import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/models.dart';
import '../../state/app_state.dart';
import '../art.dart';
import '../icons.dart';
import '../shell.dart';
import '../theme.dart';
import '../widgets.dart';
import 'parcel_screens.dart' show typeName;

/// RX orders are progressive only: the RX progressive made at the lab to the
/// customer's power. Below, the shop's RX orders and their lab stage.
ScreenView rxHomeScreen(BuildContext context, AppState s) {
  final c = context.c;
  final rxp = s.catalog.where((p) => p.rx).firstOrNull;
  final pr = rxp != null ? s.fromPrice(rxp) : null;
  final stages = s.content.rxStages;
  return ScreenView([
    Hd(s.tr('RX order'), right: const BagBtn()),
    Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: c.card2, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RX progressive, made at the lab.',
            style: TextStyle(fontFamily: kSerif, fontSize: 21, fontWeight: FontWeight.w600, height: 1.15, color: c.ink),
          ),
          const SizedBox(height: 6),
          Text(
            "For progressive powers we don't stock. Made to your power: sphere 0 to ±2.00, cylinder up to 2.00 at any axis (made in 10° steps), ADD +1.00 to +3.00. RX lenses take a few working days.",
            style: TextStyle(fontSize: 12.5, color: c.ink2),
          ),
        ],
      ),
    ),
    if (rxp != null)
      Padding(
        padding: const EdgeInsets.only(top: 10),
        child: RowCard(
          thumb: ThumbBox(child: ProductArt(rxp)),
          title: shortName(rxp),
          sub: rxp.name,
          extra: [if (pr != null && s.showPrice) PriceLineText(price: money(pr))],
        ),
      ),
    Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(children: [Btn('Enter the RX power', onTap: () => s.rxType(LensType.prog))]),
    ),
    const Sec('Your RX orders'),
    Gap([
      for (final o in s.content.rxLabOrders)
        CardBox(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      o.id,
                      style: TextStyle(fontWeight: FontWeight.w600, color: c.ink),
                    ),
                  ),
                  Pill(o.status, kind: o.kind),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(o.desc, style: TextStyle(fontSize: 12, color: c.ink2)),
              ),
              Tooltip(
                message: stages[o.stage],
                child: Stages(count: stages.length, upTo: o.stage),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text.rich(
                  TextSpan(
                    children: [
                      for (var i = 0; i < stages.length; i++) ...[
                        if (i > 0) const TextSpan(text: ' · '),
                        TextSpan(
                          text: stages[i],
                          style: i == o.stage ? TextStyle(fontWeight: FontWeight.w600, color: c.ink) : null,
                        ),
                      ],
                    ],
                  ),
                  style: TextStyle(fontSize: 12, color: c.ink2),
                ),
              ),
            ],
          ),
        ),
    ]),
  ]);
}

/// RX details: the RX progressive with its price when the power is in its range;
/// otherwise an RX request that staff check with the lab.
ScreenView rxDetailsScreen(BuildContext context, AppState s) {
  final c = context.c;
  final lt = s.lens;
  final d = s.rxd;
  final m = s.matches;
  final pw = s.rxL != null ? 'R ${powerTxt(s.rx, lt)} · L ${powerTxt(s.rxL!, lt)}' : 'R and L ${powerTxt(s.rx, lt)}';
  final axisMoved = m.isNotEmpty && [(s.rx, m[0].uR), (s.rxL ?? s.rx, m[0].uL ?? m[0].uR)].any((x) => x.$1.cyl != 0 && x.$1.axis != x.$2.axis);
  final pr = d.pick != null && d.pick! >= 0 && d.pick! < m.length ? s.pairPrice(m[d.pick!].p, m[d.pick!].li, m[d.pick!].liL) : null;
  Widget pickRow({required bool on, required Widget thumb, required String title, required String sub, required Widget price, required VoidCallback onTap}) =>
      RowCard(
        onTap: onTap,
        thumb: thumb,
        title: title,
        sub: sub,
        extra: [Padding(padding: const EdgeInsets.only(top: 4), child: price)],
        trailing: RadioDot(on: on),
        border: on ? Border.all(color: c.ink, width: 1.5) : null,
      );
  return ScreenView([
    const Hd('RX details', right: BagBtn()),
    Transform.translate(
      offset: const Offset(0, -6),
      child: Muted('${typeName[lt]} · $pw', align: TextAlign.center, margin: const EdgeInsets.only(bottom: 4)),
    ),
    const Sec('Lens', margin: EdgeInsets.only(top: 4, bottom: 8)),
    Gap([
      for (var i = 0; i < m.length; i++)
        () {
          final x = m[i];
          final xp = s.pairPrice(x.p, x.li, x.liL);
          return pickRow(
            on: d.pick == i,
            onTap: () => s.rxPick(i),
            thumb: ThumbBox(child: ProductArt(x.p)),
            title: shortName(x.p),
            sub: 'Made to order · ${rg(x.p.lines[x.li].range)}${axisMoved ? ' · axis made as ${x.uR.axis}°' : ''}',
            price: xp != null && s.showPrice ? PriceLineText(price: money(xp)) : const SizedBox.shrink(),
          );
        }(),
      pickRow(
        on: d.pick == -1,
        onTap: () => s.rxPick(-1),
        thumb: const IconThumb(Ic.rx),
        title: 'RX request',
        sub: m.isNotEmpty ? 'Ask staff to check with the lab' : 'Staff check with the lab and call you with the price and date',
        price: Text('Price on call', style: TextStyle(fontSize: 12, color: c.ink2)),
      ),
    ]),
    if (m.isEmpty)
      NoteBox.text(
        'This power is outside the RX progressive range (sphere 0 to ±2.00, cylinder up to 2.00, ADD +1.00 to +3.00). Send it as an RX request and our staff will check it with the lab.',
        kind: 'warn',
      ),
    const Sec('Patient reference (optional)'),
    StateField(initial: d.ref, hint: 'e.g. Mrs Sharma, job 214', onChanged: (v) => s.rxd.ref = v, label: 'Patient reference'),
    const Sec('Notes for the lab (optional)'),
    StateField(initial: d.note, hint: 'e.g. fitting height 18 mm, thin edge', onChanged: (v) => s.rxd.note = v, label: 'Notes for the lab'),
    NoteBox.text(
      'RX lenses are made after the order is confirmed and cannot be cancelled once at the lab. ${d.pick == -1 ? 'Staff call within the working day.' : 'Delivery usually in a few working days.'}',
    ),
  ], foot: Btn(d.pick == -1 ? 'Add RX request to cart' : 'Add to cart${pr != null && s.showPrice ? ' · ${money(pr)}' : ''}', onTap: s.rxAdd));
}
