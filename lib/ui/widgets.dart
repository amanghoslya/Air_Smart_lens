import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/models.dart';
import '../core/quantity.dart';
import '../state/app_scope.dart';
import 'icons.dart';
import 'theme.dart';

// ---------------------------------------------------------------- text

Text eyebrow(BuildContext context, String s) => Text(s.toUpperCase(), style: AppText.eyebrow(context.c));

class Sec extends StatelessWidget {
  final String text;
  final EdgeInsets margin;
  const Sec(this.text, {super.key, this.margin = const EdgeInsets.only(top: 18, bottom: 8)});
  @override
  Widget build(BuildContext context) => Padding(
        padding: margin,
        child: Text(text.toUpperCase(), style: AppText.eyebrow(context.c)),
      );
}

/// `.h`: a section heading with an optional link on the right.
class HeadRow extends StatelessWidget {
  final String text;
  final Widget? right;
  final double top;
  const HeadRow(this.text, {super.key, this.right, this.top = 20});
  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(top: top, bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: Text(text, style: AppText.h(context.c))),
            if (right != null) right!,
          ],
        ),
      );
}

class Display extends StatelessWidget {
  final String text;
  final EdgeInsets margin;
  final TextStyle? style;
  const Display(this.text, {super.key, this.margin = const EdgeInsets.fromLTRB(0, 2, 0, 14), this.style});
  @override
  Widget build(BuildContext context) => Padding(
        padding: margin,
        child: Text(text, style: style ?? AppText.display(context.c)),
      );
}

class Muted extends StatelessWidget {
  final String text;
  final bool small;
  final TextAlign? align;
  final EdgeInsets margin;
  const Muted(this.text, {super.key, this.small = true, this.align, this.margin = EdgeInsets.zero});
  @override
  Widget build(BuildContext context) => Padding(
        padding: margin,
        child: Text(
          text,
          textAlign: align,
          style: TextStyle(fontSize: small ? 12 : 14, height: 1.45, color: context.c.ink2),
        ),
      );
}

// ---------------------------------------------------------------- buttons

/// A tappable surface that shrinks slightly when pressed (`:active{transform:scale(.985)}`).
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  const Pressable({super.key, required this.child, this.onTap, this.scale = .985});
  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null) return widget.child;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(scale: _down ? widget.scale : 1, duration: const Duration(milliseconds: 200), child: widget.child),
    );
  }
}

/// `.btn`: navy pill, or `.btn.ghost` outlined.
class Btn extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final bool ghost;
  final bool expand;
  final double? minWidth;
  const Btn(this.text, {super.key, this.onTap, this.ghost = false, this.expand = true, this.minWidth});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final enabled = onTap != null;
    final b = Opacity(
      opacity: enabled ? 1 : .4,
      child: Material(
        color: ghost ? Colors.transparent : c.navy,
        shape: StadiumBorder(side: ghost ? BorderSide(color: c.ink) : BorderSide.none),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Container(
            constraints: BoxConstraints(minHeight: 52, minWidth: minWidth ?? 0),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            alignment: Alignment.center,
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: ghost ? c.ink : c.onNavy),
            ),
          ),
        ),
      ),
    );
    return expand ? Expanded(child: b) : b;
  }
}

/// `.ib`: a round icon button, optionally with a count badge.
class IconBtn extends StatelessWidget {
  final IconDef icon;
  final VoidCallback? onTap;
  final int? count;
  final bool filled;
  final String? label;
  final double size;
  const IconBtn(this.icon, {super.key, this.onTap, this.count, this.filled = false, this.label, this.size = 21});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Semantics(
      button: true,
      label: label,
      child: InkResponse(
        onTap: onTap,
        radius: 22,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              SvgIcon(icon, color: c.ink, size: size, filled: filled),
              if (count != null && count! > 0)
                Positioned(
                  top: 3,
                  right: 2,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 16),
                    height: 16,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(color: c.navy, borderRadius: BorderRadius.circular(8)),
                    alignment: Alignment.center,
                    child: Text(
                      '$count',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: c.onNavy),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// `.lnk`: an underlined text link.
class LinkBtn extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final double size;
  final FontWeight weight;
  const LinkBtn(this.text, {super.key, this.onTap, this.size = 12, this.weight = FontWeight.w400});
  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            text,
            style: TextStyle(fontSize: size, fontWeight: weight, color: context.c.ink, decoration: TextDecoration.underline, decorationColor: context.c.ink),
          ),
        ),
      );
}

/// `.arrow`: a round arrow badge.
class ArrowCircle extends StatelessWidget {
  final double size;
  final bool dark;
  final IconDef icon;
  final Color? bg, fg;
  const ArrowCircle({super.key, this.size = 40, this.dark = false, this.icon = Ic.arrow, this.bg, this.fg});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg ?? (dark ? c.navy : c.card),
        shape: BoxShape.circle,
        boxShadow: dark ? null : [BoxShadow(color: c.shade, blurRadius: 8, offset: const Offset(0, 2))],
      ),
      alignment: Alignment.center,
      child: SvgIcon(icon, size: size * .45, color: fg ?? (dark ? c.onNavy : c.ink)),
    );
  }
}

/// `.chip`
class ChipBtn extends StatelessWidget {
  final String label;
  final bool on;
  final VoidCallback? onTap;
  const ChipBtn(this.label, {super.key, this.on = false, this.onTap});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: on ? c.navy : c.card,
          border: Border.all(color: on ? c.navy : c.line),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(label, style: TextStyle(fontSize: 12.5, color: on ? c.onNavy : c.ink)),
      ),
    );
  }
}

/// A horizontal strip that scrolls (chips, brand row, posters, range tabs) and
/// bleeds to the screen edges like `margin:0 -18px; padding:0 18px`.
class Strip extends StatelessWidget {
  final List<Widget> children;
  final double gap;
  final double? height;
  final bool bleed;
  final EdgeInsets padding;
  final ScrollController? controller;
  final CrossAxisAlignment cross;
  const Strip({
    super.key,
    required this.children,
    this.gap = 8,
    this.height,
    this.bleed = true,
    this.padding = EdgeInsets.zero,
    this.controller,
    this.cross = CrossAxisAlignment.start,
  });
  @override
  Widget build(BuildContext context) {
    final row = SingleChildScrollView(
      controller: controller,
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: bleed ? 18 : 0).add(padding),
      child: Row(
        crossAxisAlignment: cross,
        children: [
          for (var i = 0; i < children.length; i++) ...[if (i > 0) SizedBox(width: gap), children[i]],
        ],
      ),
    );
    final sized = height != null ? SizedBox(height: height, child: row) : row;
    return bleed ? Bleed(child: sized) : sized;
  }
}

/// A block that runs to the screen edges (`margin:0 -18px`). The shell pads every
/// other top-level block of a screen by 18 px on each side.
class Bleed extends StatelessWidget {
  final Widget child;
  const Bleed({super.key, required this.child});
  @override
  Widget build(BuildContext context) => child;
}

/// `.seg`: a segmented control.
class Seg extends StatelessWidget {
  final List<(String, String)> items; // (value, label)
  final String value;
  final ValueChanged<String> onTap;
  final bool Function(String v)? disabled;
  const Seg({super.key, required this.items, required this.value, required this.onTap, this.disabled});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: c.sunk, borderRadius: BorderRadius.circular(999)),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: Opacity(
                opacity: disabled?.call(items[i].$1) == true ? .4 : 1,
                child: GestureDetector(
                  onTap: disabled?.call(items[i].$1) == true ? null : () => onTap(items[i].$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
                    decoration: BoxDecoration(color: value == items[i].$1 ? c.navy : Colors.transparent, borderRadius: BorderRadius.circular(999)),
                    alignment: Alignment.center,
                    child: Text(
                      items[i].$2,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: value == items[i].$1 ? FontWeight.w600 : FontWeight.w400,
                        color: value == items[i].$1 ? c.onNavy : c.ink2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- header

/// `hd(title, right, noBack)`: the screen header.
///
/// 6 Nov: the cart is one tap away at the top right of every screen (not on the cart, checkout and order-placed
/// screens), with Search next to it (see [BagBtn]). A screen that passes its own search button gets the cart only.
class Hd extends StatelessWidget {
  final String title;
  final Widget? right;
  final bool noBack;
  const Hd(this.title, {super.key, this.right, this.noBack = false});

  static const noCart = {'cart', 'checkout', 'placed', 'loading', 'welcome'};

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final r = right;
    final Widget? extra = noCart.contains(s.screen) || r is BagBtn
        ? null
        : r is SearchBtn
            ? const BagBtn(cartOnly: true)
            : const BagBtn();
    double bagW(BagBtn b) => b.cartOnly || BagBtn.ownSearch.contains(s.screen) ? 38 : 76;
    final icons = (r is BagBtn ? bagW(r) : 0) + (extra is BagBtn ? bagW(extra) : 0) + (r is SearchBtn || r is IconBtn ? 38 : 0);
    final link = r is LinkBtn ? r.text.length * 12.0 + 8.0 : (r != null && r is! BagBtn && r is! SearchBtn && r is! IconBtn ? 44.0 : 0.0);
    final side = math.max(80.0, icons + link + 4);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            SizedBox(
              width: side,
              child: Align(
                alignment: Alignment.centerLeft,
                child: noBack
                    ? const SizedBox()
                    : Transform.translate(
                        offset: const Offset(-4, 0),
                        child: IconBtn(Ic.back, label: 'Back', onTap: s.back),
                      ),
              ),
            ),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: context.c.ink),
              ),
            ),
            SizedBox(
              width: side,
              child: Align(
                alignment: Alignment.centerRight,
                child: Transform.translate(
                  offset: const Offset(4, 0),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [if (r != null) r, if (extra != null) extra]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The bag button with the number of cart lines. With something in the cart and no touch for 5 minutes it
/// shakes gently every few seconds (3 Nov) until the next touch.
///
/// 6 Nov: Search sits next to the cart on every screen, except Search itself and the screens that already carry
/// their own search (Home, Shop with its search bar, Parcel order's lens type, Brands).
class BagBtn extends StatelessWidget {
  final bool cartOnly;
  const BagBtn({super.key, this.cartOnly = false});

  static const ownSearch = {'search', 'home', 'shop', 'lenstype', 'brands'};

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final btn = IconBtn(Ic.bag, label: 'Cart', count: s.cart.length, onTap: s.openCart);
    final cart = s.nudge && s.cartWaiting ? CartNudge(child: btn) : btn;
    if (cartOnly || ownSearch.contains(s.screen)) return cart;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconBtn(Ic.search, label: 'Search', onTap: s.toSearch),
        cart,
      ],
    );
  }
}

/// `@keyframes cnudge`: a short wobble every 2.6 s, swinging from near the top; a still ring when the phone
/// asks for reduced motion.
class CartNudge extends StatefulWidget {
  final Widget child;
  const CartNudge({super.key, required this.child});
  @override
  State<CartNudge> createState() => _CartNudgeState();
}

class _CartNudgeState extends State<CartNudge> with SingleTickerProviderStateMixin {
  late final AnimationController _a = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..repeat();
  static const _k = [(0.0, 0.0), (0.62, 0.0), (0.66, -11.0), (0.72, 9.0), (0.78, -6.0), (0.84, 4.0), (0.90, -2.0), (1.0, 0.0)];
  double _deg(double t) {
    for (var i = 1; i < _k.length; i++) {
      if (t <= _k[i].$1) {
        final (t0, v0) = _k[i - 1];
        final (t1, v1) = _k[i];
        final u = Curves.easeInOut.transform(t1 == t0 ? 1 : (t - t0) / (t1 - t0));
        return v0 + (v1 - v0) * u;
      }
    }
    return 0;
  }

  @override
  void dispose() {
    _a.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    if (MediaQuery.disableAnimationsOf(context)) {
      return DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: c.navy.withValues(alpha: .35), spreadRadius: 4)],
        ),
        child: widget.child,
      );
    }
    return AnimatedBuilder(
      animation: _a,
      builder: (_, child) => Transform.rotate(angle: _deg(_a.value) * 3.1415926535 / 180, alignment: const Alignment(0, -0.6), child: child),
      child: widget.child,
    );
  }
}

class SearchBtn extends StatelessWidget {
  final VoidCallback onTap;
  const SearchBtn({super.key, required this.onTap});
  @override
  Widget build(BuildContext context) => IconBtn(Ic.search, label: 'Search', onTap: onTap);
}

// ---------------------------------------------------------------- cards

/// A card surface with the soft long shadow (`--e1`).
class CardBox extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final Color? color;
  final EdgeInsets margin;
  final bool shadow;
  final Border? border;
  const CardBox({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.radius = 16,
    this.color,
    this.margin = EdgeInsets.zero,
    this.shadow = true,
    this.border,
  });
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(color: color ?? c.card, borderRadius: BorderRadius.circular(radius), boxShadow: shadow ? c.e1 : null, border: border),
      child: child,
    );
  }
}

/// `.row`: thumb, title, subtitle, extra lines and a chevron.
class RowCard extends StatelessWidget {
  final Widget? thumb;
  final String? title;
  final Widget? titleWidget;
  final String? sub;
  final List<Widget> extra;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool dim;
  final bool chevron;
  final Border? border;
  final bool numTitle;
  const RowCard({
    super.key,
    this.thumb,
    this.title,
    this.titleWidget,
    this.sub,
    this.extra = const [],
    this.trailing,
    this.onTap,
    this.dim = false,
    this.chevron = false,
    this.border,
    this.numTitle = false,
  });
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final body = Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
      decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(14), boxShadow: dim ? null : c.e1, border: border),
      child: Row(
        children: [
          if (thumb != null) ...[thumb!, const SizedBox(width: 12)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (titleWidget != null) titleWidget!,
                if (title != null)
                  Text(
                    title!,
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, height: 1.25, color: c.ink, fontFeatures: numTitle ? kTabular : null),
                  ),
                if (sub != null && sub!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(sub!, style: TextStyle(fontSize: 11.5, color: c.ink2, height: 1.35)),
                  ),
                ...extra,
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
          if (chevron) ...[const SizedBox(width: 12), SvgIcon(Ic.chev, size: 18, color: c.mute)],
        ],
      ),
    );
    return Opacity(
      opacity: dim ? .5 : 1,
      child: Pressable(onTap: onTap, child: body),
    );
  }
}

/// `.thumb`
class ThumbBox extends StatelessWidget {
  final Widget child;
  final double w, h;
  const ThumbBox({super.key, required this.child, this.w = 64, this.h = 64});
  @override
  Widget build(BuildContext context) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(color: context.c.sunk, borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        alignment: Alignment.center,
        child: child,
      );
}

class IconThumb extends StatelessWidget {
  final IconDef icon;
  const IconThumb(this.icon, {super.key});
  @override
  Widget build(BuildContext context) => ThumbBox(child: SvgIcon(icon, size: 24, color: context.c.ink2));
}

/// Price line under a row title: "₹1,148 / pair  In stock".
class PriceLineText extends StatelessWidget {
  final String price;
  final String suffix;
  final Widget? tag;
  const PriceLineText({super.key, required this.price, this.suffix = ' / pair', this.tag});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (price.isNotEmpty)
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: price,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.ink, fontFeatures: kTabular),
                  ),
                  if (suffix.isNotEmpty)
                    TextSpan(
                      text: suffix,
                      style: TextStyle(fontSize: 12, color: c.ink2),
                    ),
                ],
              ),
            ),
          if (tag != null) tag!,
        ],
      ),
    );
  }
}

/// `stTag(st)`
class StockTag extends StatelessWidget {
  final StockStatus st;
  final double left;
  const StockTag(this.st, {super.key, this.left = 6});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final col = switch (st.state) {
      'in' when st.low => c.warn,
      'in' => c.good,
      'zero' => c.warn,
      'mto' => c.ink2,
      _ => c.mute,
    };
    return Padding(
      padding: EdgeInsets.only(left: left),
      child: Text(
        st.label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: col),
      ),
    );
  }
}

/// `.flag`: "Different power: check before ordering".
class FlagTag extends StatelessWidget {
  final String text;
  const FlagTag(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 5),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(color: context.c.warnSoft, borderRadius: BorderRadius.circular(6)),
          child: Text(
            text,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: context.c.warn, height: 1.3),
          ),
        ),
      );
}

/// `.note`, `.note.warn`, `.note.bad`
class NoteBox extends StatelessWidget {
  final Widget child;
  final String kind; // '' | warn | bad | card
  final EdgeInsets margin;
  final TextAlign align;
  const NoteBox({super.key, required this.child, this.kind = '', this.margin = const EdgeInsets.only(top: 12), this.align = TextAlign.start});
  factory NoteBox.text(String text, {String kind = '', EdgeInsets margin = const EdgeInsets.only(top: 12)}) =>
      NoteBox(kind: kind, margin: margin, child: Text(text));
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final (bg, fg) = switch (kind) {
      'warn' => (c.warnSoft, c.warn),
      'bad' => (c.badSoft, c.bad),
      'card' => (c.card, c.ink),
      _ => (c.card2, c.ink2),
    };
    return Container(
      width: double.infinity,
      margin: margin,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: DefaultTextStyle.merge(
        textAlign: align,
        style: TextStyle(fontSize: 12.5, color: fg, height: 1.45),
        child: child,
      ),
    );
  }
}

/// `.pill`
class Pill extends StatelessWidget {
  final String text;
  final String kind; // good | warn | bad | n
  const Pill(this.text, {super.key, this.kind = 'n'});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final (bg, fg) = switch (kind) {
      'good' => (c.goodSoft, c.good),
      'warn' => (c.warnSoft, c.warn),
      'bad' => (c.badSoft, c.bad),
      _ => (c.sunk, c.ink2),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(
        text,
        maxLines: 1,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}

/// `.sbtn`: a small outlined pill button.
class SBtn extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  const SBtn(this.text, {super.key, this.onTap, this.padding = const EdgeInsets.symmetric(horizontal: 13, vertical: 7)});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: c.card2,
          border: Border.all(color: c.line),
          borderRadius: BorderRadius.circular(999),
        ),
        alignment: Alignment.center,
        child: Text(text, style: TextStyle(fontSize: 12.5, color: c.ink)),
      ),
    );
  }
}

/// `.tot`: a totals row.
class TotRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool last;
  final Widget? labelWidget;
  const TotRow(this.label, this.value, {super.key, this.valueColor, this.last = false, this.labelWidget});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: last ? null : Border(bottom: BorderSide(color: c.line)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: labelWidget ?? Text(label, style: TextStyle(fontSize: 13.5, color: c.ink)),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: valueColor ?? c.ink, fontFeatures: kTabular),
          ),
        ],
      ),
    );
  }
}

/// Rows of totals where the last has no rule (`.tot:last-child`).
class Tots extends StatelessWidget {
  final List<TotRow> rows;
  const Tots(this.rows, {super.key});
  @override
  Widget build(BuildContext context) => Column(
        children: [
          for (var i = 0; i < rows.length; i++)
            TotRow(rows[i].label, rows[i].value, valueColor: rows[i].valueColor, last: i == rows.length - 1, labelWidget: rows[i].labelWidget),
        ],
      );
}

/// `.empty`
class EmptyState extends StatelessWidget {
  final String title;
  final String text;
  const EmptyState(this.title, this.text, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 10),
        child: Column(
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: kSerif, fontSize: 24, fontWeight: FontWeight.w600, color: context.c.ink),
            ),
            const SizedBox(height: 4),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.c.ink2),
            ),
          ],
        ),
      );
}

/// `.box`
class InfoBox extends StatelessWidget {
  final Widget child;
  final EdgeInsets margin;
  const InfoBox({super.key, required this.child, this.margin = const EdgeInsets.only(top: 14)});
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: margin,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: context.c.card2, borderRadius: BorderRadius.circular(14)),
        child: child,
      );
}

/// `qtyCtl(k, n)`: label on the left, − n + on the right.
/// `qtyCtl(k, n, …)`: − quantity +. Single vision and KT ('H') count in pairs or pieces (30 Oct, the customer's
/// choice, [onUnit]); progressive counts a pair in pairs and one eye in pieces. With [onTyped] the number can be
/// typed (the state rounds it to what can be ordered).
class QtyCtl extends StatelessWidget {
  final String kind;
  final double n;
  final ValueChanged<int> onStep;
  final String unit;
  final ValueChanged<String>? onUnit;
  final ValueChanged<double>? onTyped;
  final String? label;
  final String? sub;
  const QtyCtl({super.key, required this.kind, required this.n, required this.onStep, this.unit = 'pairs', this.onUnit, this.onTyped, this.label, this.sub});
  static const labels = {
    'H': ('Pairs', '0.5 is one lens. Right and left are the same lens.'),
    'P': ('Pairs', 'Same power, one right and one left lens each'),
    'R': ('Pieces', 'Right eye lenses'),
    'L': ('Pieces', 'Left eye lenses'),
  };
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = labels[kind]!;
    final uni = onUnit != null && kind == 'H';
    final mul = uni ? uMul(kind, unit) : 1;
    final shown = uni ? nfmt(n * mul) : qtyNum(n);
    Widget stepBtn(int v, String lab) => Semantics(
          button: true,
          label: lab,
          child: GestureDetector(
            onTap: () => onStep(v),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.card,
                border: Border.all(color: c.line),
              ),
              alignment: Alignment.center,
              child: Icon(
                v > 0 ? Icons.add : Icons.remove,
                size: 18,
                color: c.ink,
              ),
            ),
          ),
        );
    final left = uni
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UnitSwitch(unit: unit, onUnit: onUnit!),
              const SizedBox(height: 4),
              Text(
                isPcs(kind, unit) ? 'One piece is one lens; 2 pieces = 1 pair' : '0.5 is one lens. Right and left are the same lens.',
                style: TextStyle(fontSize: 12, color: c.ink2),
              ),
            ],
          )
        : Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: label ?? l.$1,
                  style: TextStyle(color: c.ink),
                ),
                if ((sub ?? l.$2).isNotEmpty)
                  TextSpan(
                    text: '\n${sub ?? l.$2}',
                    style: TextStyle(fontSize: 12, color: c.ink2),
                  ),
              ],
            ),
          );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: left),
          const SizedBox(width: 8),
          stepBtn(-1, 'fewer'),
          const SizedBox(width: 6),
          if (onTyped != null)
            QtyField(
              key: ValueKey('qin-$kind-$unit-$shown'),
              text: shown,
              label: uni ? (isPcs(kind, unit) ? 'Pieces' : 'Pairs') : l.$1,
              onDone: (v) => onTyped!(v / mul),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 24),
              child: Text(
                shown,
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w600, fontFeatures: kTabular, color: c.ink),
              ),
            ),
          const SizedBox(width: 6),
          stepBtn(1, 'more'),
        ],
      ),
    );
  }
}

/// `.qin`: a typed quantity. Done (or leaving the box) hands the number back.
class QtyField extends StatefulWidget {
  final String text;
  final String label;
  final ValueChanged<double> onDone;
  const QtyField({super.key, required this.text, required this.label, required this.onDone});
  @override
  State<QtyField> createState() => _QtyFieldState();
}

class _QtyFieldState extends State<QtyField> {
  late final TextEditingController _t = TextEditingController(text: widget.text);
  final FocusNode _f = FocusNode();
  @override
  void initState() {
    super.initState();
    _f.addListener(() {
      if (_f.hasFocus) {
        _t.selection = TextSelection(baseOffset: 0, extentOffset: _t.text.length);
      } else {
        _done();
      }
    });
  }

  void _done() {
    final v = double.tryParse(_t.text.replaceAll(',', '.'));
    if (v != null) widget.onDone(v);
  }

  /// 5 Nov: after Done in the power screen's Type sheet, the quantity box takes the keyboard.
  static int _focusHandled = 0;

  @override
  void dispose() {
    _t.dispose();
    _f.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final s = AppScope.of(context);
    if (s.qtyFocusReq > _focusHandled && s.screen == 'rx') {
      _focusHandled = s.qtyFocusReq;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _f.requestFocus();
      });
    }
    return SizedBox(
      width: 56,
      child: TextField(
        controller: _t,
        focusNode: _f,
        textAlign: TextAlign.center,
        textAlignVertical: TextAlignVertical.center,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _f.unfocus(),
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: c.ink, fontFeatures: kTabular),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.zero,
          filled: true,
          fillColor: c.card,
          semanticCounterText: widget.label,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: c.line),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: c.ink, width: 1.5),
          ),
        ),
      ),
    );
  }
}

/// `.usw`: Pairs or Pieces (30 Oct).
class UnitSwitch extends StatelessWidget {
  final String unit;
  final ValueChanged<String> onUnit;
  final String? label;
  const UnitSwitch({super.key, required this.unit, required this.onUnit, this.label});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    Widget opt(String v, String t) {
      final on = unit == v;
      return Semantics(
        inMutuallyExclusiveGroup: true,
        checked: on,
        button: true,
        label: t,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onUnit(v),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: on ? c.ink : c.mute, width: on ? 5.5 : 1.5),
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  t,
                  style: TextStyle(fontSize: 14, color: on ? c.ink : c.ink2, fontWeight: on ? FontWeight.w600 : FontWeight.w400),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 14,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (label != null) Text(label!.toUpperCase(), style: AppText.eyebrow(c).copyWith(fontSize: 11)),
        opt('pairs', 'Pairs'),
        opt('pcs', 'Pieces'),
      ],
    );
  }
}

String qtyNum(double n) => n == n.roundToDouble() ? n.toInt().toString() : n.toString();

/// `.tgl`: a small on/off switch.
class Toggle extends StatelessWidget {
  final bool on;
  final VoidCallback? onTap;
  const Toggle({super.key, required this.on, this.onTap});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 44,
        height: 26,
        decoration: BoxDecoration(color: on ? c.good : c.line, borderRadius: BorderRadius.circular(13)),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 150),
          alignment: on ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.all(3),
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Color(0x40000000), blurRadius: 3, offset: Offset(0, 1))],
            ),
          ),
        ),
      ),
    );
  }
}

/// `.stages`: progress bars for an order's stage.
class Stages extends StatelessWidget {
  final int count;
  final int upTo; // inclusive index, -1 for none
  const Stages({super.key, required this.count, required this.upTo});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Row(
          children: [
            for (var i = 0; i < count; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              Expanded(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(color: i <= upTo ? context.c.ink : context.c.line, borderRadius: BorderRadius.circular(2)),
                ),
              ),
            ],
          ],
        ),
      );
}

/// `.radio` option.
class RadioCard extends StatelessWidget {
  final bool on;
  final Widget child;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showDot;
  const RadioCard({super.key, required this.on, required this.child, this.trailing, this.onTap, this.showDot = true});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: on ? c.ink : c.line, width: on ? 2 : 1),
        ),
        child: Row(
          children: [
            Expanded(child: child),
            if (trailing != null) trailing!,
            if (trailing == null && showDot) RadioDot(on: on, size: 18, onWidth: 5),
          ],
        ),
      ),
    );
  }
}

class RadioDot extends StatelessWidget {
  final bool on;
  final double size;
  final double onWidth;
  const RadioDot({super.key, required this.on, this.size = 20, this.onWidth = 6});
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: on ? context.c.ink : context.c.mute, width: on ? onWidth : 1.5),
        ),
      );
}

/// A field box (`.field`).
class FieldBox extends StatelessWidget {
  final TextEditingController controller;
  final String? hint;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboard;
  final TextStyle? style;
  final TextAlign align;
  final String? label;
  final bool? enabled;
  final bool readOnly;
  const FieldBox({
    super.key,
    required this.controller,
    this.hint,
    this.onChanged,
    this.keyboard,
    this.style,
    this.align = TextAlign.start,
    this.label,
    this.enabled,
    this.readOnly = false,
  });
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Semantics(
      label: label,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        keyboardType: keyboard,
        textAlign: align,
        enabled: enabled,
        readOnly: readOnly,
        style: style ?? TextStyle(fontSize: 14, color: c.ink),
        decoration: InputDecoration(
          isDense: true,
          hintText: hint,
          hintStyle: TextStyle(color: c.mute),
          filled: true,
          fillColor: c.card,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: c.line),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: c.ink, width: 1.5),
          ),
        ),
      ),
    );
  }
}

/// A text field that keeps its own controller across rebuilds and reports changes.
class StateField extends StatefulWidget {
  final String initial;
  final String? hint;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboard;
  final TextStyle? style;
  final TextAlign align;
  final String? label;
  const StateField({super.key, required this.initial, required this.onChanged, this.hint, this.keyboard, this.style, this.align = TextAlign.start, this.label});
  @override
  State<StateField> createState() => _StateFieldState();
}

class _StateFieldState extends State<StateField> {
  late final TextEditingController _c = TextEditingController(text: widget.initial);
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FieldBox(
        controller: _c,
        hint: widget.hint,
        onChanged: widget.onChanged,
        keyboard: widget.keyboard,
        style: widget.style,
        align: widget.align,
        label: widget.label,
      );
}

/// `.search`: a rounded search box.
class SearchBox extends StatefulWidget {
  final String initial;
  final String hint;
  final ValueChanged<String> onChanged;
  final bool autofocus;
  const SearchBox({super.key, required this.initial, required this.hint, required this.onChanged, this.autofocus = false});
  @override
  State<SearchBox> createState() => _SearchBoxState();
}

class _SearchBoxState extends State<SearchBox> {
  late final TextEditingController _c = TextEditingController(text: widget.initial);
  @override
  void didUpdateWidget(SearchBox old) {
    super.didUpdateWidget(old);
    if (widget.initial != _c.text && widget.initial != old.initial) {
      _c.value = TextEditingValue(
        text: widget.initial,
        selection: TextSelection.collapsed(offset: widget.initial.length),
      );
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: c.card,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          SvgIcon(Ic.search, size: 18, color: c.mute),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _c,
              autofocus: widget.autofocus,
              onChanged: widget.onChanged,
              style: TextStyle(fontSize: 14, color: c.ink),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: widget.hint,
                hintStyle: TextStyle(color: c.mute),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Column with a fixed gap between children (`display:grid; gap:10px`).
class Gap extends StatelessWidget {
  final List<Widget> children;
  final double gap;
  final CrossAxisAlignment cross;
  const Gap(this.children, {super.key, this.gap = 10, this.cross = CrossAxisAlignment.stretch});
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: cross,
        children: [
          for (var i = 0; i < children.length; i++) ...[if (i > 0) SizedBox(height: gap), children[i]],
        ],
      );
}

/// Power text helpers used by several screens.
String eyePowers(Rx r, Rx? l, String lt, {String both = 'R and L '}) => l != null ? 'R ${powerTxt(r, lt)} · L ${powerTxt(l, lt)}' : '$both${powerTxt(r, lt)}';

String pairsWord(double n) => '${qtyNum(n)} pair${n == 1 ? '' : 's'}';

String lineQty(CartLine c) => lineQtyTxt(c);
