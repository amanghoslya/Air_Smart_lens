import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/brands.dart';
import '../../core/format.dart';
import '../../state/app_state.dart';
import '../art.dart';
import '../icons.dart';
import '../sheets.dart';
import '../shell.dart';
import '../theme.dart';
import '../widgets.dart';
import 'browse_screens.dart' show BrandHero;
import 'parcel_screens.dart' show typeName;
import 'start_screens.dart' show PlayBadge;

Widget _miThumb(BuildContext context, String k) => ThumbBox(child: SvgIcon(Ic.mi[k]!, size: 24, color: context.c.ink2));

// ---------------------------------------------------------------- pre-orders

ScreenView preorderScreen(BuildContext context, AppState s) {
  final soon = <(int pid, int li)>[];
  for (final p in s.catalog) {
    for (var i = 0; i < p.lines.length; i++) {
      if (p.lines[i].status == 'coming soon') soon.add((p.id, i));
    }
  }
  return ScreenView([
    const Hd('Pre-orders', right: BagBtn()),
    const Muted('Lenses arriving soon. Pre-order now and they are sent as soon as they reach the warehouse.', margin: EdgeInsets.only(bottom: 10)),
    if (s.pre.isNotEmpty) ...[
      Sec('Your pre-orders · ${s.pre.length}'),
      Gap([
        for (var i = 0; i < s.pre.length; i++)
          RowCard(
            thumb: ThumbBox(child: ProductArt(s.product(s.pre[i].pid), li: s.pre[i].li)),
            title: shortName(s.product(s.pre[i].pid)),
            sub: s.preTxt(s.pre[i]),
            extra: [if (s.pre[i].eta.isNotEmpty) Muted('Expected in ${s.pre[i].eta}')],
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Pill('Pre-ordered', kind: 'warn'),
                IconBtn(Ic.trash, size: 19, label: 'Cancel pre-order', onTap: () => s.removePre(i)),
              ],
            ),
          ),
      ]),
    ] else
      const NoteBox(
        margin: EdgeInsets.zero,
        child: Text('To pre-order a sold-out power, choose it in a parcel or bulk order: the Add button becomes Pre-order.'),
      ),
    if (soon.isNotEmpty) Sec('Coming soon · ${soon.length} ranges'),
    Gap([
      for (final x in soon)
        () {
          final p = s.product(x.$1);
          final l = p.lines[x.$2];
          final done = s.pre.any((y) => y.pid == p.id && y.li == x.$2);
          return RowCard(
            thumb: ThumbBox(child: ProductArt(p)),
            title: shortName(p),
            sub: '${typeName[p.ptype]} · ${rg(l.range)}${l.dia != null ? ' · ${l.dia} mm' : ''}',
            extra: [if (l.price != null && s.showPrice) PriceLineText(price: money(s.logic.tier(l.price!)))],
            trailing: done ? const Pill('Pre-ordered', kind: 'warn') : SBtn('Pre-order', onTap: () => showPreorderSheet(context, p.id, x.$2)),
          );
        }(),
    ]),
  ]);
}

// ---------------------------------------------------------------- posters, videos, certificates

ScreenView postersScreen(BuildContext context, AppState s) => ScreenView([
  const Hd('Posters', right: BagBtn()),
  const Muted('Print-ready for your shop window, or share straight to WhatsApp.', margin: EdgeInsets.only(bottom: 12)),
  LayoutBuilder(
    builder: (context, cons) {
      final w = (cons.maxWidth - 10) / 2;
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final p in posters)
            SizedBox(
              width: w,
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: w,
                      height: 240,
                      child: ColoredBox(
                        color: context.c.sunk,
                        child: BrandImg(
                          p.$2,
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                          semantic: '${bname(p.$1)} poster',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: SBtn('Save', padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4), onTap: () => s.info('PDF downloads here')),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: SBtn('Share', padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4), onTap: () => s.info('Opens WhatsApp share')),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      );
    },
  ),
]);

ScreenView videosScreen(BuildContext context, AppState s) {
  final c = context.c;
  return ScreenView([
    const Hd('Videos', right: BagBtn()),
    Gap([
      for (final v in s.content.videos)
        Pressable(
          onTap: () => s.info('Video plays here'),
          child: Container(
            padding: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(16), boxShadow: c.e1),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 150,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ColoredBox(
                        color: c.sunk,
                        child: BrandImg(v.image, alignment: const Alignment(0, -.4)),
                      ),
                      const Center(child: PlayBadge(size: 44)),
                      Positioned(
                        right: 10,
                        bottom: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0x99000000), borderRadius: BorderRadius.circular(6)),
                          child: Text(v.duration, style: const TextStyle(fontSize: 11, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text(
                    v.title,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.ink),
                  ),
                ),
              ],
            ),
          ),
        ),
    ]),
  ]);
}

ScreenView certsScreen(BuildContext context, AppState s) => ScreenView([
  const Hd('Certificates', right: BagBtn()),
  const Muted('Show these to your customers. Vishal uploads the real documents; these titles are examples.', margin: EdgeInsets.only(bottom: 12)),
  Gap([
    for (final cert in s.content.certificates)
      RowCard(
        thumb: _miThumb(context, 'award'),
        title: cert.title,
        sub: cert.sub,
        trailing: SBtn('PDF', onTap: () => s.info('PDF downloads here')),
      ),
  ]),
]);

// ---------------------------------------------------------------- price list

ScreenView priceListScreen(BuildContext context, AppState s) {
  final c = context.c;
  if (!s.showPrice) {
    return const ScreenView([Hd('Price list'), EmptyState('Prices are hidden', 'Your account orders through your distributor.')]);
  }
  final b = s.plBrand ?? s.brands.first;
  final ps = brandProducts(b, s.catalog);
  return ScreenView([
    Hd('Price list', right: LinkBtn('PDF', onTap: () => s.info('PDF downloads here'))),
    Muted('Your prices as a ${s.cust.tier}, per pair. Updated whenever Vishal changes the price file.', margin: const EdgeInsets.only(bottom: 10)),
    Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Strip(
        bleed: false,
        children: [for (final x in s.brands) ChipBtn(bname(x), on: x == b, onTap: () => s.setPriceListBrand(x))],
      ),
    ),
    for (final p in ps)
      CardBox(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        radius: 14,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              shortName(p),
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: c.ink),
            ),
            Text('${typeName[p.ptype]} · ${titlecase(p.base)}', style: TextStyle(fontSize: 12, color: c.ink2)),
            const SizedBox(height: 8),
            for (final l in p.lines)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: c.line)),
                ),
                child: DefaultTextStyle.merge(
                  style: TextStyle(fontSize: 12.5, color: c.ink, fontFeatures: kTabular),
                  child: Row(
                    children: [
                      Expanded(flex: 5, child: Text(rg(l.range))),
                      Expanded(flex: 3, child: Text(l.dia != null ? '${l.dia} mm' : '')),
                      Expanded(
                        flex: 3,
                        child: l.price != null
                            ? Text(money(s.logic.tier(l.price!)), textAlign: TextAlign.right)
                            : Text(
                                'soon',
                                textAlign: TextAlign.right,
                                style: TextStyle(color: c.ink2),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
  ]);
}

// ---------------------------------------------------------------- money

ScreenView ledgerScreen(BuildContext context, AppState s) {
  final c = context.c;
  var bal = s.content.openingBalance;
  final rows = <(String, String, bool, int, int, int)>[];
  for (final r in s.content.ledger) {
    if (r.text != 'Opening balance') bal += r.debit - r.credit;
    rows.add((r.date, r.text, r.isInvoice, r.debit, r.credit, bal));
  }
  return ScreenView([
    Hd('Ledger', right: LinkBtn('PDF', onTap: () => s.info('PDF downloads here'))),
    Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Seg(
        items: const [('sep', 'Sep–Oct'), ('year', 'This year'), ('custom', 'Custom')],
        value: 'sep',
        onTap: (v) {
          if (v != 'sep') s.info('Date filter opens here');
        },
      ),
    ),
    CardBox(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Tots([TotRow('Opening balance', money(s.content.openingBalance)), TotRow('Closing balance (you owe)', money(bal))]),
    ),
    Gap([
      for (final r in rows.skip(1).toList().reversed)
        CardBox(
          radius: 14,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.$2,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.ink),
                    ),
                    const SizedBox(height: 2),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text('${r.$1} 2026', style: TextStyle(fontSize: 11.5, color: c.ink2)),
                        if (r.$3) ...[
                          Text(' · ', style: TextStyle(fontSize: 11.5, color: c.ink2)),
                          LinkBtn('PDF', size: 11.5, onTap: () => s.info('PDF downloads here')),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    r.$4 != 0 ? '+ ${money(r.$4)}' : '− ${money(r.$5)}',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: r.$4 != 0 ? c.ink : c.good, fontFeatures: kTabular),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Bal ${money(r.$6)}',
                    style: TextStyle(fontSize: 11.5, color: c.ink2, fontFeatures: kTabular),
                  ),
                ],
              ),
            ],
          ),
        ),
    ]),
    const Muted('From the accounts system, updated daily. + bills, − payments and credit notes.', margin: EdgeInsets.only(top: 10)),
  ]);
}

ScreenView transactionsScreen(BuildContext context, AppState s) {
  final c = context.c;
  final t = s.content.ledger.where((r) => r.credit != 0).toList().reversed;
  return ScreenView([
    const Hd('Transactions'),
    const Muted('Payments and credit notes received from your shop.', margin: EdgeInsets.only(bottom: 10)),
    Gap([
      for (final r in t)
        RowCard(
          thumb: _miThumb(context, 'swap'),
          title: r.text,
          sub: '${r.date} 2026',
          trailing: Text(
            money(r.credit),
            style: TextStyle(fontWeight: FontWeight.w600, color: c.good, fontFeatures: kTabular),
          ),
        ),
    ]),
  ]);
}

ScreenView invoicesScreen(BuildContext context, AppState s) {
  final c = context.c;
  final inv = s.content.ledger.where((r) => r.isInvoice).toList().reversed;
  return ScreenView([
    const Hd('Invoices'),
    const Muted('Every bill as a PDF. Freight is on the bill.', margin: EdgeInsets.only(bottom: 10)),
    Gap([
      for (final r in inv)
        RowCard(
          thumb: _miThumb(context, 'file'),
          title: r.text.split(' · ').first.replaceFirst('Invoice ', ''),
          sub: '${r.date} 2026 · ${r.text.split(' · ')[1]}',
          extra: [PriceLineText(price: money(r.debit), suffix: '')],
          trailing: Column(
            children: [
              SBtn('PDF', onTap: () => s.info('PDF downloads here')),
              const SizedBox(height: 6),
              SBtn('Share', onTap: () => s.info('Opens WhatsApp share')),
            ],
          ),
        ),
    ]),
    if (c.dark) const SizedBox.shrink(),
  ]);
}

ScreenView salesReportScreen(BuildContext context, AppState s) {
  final c = context.c;
  final months = s.content.months;
  final mx = months.map((m) => m.value).reduce((a, b) => a > b ? a : b);
  final tp = months.fold<int>(0, (a, m) => a + m.pairs), tv = months.fold<int>(0, (a, m) => a + m.value);
  final big = TextStyle(fontFamily: kSerif, fontSize: 28, fontWeight: FontWeight.w600, height: 1, color: c.ink, fontFeatures: kTabular);
  return ScreenView([
    Hd('Sales report', right: LinkBtn('PDF', onTap: () => s.info('PDF downloads here'))),
    const Muted('What your shop has bought from Vishal this financial year.', margin: EdgeInsets.only(bottom: 12)),
    Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Wrap(
        spacing: 26,
        runSpacing: 10,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(indianGroup(tp), style: big),
              const Muted('pairs'),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(money(tv), style: big),
              const Muted('billed'),
            ],
          ),
        ],
      ),
    ),
    CardBox(
      radius: 14,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: SizedBox(
        height: 150,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < months.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${(months[i].value / 100000).toStringAsFixed(1)}L',
                      style: TextStyle(fontSize: 10, color: c.ink2, fontFeatures: kTabular),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      constraints: const BoxConstraints(maxWidth: 26),
                      height: (months[i].value / mx * 96).roundToDouble(),
                      decoration: BoxDecoration(
                        color: c.navy,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(5), bottom: Radius.circular(2)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(months[i].month, style: TextStyle(fontSize: 11, color: c.ink2)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    ),
    Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Table(
        columnWidths: const {0: FlexColumnWidth(1.3), 1: FlexColumnWidth(1), 2: FlexColumnWidth(1.4)},
        children: [
          TableRow(
            decoration: BoxDecoration(color: c.card2),
            children: [
              for (final h in const ['Month', 'Pairs', 'Value'])
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    h,
                    textAlign: h == 'Month' ? TextAlign.left : TextAlign.right,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: c.ink2),
                  ),
                ),
            ],
          ),
          for (final m in months)
            TableRow(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: c.line)),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text('${m.month} 2026', style: TextStyle(fontSize: 12.5, color: c.ink)),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    '${m.pairs}',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 12.5, color: c.ink, fontFeatures: kTabular),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    money(m.value),
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 12.5, color: c.ink, fontFeatures: kTabular),
                  ),
                ),
              ],
            ),
        ],
      ),
    ),
    const Muted('October is month to date.', margin: EdgeInsets.only(top: 8)),
  ]);
}

ScreenView analysisScreen(BuildContext context, AppState s) {
  final c = context.c;
  final m = s.content.months;
  List<Widget> bars(List<dynamic> a) => [
    for (final x in a)
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            SizedBox(
              width: 92,
              child: Text(x.label as String, style: TextStyle(fontSize: 12.5, color: c.ink)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  height: 8,
                  child: Stack(
                    children: [
                      Positioned.fill(child: ColoredBox(color: c.sunk)),
                      FractionallySizedBox(
                        widthFactor: (x.percent as int) / 100,
                        child: Container(
                          decoration: BoxDecoration(color: c.navy, borderRadius: BorderRadius.circular(4)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 40,
              child: Text(
                '${x.percent}%',
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: c.ink, fontFeatures: kTabular),
              ),
            ),
          ],
        ),
      ),
  ];
  return ScreenView([
    const Hd('Sales analysis'),
    const Muted('Share of your purchases by value, April to October.', margin: EdgeInsets.only(bottom: 12)),
    const HeadRow('By brand', top: 0),
    ...bars(s.content.byBrand),
    const HeadRow('By lens type'),
    ...bars(s.content.byLensType),
    const HeadRow('Most ordered powers'),
    Tots([for (final r in s.content.topPowers) TotRow(r.$1, '${r.$2} pairs')]),
    NoteBox.text('Sep was your best month: ${m[5].pairs} pairs, up ${((m[5].pairs / m[4].pairs - 1) * 100).round()}% on August.'),
  ]);
}

// ---------------------------------------------------------------- settings

ScreenView staffLoginsScreen(BuildContext context, AppState s) {
  final c = context.c;
  const sw = ['Show prices', 'Show availability', 'Add to cart', 'Place order'];
  return ScreenView([
    const Hd('Staff logins'),
    const Muted('Each login has its own mobile number and four switches. Vishal can set these too.', margin: EdgeInsets.only(bottom: 12)),
    for (var i = 0; i < s.staffLogins.length; i++)
      CardBox(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.staffLogins[i].name,
                        style: TextStyle(fontWeight: FontWeight.w600, color: c.ink),
                      ),
                      Text(s.staffLogins[i].mobile, style: TextStyle(fontSize: 12, color: c.ink2)),
                    ],
                  ),
                ),
                Pill(s.staffLogins[i].switches[3] ? 'Can place orders' : 'Cannot place orders', kind: s.staffLogins[i].switches[3] ? 'good' : 'n'),
              ],
            ),
            for (var j = 0; j < sw.length; j++)
              TotRow(
                sw[j],
                '',
                last: j == sw.length - 1,
                labelWidget: Row(
                  children: [
                    Expanded(
                      child: Text(sw[j], style: TextStyle(fontSize: 13.5, color: c.ink)),
                    ),
                    Semantics(
                      label: '${sw[j]} for ${s.staffLogins[i].name}',
                      toggled: s.staffLogins[i].switches[j],
                      child: Toggle(on: s.staffLogins[i].switches[j], onTap: () => s.toggleStaffSwitch(i, j)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    Row(children: [Btn('Add a staff login', ghost: true, onTap: () => s.info('Add name and mobile number, then set the four switches'))]),
  ]);
}

ScreenView webLoginScreen(BuildContext context, AppState s) => ScreenView([
  const Hd('Web login'),
  const Muted(
    'Order from a computer with the same account. Your cart, orders and invoices are the same on both.',
    small: false,
    margin: EdgeInsets.only(bottom: 14),
  ),
  CardBox(
    padding: const EdgeInsets.all(16),
    child: Tots([TotRow('Website', s.content.webAddress), const TotRow('Login', 'Your mobile number'), const TotRow('Code', 'One-time code by SMS')]),
  ),
  const Muted('The web address is a placeholder until the domain is fixed.', margin: EdgeInsets.only(top: 12)),
  Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Row(
      children: [
        Btn(
          'Copy web address',
          onTap: () {
            Clipboard.setData(ClipboardData(text: s.content.webAddress));
            s.info('Web address copied');
          },
        ),
      ],
    ),
  ),
]);

ScreenView languageScreen(BuildContext context, AppState s) {
  final c = context.c;
  return ScreenView([
    Hd(s.tr('Language')),
    Gap(gap: 8, [
      for (final x in const [('en', 'English', 'English'), ('hi', 'हिंदी', 'Hindi')])
        RadioCard(
          on: s.lang == x.$1,
          onTap: () => s.setLang(x.$1),
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '${x.$2}\n',
                  style: TextStyle(fontWeight: FontWeight.w600, color: c.ink),
                ),
                TextSpan(
                  text: x.$3,
                  style: TextStyle(fontSize: 12, color: c.ink2),
                ),
              ],
            ),
          ),
        ),
    ]),
    const Muted(
      'In this model Hindi covers the menu, tab bar and home screen; the full app is translated in the build (Q52).',
      margin: EdgeInsets.only(top: 12),
    ),
  ]);
}

// ---------------------------------------------------------------- help

ScreenView contactScreen(BuildContext context, AppState s) => ScreenView([
  const Hd('Contact us'),
  const Display("We're here to help", margin: EdgeInsets.only(top: 4, bottom: 14)),
  Gap([
    for (final r in const [
      ('phone', 'Call the order desk', 'Mon to Sat, 10 am to 7 pm', 'Calls the order desk'),
      ('swap', 'WhatsApp group', 'For quick questions and photos', 'Opens WhatsApp share'),
      ('help', 'Raise a support ticket', 'For app problems; we reply the same day', 'Opens a support ticket'),
      ('team', 'Remote help', 'Our team connects only after your staff approve it', 'Remote help starts only after your staff approve it'),
    ])
      RowCard(thumb: _miThumb(context, r.$1), title: r.$2, sub: r.$3, chevron: true, onTap: () => s.info(r.$4)),
  ]),
  const Muted('Phone numbers and address come from Vishal Optical before launch.', margin: EdgeInsets.only(top: 12)),
]);

class _Details extends StatefulWidget {
  final String q, a;
  final bool open;
  const _Details(this.q, this.a, {this.open = false});
  @override
  State<_Details> createState() => _DetailsState();
}

class _DetailsState extends State<_Details> {
  late bool open = widget.open;
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return CardBox(
      radius: 14,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => open = !open),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                AnimatedRotation(
                  turns: open ? .25 : 0,
                  duration: const Duration(milliseconds: 150),
                  child: Text('▸ ', style: TextStyle(color: c.ink)),
                ),
                Expanded(
                  child: Text(
                    widget.q,
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: c.ink),
                  ),
                ),
              ],
            ),
            if (open)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(widget.a, style: TextStyle(fontSize: 13, color: c.ink2)),
              ),
          ],
        ),
      ),
    );
  }
}

ScreenView faqScreen(BuildContext context, AppState s) =>
    ScreenView([const Hd('FAQ'), for (var i = 0; i < s.content.faqs.length; i++) _Details(s.content.faqs[i].q, s.content.faqs[i].a, open: i == 0)]);

ScreenView aboutScreen(BuildContext context, AppState s) => ScreenView([
  Bleed(
    child: BrandHero(image: 'vishal2_face', title: 'Vishal Optical Co.', sub: 'Prescription lenses, wholesale', onBack: s.back),
  ),
  Padding(
    padding: const EdgeInsets.only(top: 16),
    child: Text(
      'Vishal Optical supplies prescription lenses to optical shops: single vision, KT and progressive, across ${s.brands.length} brands and ${s.catalog.length} products.',
    ),
  ),
  const Muted('Vishal Optical supplies the final text and photos.', margin: EdgeInsets.only(top: 12)),
]);

ScreenView termsScreen(BuildContext context, AppState s) => ScreenView([
  const Hd('Terms and conditions'),
  for (final t in s.content.terms) _Details(t.$1, t.$2, open: true),
  const Muted('Draft wording for the model; Vishal Optical approves the final terms.'),
]);
