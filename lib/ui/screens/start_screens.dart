import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:air_smart_lens/Screens/Home_Screen/Provider/brandsProvider.dart';
import 'package:air_smart_lens/Screens/Home_Screen/Provider/catalogProvider.dart';
import 'package:air_smart_lens/core/Data/responseModel/brandsResModel.dart';

import '../../core/brands.dart';
import '../../core/models.dart';
import '../../state/app_scope.dart';
import '../../state/app_state.dart';
import '../art.dart';
import '../icons.dart';
import '../lens3d.dart' show LoaderLens;
import '../shell.dart';
import '../theme.dart';
import '../widgets.dart';

export 'package:air_smart_lens/Screens/Welcome_Screen/welcome_screen.dart' show welcomeScreen, WelcomeScreen;
export 'package:air_smart_lens/Screens/Login_Screen/login_screen.dart' show loginScreen, LoginScreen, LoginForm, LoginFooterButton;

// ---------------------------------------------------------------- welcome
// (welcomeScreen is exported above from package:air_smart_lens/Screens/Welcome_Screen/welcome_screen.dart)

// ---------------------------------------------------------------- login
// (loginScreen is exported above from package:air_smart_lens/Screens/Login_Screen/login_screen.dart)

// ---------------------------------------------------------------- home

ScreenView homeScreen(BuildContext context, AppState s) {
  final c = context.c;
  Widget quick(IconDef icon, String label, VoidCallback onTap) => Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Column(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: c.card,
                  border: Border.all(color: c.line),
                ),
                alignment: Alignment.center,
                child: SvgIcon(icon, size: 21, color: c.ink),
              ),
              const SizedBox(height: 7),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, height: 1.2, color: c.ink),
              ),
            ],
          ),
        ),
      );
  final shown = posters.where((x) => x.$2 != 'vishal2_card' && !x.$2.endsWith('1_card')).toList();
  return ScreenView([
    SizedBox(
      height: 48,
      child: Row(
        children: [
          Transform.translate(
            offset: const Offset(-4, 0),
            child: IconBtn(Ic.menu, label: 'Menu', onTap: s.openDrawer),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              'Air Smart Lens',
              maxLines: 1,
              overflow: TextOverflow.fade,
              softWrap: false,
              style: TextStyle(fontFamily: kSerif, fontWeight: FontWeight.w600, fontSize: 25, color: c.ink),
            ),
          ),
          // 3 Nov: search beside favorites and the cart
          SearchBtn(onTap: s.toSearch),
          IconBtn(
            Ic.heart,
            label: 'Favorites',
            filled: s.wish.length + s.wishR.length > 0,
            count: s.wish.length + s.wishR.length,
            onTap: () => s.go('wishlist'),
          ),
          Transform.translate(offset: const Offset(4, 0), child: const BagBtn()),
        ],
      ),
    ),
    const SizedBox(height: 8),
    Text('${s.tr('Good morning')}, ${s.cust.name}', style: AppText.small(c)),
    Display(s.tr('See every power,\norder in a minute')),
    Bleed(child: ApiHeroCarousel(s: s)),
    // 6 Nov: Order by (five ways to start), then Shop by brand, which moves along by itself
    HeadRow(s.tr('Order by')),
    Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        quick(Ic.glasses, s.tr('Brand'), () => s.go('brands')),
        const SizedBox(width: 4),
        quick(Ic.rx, s.tr('Lens type'), s.toParcel),
        const SizedBox(width: 4),
        quick(Ic.boxes, s.tr('Bulk (large quantity)'), s.toStock),
        const SizedBox(width: 4),
        quick(Ic.eye, s.tr('RX'), s.toRx),
        const SizedBox(width: 4),
        quick(Ic.rangeGrid, s.tr('Range'), s.toRange),
      ],
    ),
    HeadRow(s.tr('Shop by brand'), right: LinkBtn(s.tr('See all'), onTap: () => s.go('brands'))),
    const Bleed(child: ApiBrandStrip()),
    HeadRow(s.tr('Posters and videos'), right: LinkBtn(s.tr('See all'), onTap: () => s.go('posters'))),
    Strip(
      gap: 10,
      padding: const EdgeInsets.only(bottom: 4),
      children: [
        _PosterTile(width: 140, image: 'vishal1_face', title: 'Fitting a progressive', sub: 'Video · 2 min', video: true, onTap: () => s.go('videos')),
        for (final p in shown)
          _PosterTile(
            width: (228 * imageAspect(p.$2, s.data.imageAspect)).roundToDouble().clamp(135.0, 175.0),
            image: p.$2,
            title: '${bname(p.$1)} poster',
            sub: 'A3 · A4 · WhatsApp',
            onTap: () => s.go('posters'),
          ),
      ],
    ),
  ]);
}

class _PosterTile extends StatelessWidget {
  static const double cardWidth = 140.0;
  static const double cardHeight = 228.0;

  final double width;
  final String image, title, sub;
  final bool video;
  final VoidCallback onTap;
  const _PosterTile({
    this.width = cardWidth,
    required this.image,
    required this.title,
    required this.sub,
    required this.onTap,
    this.video = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: cardHeight,
        width: width,
        decoration: BoxDecoration(
          color: c.sunk,
          borderRadius: BorderRadius.circular(14),
          boxShadow: c.e1,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background image
            BrandImg(
              image,
              fit: BoxFit.cover,
              alignment: video ? Alignment.center : Alignment.topCenter,
              semantic: video ? null : title,
            ),

            // Gradient overlay for contrast and text readability
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: const Alignment(0, 0.15),
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.55),
                      Colors.black.withValues(alpha: 0.85),
                    ],
                  ),
                ),
              ),
            ),

            // Video Play Badge in center
            if (video)
              const Center(
                child: PlayBadge(size: 36),
              ),

            // Text overlay at the bottom using Stack (title + sub)
            Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withValues(alpha: 0.85),
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PlayBadge extends StatelessWidget {
  final double size;
  const PlayBadge({super.key, this.size = 30});
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(color: Color(0xEBFFFFFF), shape: BoxShape.circle),
        alignment: Alignment.center,
        child: SvgIcon(Ic.play, size: 14, color: const Color(0xFF1B2130)),
      );
}

/// One card of the Home carousel: a brand picture with its name and tagline written over it.
class HeroItem {
  final String key; // catalog brand key, e.g. 'AIR SMART'
  final String title;
  final String tagline;
  final String? url; // picture from the API
  final String asset; // local picture, used for the card's shape and as a fallback
  final BrandItem? info; // the API brand, handed to the brand page
  const HeroItem({required this.key, required this.title, required this.tagline, required this.asset, this.url, this.info});
}

/// Home's brand cards, loaded from GET /customer/brands. The text over each picture is laid out exactly as before.
/// While loading it shows grey cards; if the call fails it falls back to the client's local brand cards.
class ApiHeroCarousel extends ConsumerWidget {
  final AppState s;
  const ApiHeroCarousel({super.key, required this.s});

  static List<HeroItem> _local() => [
        for (final h in heroCards) HeroItem(key: h.$1, title: bname(h.$1), tagline: brandLine[h.$1] ?? '', asset: h.$2),
      ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    return ref.watch(brandsProvider).when(
          data: (list) => list.isEmpty
              ? HeroCarousel(s: s, items: _local())
              : HeroCarousel(
                  key: ValueKey(list.length),
                  s: s,
                  items: [
                    for (final b in list)
                      HeroItem(
                        key: b.key,
                        title: (b.name ?? b.id ?? '').trim(),
                        tagline: brandLine[b.key] ?? b.description ?? '',
                        url: b.picture,
                        info: b,
                        asset: '${b.key.toLowerCase().replaceAll(' ', '')}_bg',
                      ),
                  ],
                ),
          error: (e, st) => HeroCarousel(s: s, items: _local()),
          loading: () => SizedBox(
            height: 340 + 4 + 31,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 35),
              children: [
                for (var i = 0; i < 3; i++)
                  Container(
                    width: 340 * 768 / 1376,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(color: c.card2, borderRadius: BorderRadius.circular(16)),
                  ),
              ],
            ),
          ),
        );
  }
}

/// The client's brand cards as a swipeable carousel with dots, auto-advancing every 4 s.
class HeroCarousel extends StatefulWidget {
  final AppState s;
  final List<HeroItem> items;
  const HeroCarousel({super.key, required this.s, required this.items});
  @override
  State<HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<HeroCarousel> {
  final _ctl = ScrollController();
  Timer? _timer;
  int _on = 0;
  static const _h = 340.0, _gap = 10.0, _pad = 18.0;

  List<HeroItem> get _items => widget.items;
  List<double> get _widths => [for (final c in _items) _h * imageAspect(c.asset, widget.s.data.imageAspect)];
  double _pos(int i) {
    var x = 0.0;
    for (var k = 0; k < i; k++) {
      x += _widths[k] + _gap;
    }
    return x;
  }

  int _idx() {
    if (!_ctl.hasClients) return 0;
    final off = _ctl.offset;
    if (off >= _ctl.position.maxScrollExtent - 2) return _items.length - 1;
    var b = 0;
    for (var i = 0; i < _items.length; i++) {
      if ((_pos(i) - off).abs() < (_pos(b) - off).abs()) b = i;
    }
    return b;
  }

  void _to(int i) {
    if (!_ctl.hasClients) return;
    i = (i + _items.length) % _items.length;
    _ctl.animateTo(_pos(i).clamp(0, _ctl.position.maxScrollExtent), duration: const Duration(milliseconds: 450), curve: Curves.easeInOut);
  }

  void _restart() {
    _timer?.cancel();
    if (MediaQuery.of(context).disableAnimations) return;
    _timer = Timer.periodic(const Duration(seconds: 4), (_) => _to(_idx() + 1));
  }

  @override
  void initState() {
    super.initState();
    _ctl.addListener(() {
      final i = _idx();
      if (i != _on) setState(() => _on = i);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _restart();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Column(
      children: [
        SizedBox(
          height: _h + 4,
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n is ScrollStartNotification && n.dragDetails != null) _timer?.cancel();
              if (n is ScrollEndNotification) {
                final i = _idx();
                if ((_pos(i) - _ctl.offset).abs() > 2 && _ctl.offset < _ctl.position.maxScrollExtent - 2) {
                  Future.microtask(() => _to(i));
                }
                _restart();
              }
              return false;
            },
            child: ListView.separated(
              controller: _ctl,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(_pad, 0, _pad, 4),
              itemCount: _items.length,
              separatorBuilder: (context, index) => const SizedBox(width: _gap),
              itemBuilder: (context, i) {
                final h = _items[i];
                final brandTitle = h.title;
                final tagline = h.tagline;
                return Pressable(
                  onTap: () => widget.s.openBrand(h.key, info: h.info),
                  child: Container(
                    width: _widths[i],
                    height: _h,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2622),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: c.e1,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Solid base background color while image is decoding
                        const Positioned.fill(
                          child: ColoredBox(color: Color(0xFF2A2622)),
                        ),

                        // Background clean image (text-free portrait)
                        Positioned.fill(
                          child: h.url != null
                              ? Image.network(
                                  h.url!,
                                  fit: BoxFit.cover,
                                  alignment: Alignment.center,
                                  semanticLabel: '$brandTitle: $tagline',
                                  loadingBuilder: (_, child, p) => p == null ? child : const SizedBox(),
                                  errorBuilder: (ctx, err, st) =>
                                      BrandImg(h.asset, fit: BoxFit.cover, fallback: h.asset == 'welcome_bg' ? 'welcome_full' : null),
                                )
                              : BrandImg(
                                  h.asset,
                                  fit: BoxFit.cover,
                                  alignment: Alignment.center,
                                  fallback: h.asset == 'welcome_bg' ? 'welcome_full' : null,
                                  semantic: '$brandTitle: $tagline',
                                ),
                        ),

                        // Top gradient overlay for contrast and header readability
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: const Alignment(0, -0.05),
                                colors: [
                                  Colors.black.withValues(alpha: 0.5),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Bottom gradient overlay for contrast and title/subtitle readability
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: const Alignment(0, 0.12),
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.55),
                                  Colors.black.withValues(alpha: 0.85),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Top Header: Brand Name + OPTICAL
                        Align(
                          alignment: Alignment.topLeft,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  brandTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: kSerif,
                                    fontSize: 21,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    height: 1.05,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'OPTICAL',
                                  style: TextStyle(
                                    fontFamily: kSans,
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withValues(alpha: 0.85),
                                    letterSpacing: 3.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Bottom Content: Title, subtitle and arrow button
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // Text Column
                                Expanded(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tagline,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontFamily: kSerif,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                          height: 1.15,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Premium lenses',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontFamily: kSans,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w400,
                                          color: Colors.white.withValues(alpha: 0.85),
                                          height: 1.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 8),
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Color(0x40000000),
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.arrow_forward,
                                    color: Color(0xFF1B2130),
                                    size: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < _items.length; i++)
                GestureDetector(
                  onTap: () {
                    _to(i);
                    _restart();
                  },
                  child: Semantics(
                    button: true,
                    label: 'Card ${i + 1}',
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2.5),
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: i == _on ? c.ink : c.line),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- shop

ScreenView shopScreen(BuildContext context, AppState s) {
  // 31 Oct: Shop opens with Shop by brand, then the three ways to order, then Shop by range (3 Nov) and Search.
  final c = context.c;
  return ScreenView([
    const Hd('Shop', right: BagBtn(), noBack: true),
    // 6 Nov: the search box is at the top of Shop
    Semantics(
      button: true,
      label: 'Search',
      child: Pressable(
        onTap: s.toSearch,
        child: Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(999), boxShadow: c.e1),
          child: Row(
            children: [
              SvgIcon(Ic.search, size: 18, color: c.ink2),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Search a coating, brand, index, range code or power',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13.5, color: c.mute),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    HeadRow(s.tr('Shop by brand'), right: LinkBtn(s.tr('See all'), onTap: () => s.go('brands')), top: 14),
    const Bleed(child: ApiBrandStrip()),
    HeadRow(s.tr('Order by')),
    Gap(gap: 10, [
      OrderTypeCard(
        small: true,
        title: s.tr('Parcel (lens type)'),
        text: 'Small quantity, from the power. Half a pair, a pair or a few, by courier.',
        art: const BoxesArt([(22, 24, 40, 40), (30, 2, 30, 26)]),
        onTap: s.toParcel,
      ),
      OrderTypeCard(
        small: true,
        title: s.tr('Bulk (power chart)'),
        text: 'Start from the product. Box quantities on a power grid.',
        art: const BoxesArt([(0, 34, 36, 34), (38, 34, 36, 34), (18, 4, 38, 32)]),
        onTap: s.toStock,
      ),
      OrderTypeCard(
        small: true,
        title: s.tr('RX order'),
        text: "Progressive lenses made at the lab to the customer's power.",
        art: const RxArt(),
        onTap: s.toRx,
      ),
    ]),
    const SizedBox(height: 12),
    Gap([
      RowCard(
        thumb: const IconThumb(Ic.rangeGrid),
        title: 'Shop by range',
        sub: 'Single vision, KT or progressive, then a range code such as −6.00−2.00',
        chevron: true,
        onTap: s.toRange,
      ),
    ]),
  ]);
}

/// `.bmini`: a brand photo with its name and number of products (Shop by brand).
class BrandMini extends StatelessWidget {
  final String b;
  const BrandMini(this.b, {super.key});
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = context.c;
    final ps = brandProducts(b, s.catalog);
    final im = brandImage[b];
    return Semantics(
      button: true,
      label: '${bname(b)}, ${ps.length} products',
      child: Pressable(
        onTap: () => s.openBrand(b),
        child: SizedBox(
          width: 96,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 118,
                width: 96,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(color: c.card2, borderRadius: BorderRadius.circular(14), boxShadow: c.e1),
                child: im != null
                    ? BrandImg(im, alignment: const Alignment(0, -0.5))
                    : Center(
                        child: FractionallySizedBox(widthFactor: .62, child: LensArt(tint: coatTint(ps.first))),
                      ),
              ),
              const SizedBox(height: 6),
              Text(
                bname(b),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontFamily: kSerif, fontSize: 16, fontWeight: FontWeight.w600, height: 1.1, color: c.ink),
              ),
              Text('${ps.length} product${ps.length == 1 ? '' : 's'}', style: TextStyle(fontSize: 10.5, color: c.ink2)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Home's Shop by brand, loaded from GET /customer/brands. While loading it shows grey tiles; if the call fails it
/// falls back to the brands in the local catalog so Home is never empty.
class ApiBrandStrip extends ConsumerWidget {
  const ApiBrandStrip({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppScope.of(context);
    final c = context.c;
    return ref.watch(brandsProvider).when(
          data: (list) =>
              list.isEmpty ? AutoStrip(children: [for (final b in s.brands) BrandMini(b)]) : AutoStrip(children: [for (final b in list) ApiBrandMini(b)]),
          error: (e, st) => AutoStrip(children: [for (final b in s.brands) BrandMini(b)]),
          loading: () => Strip(
            gap: 10,
            padding: const EdgeInsets.only(bottom: 6),
            children: [
              for (var i = 0; i < 5; i++)
                Container(
                  width: 96,
                  height: 118 + 6 + 34,
                  alignment: Alignment.topCenter,
                  child: Container(
                    height: 118,
                    decoration: BoxDecoration(color: c.card2, borderRadius: BorderRadius.circular(14)),
                  ),
                ),
            ],
          ),
        );
  }
}

/// `.bmini` for a brand from the API: its picture (network), name and product count.
class ApiBrandMini extends StatelessWidget {
  final BrandItem b;
  const ApiBrandMini(this.b, {super.key});
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = context.c;
    final name = (b.name ?? b.id ?? '').trim();
    final n = b.productCount ?? 0;
    final url = b.picture;
    final local = brandImage[b.key];
    Widget fallback() => local != null
        ? BrandImg(local, alignment: const Alignment(0, -0.5))
        : Center(child: FractionallySizedBox(widthFactor: .62, child: LensArt(tint: c.ink2)));
    return Semantics(
      button: true,
      label: '$name, $n products',
      child: Pressable(
        onTap: () => s.openBrand(b.key, info: b),
        child: SizedBox(
          width: 96,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 118,
                width: 96,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(color: c.card2, borderRadius: BorderRadius.circular(14), boxShadow: c.e1),
                child: url != null
                    ? Image.network(
                        url,
                        fit: BoxFit.cover,
                        alignment: const Alignment(0, -0.5),
                        loadingBuilder: (_, child, p) => p == null ? child : const SizedBox(),
                        errorBuilder: (ctx, err, st) => fallback(),
                      )
                    : fallback(),
              ),
              const SizedBox(height: 6),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontFamily: kSerif, fontSize: 16, fontWeight: FontWeight.w600, height: 1.1, color: c.ink),
              ),
              Text('$n product${n == 1 ? '' : 's'}', style: TextStyle(fontSize: 10.5, color: c.ink2)),
            ],
          ),
        ),
      ),
    );
  }
}

class OrderTypeCard extends StatelessWidget {
  final String title, text;
  final Widget art;
  final VoidCallback onTap;
  final bool small; // `.otype.sm`: one row, smaller art (Shop, 31 Oct)
  const OrderTypeCard({super.key, required this.title, required this.text, required this.art, required this.onTap, this.small = false});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    if (small) {
      return Pressable(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
          decoration: BoxDecoration(color: c.card2, borderRadius: BorderRadius.circular(18), boxShadow: c.e1),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, height: 1.2, color: c.ink),
                    ),
                    const SizedBox(height: 3),
                    Text(text, style: TextStyle(fontSize: 12.5, color: c.ink2, height: 1.4)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 58,
                height: 52,
                child: FittedBox(fit: BoxFit.contain, child: art),
              ),
              const SizedBox(width: 10),
              const ArrowCircle(size: 36),
            ],
          ),
        ),
      );
    }
    return Pressable(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 170),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        decoration: BoxDecoration(color: c.card2, borderRadius: BorderRadius.circular(18), boxShadow: c.e1),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600, height: 1.2, color: c.ink),
                  ),
                  const SizedBox(height: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 190),
                    child: Text(text, style: TextStyle(fontSize: 13, color: c.ink2, height: 1.4)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            SizedBox(
              height: 130,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [art, const ArrowCircle()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cardboard boxes art on the order-type cards.
class BoxesArt extends StatelessWidget {
  final List<(double, double, double, double)> boxes; // left, top, width, height
  const BoxesArt(this.boxes, {super.key});
  @override
  Widget build(BuildContext context) => SizedBox(
        width: 76,
        height: 70,
        child: Stack(
          children: [
            for (final b in boxes)
              Positioned(
                left: b.$1,
                top: b.$2,
                width: b.$3,
                height: b.$4,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFD9B98C), Color(0xFFC49A63)]),
                    border: Border.all(color: const Color(0x0F000000)),
                  ),
                  child: Align(
                    alignment: const Alignment(-0.0, 0),
                    child: FractionallySizedBox(widthFactor: .12, heightFactor: 1, child: Container(color: const Color(0x47FFFFFF))),
                  ),
                ),
              ),
          ],
        ),
      );
}

/// The RX lens art: a glass disc with an "Rx" tag.
class RxArt extends StatelessWidget {
  const RxArt({super.key});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return SizedBox(
      width: 70,
      height: 62,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 6,
            top: 4,
            width: 58,
            height: 58,
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Color(0x2E283040), blurRadius: 10, offset: Offset(0, 4))],
                gradient: RadialGradient(colors: [Color(0xFFEEF2F6), Color(0xFFEEF2F6), Color(0xFFC9D1DA), Color(0xFF9AA6B4)], stops: [0, .55, .8, 1]),
              ),
              foregroundDecoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xCCFFFFFF), width: 1.5),
                gradient: const RadialGradient(
                  center: Alignment(-.32, -.4),
                  radius: .6,
                  colors: [Colors.white, Colors.white, Color(0x00FFFFFF)],
                  stops: [0, .2, .55],
                ),
              ),
            ),
          ),
          Positioned(
            right: -6 + 6,
            bottom: -4 + 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(color: c.navy, borderRadius: BorderRadius.circular(6)),
              child: Text(
                'Rx',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: c.onNavy),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- lens type

/// `.pcard`: lens-type card with a photo on the right.
class PhotoCard extends StatelessWidget {
  final String title, sub, count, image;
  final VoidCallback onTap;
  const PhotoCard({super.key, required this.title, required this.sub, required this.count, required this.image, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Pressable(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 96),
        decoration: BoxDecoration(color: c.card2, borderRadius: BorderRadius.circular(16), boxShadow: c.e1),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: c.ink),
                      ),
                      const SizedBox(height: 3),
                      Text(sub, style: TextStyle(fontSize: 12, color: c.ink2)),
                      const SizedBox(height: 8),
                      Text(count, style: TextStyle(fontSize: 12, color: c.ink2)),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: 108,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(
                      color: c.sunk,
                      child: BrandImg(image, alignment: const Alignment(0, -.4)),
                    ),
                    const Positioned(right: 10, bottom: 10, child: ArrowCircle(size: 34)),
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

const lensTypeCards = [
  (LensType.sv, 'max1_face', 'Single vision', 'One power, for distance or reading'),
  (LensType.kt, 'vishal1_face', 'KT', 'Two powers, one lens'),
  (LensType.prog, 'kopperx1_face', 'Progressive', 'Seamless vision at all distances'),
];

ScreenView lensTypeScreen(BuildContext context, AppState s) => ScreenView([
      Hd(s.tr('Parcel order'), right: SearchBtn(onTap: s.toSearch)),
      ApiParcelLensTypeCards(s: s),
    ]);

class ApiParcelLensTypeCards extends ConsumerStatefulWidget {
  final AppState s;
  const ApiParcelLensTypeCards({super.key, required this.s});

  @override
  ConsumerState<ApiParcelLensTypeCards> createState() => _ApiParcelLensTypeCardsState();
}

class _ApiParcelLensTypeCardsState extends ConsumerState<ApiParcelLensTypeCards> {
  ScrollPosition? _scrollPosition;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(catalogProvider.notifier).getCatalogData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scrollable = Scrollable.maybeOf(context);
    final position = scrollable?.position;
    if (_scrollPosition != position) {
      _scrollPosition?.removeListener(_onScroll);
      _scrollPosition = position;
      _scrollPosition?.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    _scrollPosition?.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    final pos = _scrollPosition;
    if (pos == null) return;
    if (pos.pixels >= pos.maxScrollExtent - 150) {
      ref.read(catalogProvider.notifier).loadMoreCatalogData();
    }
  }

  static const Map<String, ({String image, String sub, String type})> _staticMeta = {
    LensType.sv: (
      image: 'max1_face',
      sub: 'One power, for distance or reading',
      type: LensType.sv,
    ),
    LensType.kt: (
      image: 'vishal1_face',
      sub: 'Two powers, one lens',
      type: LensType.kt,
    ),
    LensType.prog: (
      image: 'kopperx1_face',
      sub: 'Seamless vision at all distances',
      type: LensType.prog,
    ),
  };

  static String _resolveLensType(String name) {
    final clean = name.trim().toLowerCase().replaceAll(RegExp(r'[\s_-]'), '');
    if (clean.contains('single') || clean == 'sv') return LensType.sv;
    if (clean.contains('kt')) return LensType.kt;
    if (clean.contains('prog')) return LensType.prog;
    if (clean.contains('rx')) return 'RX';
    for (final entry in LensType.names.entries) {
      if (entry.value.toLowerCase() == name.trim().toLowerCase()) return entry.key;
    }
    return name;
  }

  List<Widget> _buildDefaultCards(AppState s) {
    return [
      for (final x in lensTypeCards)
        PhotoCard(
          title: x.$3,
          sub: x.$4,
          count: '${s.catalog.where((p) => p.ptype == x.$1).length} products',
          image: x.$2,
          onTap: () => s.chooseLens(x.$1),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final s = widget.s;
    final state = ref.watch(catalogProvider);

    // Initial loading state while API call is in progress (clean loader without text)
    if (state.isLoading && state.lensTypes.isEmpty) {
      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.55,
        child: const Center(
          child: LoaderLens(size: 96),
        ),
      );
    }

    final List<Widget> cardWidgets = [];

    if (state.lensTypes.isNotEmpty) {
      for (final item in state.lensTypes) {
        final title = (item.name?.trim().isNotEmpty == true) ? item.name!.trim() : 'Lens';
        final typeKey = _resolveLensType(title);

        // RX lens ko comment out / skip kiya gaya hai (Parcel screen me sirf 3 lenses hi show honge)
        if (typeKey == 'RX' || title.toLowerCase() == 'rx' || title.toLowerCase().startsWith('rx')) {
          continue; // RX lens commented out / excluded
        }

        final meta = _staticMeta[typeKey] ??
            (
              image: 'max1_face',
              sub: 'Seamless vision at all distances',
              type: typeKey,
            );

        final count = item.count ?? s.catalog.where((p) => p.ptype == typeKey).length;
        final countText = '$count product${count == 1 ? '' : 's'}';

        cardWidgets.add(
          PhotoCard(
            title: title,
            sub: meta.sub,
            count: countText,
            image: meta.image,
            onTap: () => s.chooseLens(meta.type),
          ),
        );
      }
    } else {
      cardWidgets.addAll(_buildDefaultCards(s));
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.pixels >= notification.metrics.maxScrollExtent - 150) {
          ref.read(catalogProvider.notifier).loadMoreCatalogData();
        }
        return false;
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Gap(cardWidgets),
          const Muted(
            'Not sure which lens? Enter the power on the next screen and every lens that stocks it is shown.',
            margin: EdgeInsets.only(top: 14),
          ),
          if (state.isLoadMore)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Loading more lenses...',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: c.ink2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Home's Shop by brand (6 Nov): moves one brand along every 2.5 s, back to the start at the end. A touch or drag
/// pauses it for 6 s so the customer can choose; nothing moves when the phone asks for reduced motion.
class AutoStrip extends StatefulWidget {
  final List<Widget> children;
  const AutoStrip({super.key, required this.children});
  @override
  State<AutoStrip> createState() => _AutoStripState();
}

class _AutoStripState extends State<AutoStrip> {
  final _ctl = ScrollController();
  Timer? _t;
  DateTime _pauseTill = DateTime(0);

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(milliseconds: 2500), (_) => _step());
  }

  void _step() {
    if (!mounted || !_ctl.hasClients || MediaQuery.of(context).disableAnimations) return;
    if (DateTime.now().isBefore(_pauseTill)) return;
    final pos = _ctl.position;
    const tile = 96.0 + 10; // BrandMini width + gap
    final end = pos.pixels >= pos.maxScrollExtent - 4;
    _ctl.animateTo(end ? 0 : math.min(pos.maxScrollExtent, pos.pixels + tile), duration: const Duration(milliseconds: 450), curve: Curves.easeInOut);
  }

  void _pause() => _pauseTill = DateTime.now().add(const Duration(seconds: 6));

  @override
  void dispose() {
    _t?.cancel();
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Listener(
        onPointerDown: (_) => _pause(),
        onPointerSignal: (_) => _pause(),
        child: Strip(gap: 10, controller: _ctl, padding: const EdgeInsets.only(bottom: 6), children: widget.children),
      );
}
