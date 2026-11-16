import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../Screens/Home_Screen/Provider/brandsProvider.dart';
import '../../core/Data/responseModel/brandsResModel.dart';
import '../../core/brands.dart';
import '../../core/format.dart';
import '../../core/models.dart';
import '../../core/search.dart';
import '../../state/app_state.dart';
import '../art.dart';
import '../parts.dart';
import '../icons.dart';
import '../shell.dart';
import '../sheets.dart';
import '../theme.dart';
import '../widgets.dart';
import 'parcel_screens.dart' show typeName;

// ---------------------------------------------------------------- account

ScreenView accountScreen(BuildContext context, AppState s) {
  final c = context.c;
  final head = s.cust.limit - s.cust.outstanding;
  Widget item(String t, String sub, VoidCallback onTap) => RowCard(title: t, sub: sub, chevron: true, onTap: onTap);
  return ScreenView([
    const Hd('Account', right: BagBtn(), noBack: true),
    Display(s.cust.name, margin: const EdgeInsets.only(top: 4, bottom: 6)),
    Muted(
      '${s.cust.tier} · ${s.persona == 'owner'
          ? 'Owner'
          : s.persona == 'staff'
          ? 'Staff login'
          : 'Sub-customer'}',
      small: false,
      margin: const EdgeInsets.only(bottom: 14),
    ),
    if (s.persona != 'sub')
      CardBox(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        child: Tots([
          TotRow('Credit limit', money(s.cust.limit)),
          TotRow('Outstanding', money(s.cust.outstanding)),
          TotRow('Available', money(head), valueColor: c.good),
        ]),
      ),
    Gap([
      if (s.persona != 'sub') ...[
        item('Ledger', 'Statement, closing balance ${money(s.cust.outstanding)}', () => s.go('ledger')),
        item('Invoices', 'PDFs of every bill', () => s.go('invoices')),
      ],
      item('Favorites', s.favSub, () => s.go('wishlist')),
      if (s.persona == 'owner') item('Staff logins', 'Show prices · show availability · add to cart · place order', () => s.go('stafflogins')),
      item('Language', s.lang == 'hi' ? 'हिंदी' : 'English', () => s.go('language')),
      RowCard(
        title: 'Sound and vibration',
        sub: 'Clicks on the power dial, add to cart, order placed',
        trailing: Toggle(on: s.fb),
        onTap: s.toggleSound,
      ),
      item('Contact us', 'Call, WhatsApp group or support ticket', () => s.go('contact')),
      item('Everything else', 'Pre-orders, price list, posters, videos, certificates, web login, FAQ', s.openDrawer),
      item('Sign out', '', () => showSignOutDialog(context, s)),
    ]),
  ]);
}

// ---------------------------------------------------------------- brands

ScreenView brandsScreen(BuildContext context, AppState s) {
  final f = s.bfilter;
  return ScreenView([
    Hd(s.tr('Brands'), right: SearchBtn(onTap: s.toSearch)),
    Strip(
      bleed: false,
      children: [
        for (final x in const [('All', 'All'), (LensType.sv, 'Single vision'), (LensType.kt, 'KT'), (LensType.prog, 'Progressive')])
          ChipBtn(x.$2, on: f == x.$1, onTap: () => s.setBrandFilter(x.$1)),
      ],
    ),
    const SizedBox(height: 12),
    ApiBrandsGrid(s: s),
  ]);
}

class ApiBrandsGrid extends ConsumerWidget {
  final AppState s;
  const ApiBrandsGrid({super.key, required this.s});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final f = s.bfilter;

    List<BrandItem> localBrands() => [
          for (final b in s.brands)
            BrandItem(
              id: b,
              name: bname(b),
              productCount: brandProducts(b, s.catalog).length,
            ),
        ];

    Widget buildGrid(List<BrandItem> rawList) {
      final items = rawList.where((item) {
        if (f == 'All') return true;
        final ps = brandProducts(item.key, s.catalog);
        return ps.any((p) => p.ptype == f);
      }).toList();

      if (items.isEmpty) {
        return const Muted('No brands found for this filter.', margin: EdgeInsets.only(top: 24));
      }

      return LayoutBuilder(
        builder: (context, cons) {
          final w = (cons.maxWidth - 10) / 2;
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final item in items)
                SizedBox(
                  width: w,
                  child: _BrandCard(s: s, item: item),
                ),
            ],
          );
        },
      );
    }

    return ref.watch(brandsProvider).when(
          data: (list) => buildGrid(list.isEmpty ? localBrands() : list),
          error: (e, st) => buildGrid(localBrands()),
          loading: () => LayoutBuilder(
            builder: (context, cons) {
              final w = (cons.maxWidth - 10) / 2;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (var i = 0; i < 6; i++)
                    SizedBox(
                      width: w,
                      child: AspectRatio(
                        aspectRatio: 4 / 5,
                        child: Container(
                          decoration: BoxDecoration(
                            color: c.card2,
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        );
  }
}

class _BrandCard extends StatelessWidget {
  final AppState s;
  final BrandItem item;
  const _BrandCard({required this.s, required this.item});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final b = item.key;
    final im = brandImage[b];
    final url = item.picture;
    final name = (item.name?.trim().isNotEmpty == true) ? item.name!.trim() : bname(b);
    final ps = brandProducts(b, s.catalog);
    final hasImage = (url != null && url.isNotEmpty) || im != null;

    Widget fallback() {
      if (im != null) {
        return BrandImg(im, alignment: const Alignment(0, -.5), semantic: name);
      } else if (ps.isNotEmpty) {
        return Center(
          child: FractionallySizedBox(widthFactor: .58, child: LensArt(tint: coatTint(ps.first))),
        );
      } else {
        return Center(
          child: FractionallySizedBox(widthFactor: .62, child: LensArt(tint: c.ink2)),
        );
      }
    }

    String countLabel;
    if (ps.isNotEmpty) {
      final count = ps.where((p) => s.bfilter == 'All' || p.ptype == s.bfilter).length;
      countLabel = '$count ${s.bfilter == 'All' ? 'lenses' : typeName[s.bfilter]}';
    } else {
      final n = item.productCount ?? 0;
      countLabel = '$n product${n == 1 ? '' : 's'}';
    }

    return Pressable(
      onTap: () => s.openBrand(b, info: item),
      child: AspectRatio(
        aspectRatio: 4 / 5,
        child: Container(
          decoration: BoxDecoration(color: c.card2, borderRadius: BorderRadius.circular(16), boxShadow: c.e1),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (url != null && url.isNotEmpty)
                Image.network(
                  url,
                  fit: BoxFit.cover,
                  alignment: const Alignment(0, -.5),
                  loadingBuilder: (_, child, p) => p == null ? child : const SizedBox(),
                  errorBuilder: (ctx, err, st) => fallback(),
                )
              else
                fallback(),
              if (hasImage)
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x000A0C10), Color(0x000A0C10), Color(0x9E0A0C10)],
                      stops: [0, .5, 1],
                    ),
                  ),
                ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 10,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: kSerif,
                              fontWeight: FontWeight.w600,
                              fontSize: 21,
                              color: hasImage ? Colors.white : c.ink,
                            ),
                          ),
                          Text(
                            countLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: (hasImage ? Colors.white : c.ink).withValues(alpha: .85),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const ArrowCircle(size: 26),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// `.bhero`: the photo header of a brand page (also About us).
class BrandHero extends StatelessWidget {
  final String? image;
  final String? imageUrl; // picture from the API; wins over the local `image`
  final Product? lensFor;
  final String title, sub;
  final VoidCallback onBack;
  const BrandHero({super.key, this.image, this.imageUrl, this.lensFor, required this.title, required this.sub, required this.onBack});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return SizedBox(
      height: 210,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: c.card2),
          if (imageUrl != null)
            Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              alignment: const Alignment(0, -.4),
              loadingBuilder: (_, child, p) => p == null ? child : const SizedBox(),
              errorBuilder: (ctx, err, st) => image != null ? BrandImg(image!, alignment: const Alignment(0, -.4)) : const SizedBox(),
            )
          else if (image != null)
            BrandImg(image!, alignment: const Alignment(0, -.4)),
          if (imageUrl == null && image == null && lensFor != null)
            Center(
              child: SizedBox(width: 120, child: LensArt(tint: coatTint(lensFor!))),
            ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x000A0C10), Color(0x000A0C10), Color(0xAD0A0C10)],
                stops: [0, .35, 1],
              ),
            ),
          ),
          Positioned(
            top: 10,
            left: 14,
            child: Semantics(
              button: true,
              label: 'Back',
              child: GestureDetector(
                onTap: onBack,
                child: const ArrowCircle(size: 36, icon: Ic.back),
              ),
            ),
          ),
          Positioned(
            left: 18,
            right: 18,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontFamily: kSerif, fontWeight: FontWeight.w600, fontSize: 36, height: 1, color: Colors.white),
                ),
                const SizedBox(height: 2),
                Text(sub, style: const TextStyle(fontSize: 12, color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

ScreenView brandScreen(BuildContext context, AppState s) {
  final c = context.c;
  final b = s.brand ?? s.brands.first;
  final im = brandImage[b];
  // what the API sent for this brand (the card that was tapped); null when opened some other way
  final info = s.brandInfo != null && s.brandInfo!.key == b ? s.brandInfo : null;
  final ps = brandProducts(b, s.catalog);
  final types = ['All', ...LensType.all.where((t) => ps.any((p) => p.ptype == t))];
  final tab = types.contains(s.btab) ? s.btab : 'All';
  final show = ps.where((p) => tab == 'All' || p.ptype == tab).toList();
  return ScreenView([
    Bleed(
      child: BrandHero(
        image: im,
        imageUrl: info?.picture,
        lensFor: ps.isNotEmpty ? ps.first : null,
        title: info?.name?.trim().isNotEmpty == true ? info!.name!.trim() : bname(b),
        sub: info != null
            ? '${[info.description, brandLine[b]].whereType<String>().where((x) => x.trim().isNotEmpty).toSet().join(' · ')} · ${info.productCount ?? ps.length} product${(info.productCount ?? ps.length) == 1 ? '' : 's'}'
            : '${brandLine[b] ?? ''} · ${ps.length} product${ps.length == 1 ? '' : 's'}',
        onBack: s.back,
      ),
    ),
    Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.line)),
        ),
        child: Strip(
          bleed: false,
          gap: 18,
          children: [
            for (final t in types)
              GestureDetector(
                onTap: () => s.setBrandTab(t),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: tab == t ? c.ink : Colors.transparent, width: 2)),
                  ),
                  child: Text(
                    t == 'All' ? 'All lenses' : typeName[t]!,
                    style: TextStyle(fontSize: 13, color: tab == t ? c.ink : c.ink2, fontWeight: tab == t ? FontWeight.w600 : FontWeight.w400),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
    if (show.isEmpty) const Muted('No lenses to order for this brand yet.', margin: EdgeInsets.only(top: 14)),
    Gap([
      for (final p in show) BrandProductCard(p, b == 'KOPPERX' ? shortName(p) : '${coatShort(p)} ${p.index}${p.variant.isNotEmpty ? ' · ${p.variant}' : ''}'),
    ]),
  ]);
}

// ---------------------------------------------------------------- search

ScreenView searchScreen(BuildContext context, AppState s) {
  final raw = s.q.trim();
  final q = raw.toLowerCase().replaceAll('−', '-');
  final pw = RegExp(r'^([+-]?\d+(?:\.\d+)?)\s*[\/, ]\s*([+-]?\d+(?:\.\d+)?)$').firstMatch(q);
  final rc = RegExp(r'^([+-]\d+)([+-]\d+)$').firstMatch(q);
  var hits = <Product>[];
  if (pw != null) {
    final sph = double.parse(pw.group(1)!), cyl = double.parse(pw.group(2)!);
    hits = s.catalog
        .where((p) => !p.rx && List.generate(p.lines.length, (i) => i).any((li) => s.logic.lineMatches(p, li, Rx(sph: sph, cyl: cyl, axis: 90, add: 2))))
        .toList();
  } else if (rc != null) {
    String norm(String x) => x.toLowerCase().replaceAll(RegExp(r'\s'), '').replaceAll('.00', '').replaceAll(RegExp(r'\.(?=\D|$)'), '');
    hits = s.catalog.where((p) => p.lines.any((l) => norm(l.range).contains('${rc.group(1)}${rc.group(2)}'))).toList();
  } else if (q.isNotEmpty) {
    // 6 Nov: trade short forms (BC, PC, PG, HC, V2, LRB, O2/DC, BBC) match whole tags, see core/search.dart
    hits = s.catalog.where((p) => lensMatch(p, q)).toList();
  }
  return ScreenView([
    const Hd('Search', right: BagBtn()),
    SearchBox(key: const ValueKey('search'), initial: s.q, hint: 'BC, PG, V2, 1.67 or −2.00/−0.50', onChanged: s.setQuery),
    if (pw != null)
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: RowCard(
          thumb: const IconThumb(Ic.rx),
          title: 'Order ${fmt(double.parse(pw.group(1)!))} / ${fmt(double.parse(pw.group(2)!))} as a parcel order',
          sub: 'Opens the parcel order with this power',
          chevron: true,
          onTap: () => s.orderPower(double.parse(pw.group(1)!), double.parse(pw.group(2)!)),
        ),
      ),
    if (q.isNotEmpty) ...[
      Sec('${hits.length} product${hits.length == 1 ? '' : 's'}'),
      Gap([
        for (final p in hits.take(30))
          RowCard(
            thumb: ThumbBox(child: ProductArt(p)),
            title: shortName(p),
            sub: '${typeName[p.ptype]} · ${p.lines.map((l) => rg(l.range)).take(3).join(' · ')}${p.lines.length > 3 ? ' …' : ''}',
            chevron: true,
            onTap: () => s.openProduct(p.id),
          ),
      ]),
    ] else ...[
      const Sec('Try'),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final x in const ['BC', 'PC', 'PG', 'HC', 'V2', 'LRB', 'BBC', 'opal', '1.67', 'KT', '−2.00/−0.50', '−6−2'])
            ChipBtn(x, onTap: () => s.trySearch(x)),
        ],
      ),
    ],
  ]);
}

// ---------------------------------------------------------------- favorites

/// Favorites (30 Oct): saved powers (as VOC1 codes: opening one works like scanning its QR), saved ranges and
/// saved lenses.
ScreenView wishlistScreen(BuildContext context, AppState s) {
  final c = context.c;
  final ps = s.wish.map(s.product).toList();
  final rs = [
    for (final k in s.wishR)
      if (k.split(':').length == 2) (int.parse(k.split(':')[0]), int.parse(k.split(':')[1])),
  ];
  final pw = [
    for (final code in s.wishP)
      if (s.qrInfo(code) != null) s.qrInfo(code)!,
  ];
  return ScreenView([
    const Hd('Favorites', right: BagBtn()),
    if (pw.isNotEmpty) ...[
      const Sec('Powers'),
      Gap([
        for (final i in pw)
          RowCard(
            thumb: ThumbBox(child: ProductArt(i.p, li: i.li)),
            titleWidget: Text(
              i.pw.join(' · '),
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.ink, fontFeatures: kTabular),
            ),
            sub: '${shortName(i.p)} · ${i.range}${i.p.ptype == LensType.prog ? ' · ${i.eyeTxt}' : ''}',
            onTap: () => s.openScan(i.code),
            trailing: IconBtn(Ic.heart, size: 19, filled: true, label: 'Remove from favorites', onTap: () => s.togglePowerFav(i.code)),
          ),
      ]),
    ],
    if (rs.isNotEmpty) ...[
      const Sec('Ranges'),
      Gap([
        for (final (pid, li) in rs)
          if (pid >= 1 && pid <= s.catalog.length && li < s.product(pid).lines.length) RangeRow(s.product(pid), li, withName: true),
      ]),
    ],
    if (ps.isNotEmpty && (rs.isNotEmpty || pw.isNotEmpty)) const Sec('Lenses'),
    if (ps.isNotEmpty)
      Gap([
        for (final p in ps)
          RowCard(
            thumb: ThumbBox(child: ProductArt(p)),
            title: shortName(p),
            sub: typeName[p.ptype],
            extra: [
              if (s.showPrice && s.fromPrice(p) != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'From ${money(s.fromPrice(p)!)}',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.ink, fontFeatures: kTabular),
                  ),
                ),
            ],
            chevron: true,
            onTap: () => s.openProduct(p.id),
          ),
      ])
    else if (rs.isEmpty && pw.isEmpty)
      const EmptyState('Nothing saved yet', 'Tap the heart on any lens, on one of its ranges, or on a power you have added.'),
  ]);
}
