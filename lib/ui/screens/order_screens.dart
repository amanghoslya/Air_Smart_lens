import 'package:flutter/material.dart';

import '../../core/brands.dart';
import '../../core/format.dart';
import '../../core/js_compat.dart';
import '../../core/models.dart';
import '../../core/quantity.dart';
import '../../state/app_scope.dart';
import '../../state/app_state.dart';
import '../art.dart';
import '../icons.dart';
import '../lens3d.dart';
import '../parts.dart';
import '../sheets.dart';
import '../shell.dart';
import '../theme.dart';
import '../widgets.dart';
import 'parcel_screens.dart' show typeName;

/// `sumLine(c)`: title and one-line summary of a cart line.
({String t, String m, Product? p}) sumLine(AppState s, CartLine c) {
  if (c.kind == 'rxreq') {
    final lt = c.lt!;
    return (
      t: 'RX request · ${typeName[lt]}',
      m:
          (c.rxL != null ? 'R ${powerTxt(c.rx, lt)} · L ${powerTxt(c.rxL!, lt)}' : powerTxt(c.rx, lt)) +
          (c.ref.isNotEmpty ? ' · ${c.ref}' : '') +
          (c.pref.isNotEmpty ? ' · ${c.pref}' : ''),
      p: null,
    );
  }
  final p = s.product(c.pid!);
  if (c.kind == 'grid') {
    final l = p.lines[c.li];
    final e = c.eye == 'R'
        ? ' · right eye'
        : c.eye == 'L'
        ? ' · left eye'
        : '';
    return (t: shortName(p), m: 'Bulk$e · ${rg(l.range)}${l.dia != null ? ' · ${l.dia} mm' : ''} · ${c.cells} powers', p: p);
  }
  return (
    t: shortName(p),
    m:
        '${typeName[p.ptype]} · ${c.rxL != null ? 'R ${powerTxt(c.rx, p.ptype)} · L ${powerTxt(c.rxL!, p.ptype)}' : powerTxt(c.rx, p.ptype)}'
        '${c.stock == 'mto' ? ' · made to order' : ''}${c.ref.isNotEmpty ? ' · ${c.ref}' : ''}',
    p: p,
  );
}

/// `lineHead(c)`: the lens type and range under a cart line's name (5 Nov).
String lineHead(AppState s, CartLine c) {
  if (c.kind == 'rxreq') return sumLine(s, c).m;
  final p = s.product(c.pid!);
  final l = p.lines[c.li];
  return '${typeName[p.ptype]} · range ${rg(l.range)}${l.dia != null ? ' · ${l.dia} mm' : ''}'
      '${c.kind == 'grid' && c.eye == 'R'
          ? ' · right eye'
          : c.kind == 'grid' && c.eye == 'L'
          ? ' · left eye'
          : ''}'
      '${c.stock == 'mto' ? ' · made to order' : ''}${c.ref.isNotEmpty ? ' · ${c.ref}' : ''}';
}

/// `powTable(c, i)` rows: every power of a cart line with its quantity and price (5 Nov).
List<(String, String, double?)> powRows(AppState s, CartLine c) {
  if (c.kind == 'rxreq') {
    return [
      (c.rxL != null ? 'R ${powerTxt(c.rx, c.lt!)}\nL ${powerTxt(c.rxL!, c.lt!)}' : powerTxt(c.rx, c.lt!), '${nfmt(c.qty)} pair${c.qty == 1 ? '' : 's'}', null),
    ];
  }
  final p = s.product(c.pid!);
  if (c.kind == 'one') {
    final qR = c.qR, qL = c.qL;
    final unitR = s.logic.tier(p.lines[c.li].price ?? 0) / 2, unitL = s.logic.tier(p.lines[c.liL ?? c.li].price ?? 0) / 2;
    if (c.rxL != null || (p.ptype == LensType.prog && qR != qL)) {
      return [
        if (qR > 0) (powerTxt(c.rx, p.ptype), 'R · ${nfmt(qR)} lens${qR == 1 ? '' : 'es'}', qR * unitR),
        if (qL > 0) (powerTxt(c.rxL ?? c.rx, p.ptype), 'L · ${nfmt(qL)} lens${qL == 1 ? '' : 'es'}', qL * unitL),
      ];
    }
    return [(powerTxt(c.rx, p.ptype), lineQtyTxt(c), c.qty * c.price)];
  }
  final per = c.eye == 'P' ? 1.0 : 0.5;
  final rows = [for (final e in c.grid.entries) (e.value, s.logic.cellPower(p, e.key))]
    ..sort((a, b) {
      final x = b.$2.sph.compareTo(a.$2.sph);
      if (x != 0) return x;
      final y = a.$2.cyl.compareTo(b.$2.cyl);
      return y != 0 ? y : a.$2.add.compareTo(b.$2.add);
    });
  return [
    for (final (q, x) in rows)
      (powerTxt(x, p.ptype), c.eye == 'P' ? '${nfmt(q)} pair${q == 1 ? '' : 's'}' : '${nfmt(q)} lens${q == 1 ? '' : 'es'}', q * per * c.price),
  ];
}

class _PowTable extends StatelessWidget {
  final CartLine line;
  final int i;
  const _PowTable(this.line, this.i);
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = context.c;
    final rows = powRows(s, line);
    const cap = 4;
    final open = s.cexp.contains(i);
    final show = open ? rows : rows.take(cap).toList();
    TextStyle st({bool head = false, bool bold = false}) => TextStyle(
      fontSize: head ? 10.5 : 12.5,
      fontWeight: head || bold ? FontWeight.w600 : FontWeight.w400,
      letterSpacing: head ? .5 : 0,
      color: head ? c.ink2 : c.ink,
      fontFeatures: kTabular,
    );
    Widget row(String a, String b, String v, {bool head = false, bool total = false}) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: head || total ? c.sunk : null,
        border: head ? null : Border(top: BorderSide(color: c.line)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 17,
            child: Text(
              a,
              style: st(head: head, bold: total),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 10,
            child: Text(
              b,
              style: st(head: head, bold: total),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            v,
            textAlign: TextAlign.right,
            style: st(head: head, bold: true),
          ),
        ],
      ),
    );
    return Container(
      margin: const EdgeInsets.only(top: 10),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (line.kind != 'rxreq') row('POWER', 'QTY', s.showPrice ? 'PRICE' : '', head: true),
          for (final r in show) row(r.$1, r.$2, r.$3 == null ? (s.showPrice ? 'Price on call' : '') : s.pr(r.$3!)),
          if (rows.length > cap)
            Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: c.line)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              alignment: Alignment.centerLeft,
              child: LinkBtn(open ? 'Show fewer' : 'Show all ${rows.length} powers', size: 12, onTap: () => s.toggleCexp(i)),
            ),
          if (line.kind != 'rxreq' && (rows.length > 1 || line.kind == 'grid'))
            row(
              '${rows.length} power${rows.length == 1 ? '' : 's'}',
              line.kind == 'grid' && line.eye != 'P' ? '${nfmt(line.lenses ?? 0)} lenses' : '${nfmt(line.qty)} pair${line.qty == 1 ? '' : 's'}',
              s.pr(line.qty * line.price),
              total: true,
            ),
        ],
      ),
    );
  }
}

/// Order as: Parcel / Bulk, for a line added from a brand, search, favourites, Shop by range or a product page.
class _AssignRow extends StatelessWidget {
  final int i;
  final String g;
  const _AssignRow(this.i, this.g);
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = context.c;
    Widget opt(String v, String l) {
      final on = g == v;
      return Semantics(
        inMutuallyExclusiveGroup: true,
        checked: on,
        button: true,
        label: l,
        child: GestureDetector(
          onTap: on ? null : () => s.setLineGroup(i, v),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: on ? c.ink : c.line, width: on ? 1.5 : 1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: on ? c.ink : c.ink2, width: 1.5),
                  ),
                  padding: const EdgeInsets.all(2.5),
                  child: on
                      ? DecoratedBox(
                          decoration: BoxDecoration(shape: BoxShape.circle, color: c.ink),
                        )
                      : null,
                ),
                const SizedBox(width: 7),
                Text(
                  l,
                  style: TextStyle(fontSize: 12.5, fontWeight: on ? FontWeight.w600 : FontWeight.w400, color: c.ink),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 6,
        children: [
          Text('Order as', style: TextStyle(fontSize: 12.5, color: c.ink2)),
          opt('parcel', 'Parcel'),
          opt('bulk', 'Bulk'),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- cart

/// The cart (5 Nov): two groups, Parcel order and Bulk order, each checked out on its own; All / Parcel / Bulk at
/// the top; every line shows its powers; Order as on free lines; Save for later.
ScreenView cartScreen(BuildContext context, AppState s) {
  final c = context.c;
  final groups = s.cartGroups;
  final both = groups.parcel.isNotEmpty && groups.bulk.isNotEmpty;
  final view = s.cartView;
  void edit(int i) {
    if (s.cart[i].kind == 'grid') {
      s.editGridLine(i);
    } else {
      showQtySheet(context, i);
    }
  }

  Widget item(int i) {
    final x = s.cart[i];
    final sl = sumLine(s, x);
    final av = s.logic.lineAvail(x);
    final sh = av < x.qty;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(16), boxShadow: c.e1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ThumbBox(
                w: 56,
                h: 56,
                child: sl.p != null ? ProductArt(sl.p!, li: x.li) : SvgIcon(Ic.rx, size: 22, color: c.ink2),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sl.t,
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, height: 1.25, color: c.ink),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(lineHead(s, x), style: TextStyle(fontSize: 11.5, color: c.ink2)),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (x.kind != 'rxreq') IconBtn(Ic.edit, size: 18, label: 'Edit', onTap: () => edit(i)),
                  if (x.kind == 'one' && x.stock != 'mto') PowBtn(s.cartCode(x)),
                  IconBtn(Ic.trash, size: 18, label: 'Remove', onTap: () => s.removeLine(i)),
                ],
              ),
            ],
          ),
          _PowTable(x, i),
          if (x.free) _AssignRow(i, x.group),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: LinkBtn('Save for later', size: 12.5, onTap: () => s.saveForLater(i)),
            ),
          ),
          if (sh)
            Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
              decoration: BoxDecoration(color: c.warnSoft, borderRadius: BorderRadius.circular(10)),
              child: DefaultTextStyle.merge(
                style: TextStyle(fontSize: 12.5, color: c.warn),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'You ordered ${nfmt(x.qty)} pair${x.qty == 1 ? '' : 's'}; ${av > 0 ? '${nfmt(av)} ${av == 1 ? 'is' : 'are'} available' : 'none are available right now'}.',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (av > 0) _OutlineSmall('Order ${nfmt(av)}', () => s.takeAvailable(i)),
                        _OutlineSmall('Change quantity', () => edit(i)),
                        _OutlineSmall('Remove', () => s.removeLine(i)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget group(String g, String title, String sub) {
    final idx = g == 'parcel' ? groups.parcel : groups.bulk;
    if (idx.isEmpty) return const SizedBox.shrink();
    final lines = idx.map((i) => s.cart[i]).toList();
    final t = AppState.groupTotals(lines);
    final shortTot = lines.fold<double>(0, (a, x) => a + (x.qty - s.logic.lineAvail(x)));
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 4, 2, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.ink),
                      ),
                      Text('$sub · ${idx.length} item${idx.length == 1 ? '' : 's'}', style: TextStyle(fontSize: 12, color: c.ink2)),
                    ],
                  ),
                ),
                if (s.showPrice)
                  Text(
                    money(t.v),
                    style: TextStyle(fontWeight: FontWeight.w700, color: c.ink, fontFeatures: kTabular),
                  ),
              ],
            ),
          ),
          Gap([for (final i in idx) item(i)]),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Tots([
              TotRow('${nfmt(t.n)} pair${t.n == 1 ? '' : 's'}', s.pr(t.v)),
              if (lines.any((x) => x.kind == 'rxreq')) const TotRow('RX requests', 'Price on call'),
            ]),
          ),
          if (shortTot > 0)
            NoteBox.text(
              'If you order now, short lines go with what is available and the remaining ${nfmt(shortTot)} pair${shortTot == 1 ? '' : 's'} ${shortTot == 1 ? 'is' : 'are'} cancelled.',
              kind: 'warn',
            ),
          if (both && view == 'all')
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Btn('Check out $g order · ${idx.length} item${idx.length == 1 ? '' : 's'}', onTap: () => s.toCheckout(g)),
            ),
        ],
      ),
    );
  }

  final saved = [
    if (s.saved.isNotEmpty) ...[
      Sec('Saved for later · ${s.saved.length}', margin: const EdgeInsets.only(top: 22, bottom: 8)),
      Gap([
        for (var i = 0; i < s.saved.length; i++)
          () {
            final x = s.saved[i];
            final sl = sumLine(s, x);
            return Opacity(
              opacity: .85,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(16), boxShadow: c.e1),
                child: Row(
                  children: [
                    ThumbBox(
                      w: 52,
                      h: 52,
                      child: sl.p != null ? ProductArt(sl.p!, li: x.li) : SvgIcon(Ic.rx, size: 22, color: c.ink2),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sl.t,
                            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: c.ink),
                          ),
                          Text('${x.group == 'bulk' ? 'Bulk' : 'Parcel'} · ${sl.m}', style: TextStyle(fontSize: 11.5, color: c.ink2)),
                          const SizedBox(height: 4),
                          LinkBtn('Move to cart', size: 12.5, onTap: () => s.moveToCart(i)),
                        ],
                      ),
                    ),
                    IconBtn(Ic.trash, size: 18, label: 'Remove', onTap: () => s.removeSaved(i)),
                  ],
                ),
              ),
            );
          }(),
      ]),
      Padding(
        padding: const EdgeInsets.fromLTRB(2, 8, 2, 0),
        child: Text('Saved lines are not ordered. Stock is checked again when you move them back.', style: AppText.small(c)),
      ),
    ],
  ];

  final one = view != 'all'
      ? view
      : !both
      ? (groups.parcel.isNotEmpty ? 'parcel' : 'bulk')
      : null;
  return ScreenView(
    [
      Hd('Your cart (${s.cart.length})', right: s.cart.isNotEmpty ? LinkBtn('Clear all', onTap: s.clearCart) : null),
      if (s.cart.isNotEmpty) ...[
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Seg(
            items: [('all', 'All ${s.cart.length}'), ('parcel', 'Parcel ${groups.parcel.length}'), ('bulk', 'Bulk ${groups.bulk.length}')],
            value: view,
            onTap: s.setCview,
            disabled: (v) => v == 'parcel' ? groups.parcel.isEmpty : v == 'bulk' && groups.bulk.isEmpty,
          ),
        ),
        if (both && view == 'all')
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 0, 2, 10),
            child: Text('Parcel and bulk orders are placed separately. Check out the one you want; the other stays in the cart.', style: AppText.small(c)),
          ),
        if (view != 'bulk') group('parcel', 'Parcel order', 'By courier, small quantities'),
        if (view != 'parcel') group('bulk', 'Bulk order', 'Stock order, box quantities'),
      ] else
        EmptyState('Your cart is empty', s.saved.isNotEmpty ? 'Your saved lines are below.' : 'Start a parcel or bulk order from Shop.'),
      ...saved,
    ],
    foot: s.cart.isNotEmpty
        ? Expanded(
            child: Row(
              children: [
                Btn('Add more', ghost: true, onTap: s.addMore),
                if (one != null) ...[const SizedBox(width: 10), Btn('Check out $one order', onTap: () => s.toCheckout(one))],
              ],
            ),
          )
        : Btn('Go to Shop', onTap: s.shopTab),
  );
}

class _OutlineSmall extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _OutlineSmall(this.text, this.onTap);
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        border: Border.all(color: context.c.warn),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: TextStyle(fontSize: 12, color: context.c.warn)),
    ),
  );
}

// ---------------------------------------------------------------- checkout

ScreenView checkoutScreen(BuildContext context, AppState s) {
  final c = context.c;
  // 5 Nov: only the group being checked out is placed; the other stays in the cart
  final g = s.checkoutGroup;
  final lines = s.cart.where((x) => x.group == g).toList();
  final others = s.cart.length - lines.length;
  final t = AppState.groupTotals(lines);
  final head = s.cust.limit - s.cust.outstanding;
  final over = t.v > head;
  final stock = g == 'bulk';
  return ScreenView([
    Hd(stock ? 'Checkout · bulk order' : 'Checkout · parcel order'),
    if (others > 0)
      NoteBox.text(
        'Only the $g order is placed now. Your $others ${stock ? 'parcel' : 'bulk'} item${others == 1 ? ' stays' : 's stay'} in the cart.',
        margin: EdgeInsets.zero,
      ),
    const HeadRow('Your order in words', top: 4),
    Gap([
      for (final x in lines)
        NoteBox(
          kind: 'card',
          margin: EdgeInsets.zero,
          child: Text(s.logic.sentence(x), style: TextStyle(color: c.ink)),
        ),
    ]),
    const HeadRow('Delivery'),
    RadioCard(
      on: true,
      trailing: Pill(stock ? 'Bulk order' : 'Parcel order'),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '${s.cust.name}\n',
              style: TextStyle(fontWeight: FontWeight.w600, color: c.ink),
            ),
            TextSpan(
              text: 'By courier, from Vishal Optical Co.',
              style: TextStyle(fontSize: 12, color: c.ink2),
            ),
          ],
        ),
      ),
    ),
    const HeadRow('Note for Vishal (optional)'),
    StateField(initial: s.remark, hint: "e.g. send with tomorrow's parcel", onChanged: s.setRemark, label: 'Note for Vishal'),
    if (s.showPrice)
      Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Tots([
          TotRow('${jsNum(t.n)} pair${t.n == 1 ? '' : 's'}', money(t.v)),
          TotRow('Credit available after this order', money(head - t.v), valueColor: over ? c.bad : c.good),
        ]),
      ),
    if (over && s.showPrice) NoteBox.text('This order is more than your available credit. It can be placed; billing waits for a payment.', kind: 'bad'),
    s.canOrder
        ? NoteBox.text('You can change or cancel the order for one hour after placing it.')
        : NoteBox.text(
            s.persona == 'staff'
                ? 'Your login can build the order but not place it. It is saved in the shop cart for the owner to place.'
                : 'Your account orders through your distributor. This cart goes to them as a request.',
          ),
  ], foot: Btn(Persona.all[s.persona]!.send, onTap: s.place));
}

// ---------------------------------------------------------------- placed

int orderCoat(AppState s) {
  final lo = s.lastOrder;
  final x = lo?.cart.where((c) => c.pid != null).firstOrNull;
  if (x == null) return 1;
  final k = coatKey(s.product(x.pid!));
  return coatIndex[k] ?? coatIndex[k.split(' ').first] ?? 1;
}

ScreenView placedScreen(BuildContext context, AppState s) {
  final c = context.c;
  final lo = s.lastOrder;
  final as = lo?.as ?? 'owner';
  final open = lo != null && lo.open;
  final title = as == 'staff'
      ? 'Saved to the shop cart'
      : as == 'sub'
      ? 'Sent to your distributor'
      : lo != null && lo.cancelled
      ? 'Order cancelled'
      : 'Order placed';
  final n = lo?.n ?? 0;
  return ScreenView(
    [
      Padding(
        padding: const EdgeInsets.only(top: 44),
        child: Column(
          children: [
            Transform.translate(
              offset: const Offset(0, -30),
              child: EnvelopeDrop(
                key: ValueKey('drop-${lo.hashCode}'),
                endIdx: orderCoat(s),
                onWhoosh: s.sound.whoosh,
                onThud: s.sound.thud,
                onCelebrate: s.sound.celebrate,
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -28),
              child: Column(
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: kSerif, fontWeight: FontWeight.w600, fontSize: 32, color: c.ink),
                  ),
                  const SizedBox(height: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 240),
                    child: Text(
                      as == 'owner'
                          ? 'Thank you for ordering from Vishal Optical.'
                          : as == 'staff'
                          ? 'The owner can place it from the cart.'
                          : 'Your distributor will confirm the order.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: c.ink2),
                    ),
                  ),
                  if (as == 'owner') ...[
                    CardBox(
                      margin: const EdgeInsets.only(top: 22),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Tots([
                            TotRow('Order number', lo?.number ?? s.content.nextOrderNumber),
                            TotRow('${jsNum(n)} ${n == 1 ? 'pair' : 'pairs'}', lo != null ? money(lo.v) : ''),
                          ]),
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Row(
                              children: [
                                SvgIcon(Ic.truck, size: 22, color: c.ink),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: 'Received\n',
                                          style: TextStyle(fontWeight: FontWeight.w600, color: c.ink),
                                        ),
                                        TextSpan(
                                          text: 'Stock is reserved at Confirmed. You get the courier receipt photo when it is handed to the courier.',
                                          style: TextStyle(color: c.ink2),
                                        ),
                                      ],
                                    ),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Stages(count: 6, upTo: 0),
                        ],
                      ),
                    ),
                    if (s.dropped > 0)
                      NoteBox.text(
                        '${jsNum(s.dropped)} pair${s.dropped == 1 ? ' was' : 's were'} not available and ${s.dropped == 1 ? 'was' : 'were'} cancelled.',
                        kind: 'warn',
                      ),
                    if (open)
                      NoteBox(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text.rich(
                              TextSpan(
                                children: [
                                  const TextSpan(text: 'You can change or cancel this order until '),
                                  TextSpan(
                                    text: hhmm(lo.until),
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  const TextSpan(text: '.'),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                SBtn('Change order', onTap: s.changeOrder),
                                SBtn('Cancel order', onTap: s.cancelOrder),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ],
    foot: Expanded(
      child: Column(
        children: [
          Row(children: [Btn('Continue shopping', onTap: s.goHome)]),
          const SizedBox(height: 10),
          Row(children: [Btn('View orders', ghost: true, onTap: s.goOrders)]),
        ],
      ),
    ),
  );
}

// ---------------------------------------------------------------- orders

ScreenView ordersScreen(BuildContext context, AppState s) {
  final c = context.c;
  final lo = s.lastOrder;
  final open = lo != null && lo.open;
  final rows = <({String id, String d, String st, String k, String t, String? cr, int? i, bool cur})>[
    if (lo != null && lo.as == 'owner')
      (
        id: lo.number,
        d: 'Today',
        st: lo.cancelled ? 'Cancelled' : 'Received',
        k: lo.cancelled ? 'bad' : 'n',
        t: '${jsNum(lo.n)} pairs${s.showPrice ? ' · ${money(lo.v)}' : ''}',
        cr: null,
        i: null,
        cur: true,
      ),
    for (final o in s.content.orderHistory)
      (
        id: o.id,
        d: o.date,
        st: o.status,
        k: o.kind,
        t: '${o.pairs} pairs${s.showPrice && o.value != null ? ' · ${money(o.value!)}' : ''}',
        cr: o.courier,
        i: o.repeatIndex,
        cur: false,
      ),
  ];
  return ScreenView([
    const Hd('Orders', right: BagBtn(), noBack: true),
    Gap([
      for (final o in rows)
        CardBox(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: o.id,
                            style: TextStyle(fontWeight: FontWeight.w600, color: c.ink),
                          ),
                          TextSpan(
                            text: ' · ${o.d}',
                            style: TextStyle(color: c.ink2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Pill(o.st, kind: o.k),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('${o.t}${o.cr != null ? ' · ${o.cr}' : ''}', style: TextStyle(fontSize: 12, color: c.ink2)),
              ),
              if (o.cur && open)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(text: 'Can be changed or cancelled until '),
                        TextSpan(
                          text: hhmm(lo.until),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    style: TextStyle(fontSize: 12, color: c.ink),
                  ),
                ),
              if ((o.cur && open) || o.cr != null || o.i != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (o.cur && open) ...[SBtn('Change', onTap: s.changeOrder), SBtn('Cancel', onTap: s.cancelOrder)],
                      if (o.cr != null) ...[
                        SBtn('Tracking photo', onTap: () => s.info('Courier receipt photo with the tracking number opens here')),
                        SBtn('Invoice PDF', onTap: () => s.info('Invoice PDF opens here, ready to share')),
                      ],
                      if (o.i != null) SBtn('Order again', onTap: () => s.reorder(o.i!)),
                    ],
                  ),
                ),
            ],
          ),
        ),
    ]),
  ]);
}
