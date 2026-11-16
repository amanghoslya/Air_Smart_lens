import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/app_scope.dart';
import '../state/app_state.dart';
import 'drawer.dart';
import 'icons.dart';
import 'lens3d.dart';
import '../Screens/registry.dart';
import 'theme.dart';
import 'widgets.dart';

/// What a screen draws: its blocks (each padded 18 px unless [Bleed]), and the
/// optional footer bar of buttons.
class ScreenView {
  final List<Widget> blocks;
  final Widget? foot;
  final bool bleed; // the whole screen runs edge to edge (welcome)
  final bool scroll;
  const ScreenView(this.blocks, {this.foot, this.bleed = false, this.scroll = true});
}

/// The app frame: current screen, footer, floating tab bar, toast, loader,
/// side menu.
class AppShell extends StatelessWidget {
  const AppShell({super.key});

  static const tabH = 66.0;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = context.c;
    final tab = AppState.tabFor(s.screen);
    final view = buildScreen(context, s);

    Widget body;
    if (view.bleed) {
      body = view.blocks.first;
    } else {
      final children = [
        for (final b in view.blocks) b is Bleed || (b is Strip && b.bleed) ? b : Padding(padding: const EdgeInsets.symmetric(horizontal: 18), child: b),
      ];
      final safeBottom = MediaQuery.paddingOf(context).bottom;
      body = view.scroll
          ? ListView(
              key: PageStorageKey('${s.screen}#${s.viewEpoch}'),
              padding: EdgeInsets.only(top: 4, bottom: 22 + (tab != null ? tabH + safeBottom : (view.foot == null ? safeBottom : 0))),
              children: children,
            )
          : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
    }

    final darkIcons = !c.dark && !view.bleed;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: (darkIcons ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light).copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: c.paper,
        systemNavigationBarIconBrightness: c.dark ? Brightness.light : Brightness.dark,
      ),
      child: Listener(
        // 3 Nov: any touch counts as activity (stops the cart nudge, starts its 5 minutes again)
        onPointerDown: (_) => s.activity(),
        behavior: HitTestBehavior.translucent,
        child: PopScope(
          canPop: s.screen == 'welcome' || (s.screen == 'home' && s.hist.isEmpty),
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            if (s.drawerOpen) {
              s.closeDrawer();
            } else if (s.loader == null) {
              s.back();
            }
          },
          child: Scaffold(
            backgroundColor: c.paper,
            resizeToAvoidBottomInset: true,
            body: Stack(
              children: [
                Positioned.fill(
                  child: SafeArea(
                    top: !view.bleed,
                    bottom: false,
                    child: Column(
                      children: [
                        Expanded(
                          child: KeyedSubtree(key: ValueKey('${s.screen}#${s.viewEpoch}'), child: body),
                        ),
                        if (view.foot != null)
                          Container(
                            color: c.paper,
                            padding: EdgeInsets.fromLTRB(18, 10, 18, 14 + (tab == null ? MediaQuery.paddingOf(context).bottom : 0)),
                            margin: EdgeInsets.only(bottom: tab != null ? tabH + MediaQuery.paddingOf(context).bottom : 0),
                            child: Row(children: [view.foot!]),
                          ),
                      ],
                    ),
                  ),
                ),
                if (tab != null) Positioned(left: 0, right: 0, bottom: 0, child: _TabBar(active: tab)),
                if (s.toastMsg != null)
                  Positioned(
                    left: 18,
                    right: 18,
                    bottom: (tab != null ? tabH + 12 : 16) + MediaQuery.paddingOf(context).bottom,
                    child: _Toast(key: ValueKey(s.toastId), text: s.toastMsg!),
                  ),
                const Positioned.fill(child: ConfettiLayer()),
                if (s.loader != null) Positioned.fill(child: _Loader(text: s.loader!.text)),
                const Positioned.fill(child: SideMenu()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  final String active;
  const _TabBar({required this.active});
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = context.c;
    const tabs = [('home', 'Home', Ic.home), ('shop', 'Shop', Ic.bag), ('orders', 'Orders', Ic.orders), ('account', 'Account', Ic.account)];
    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          decoration: BoxDecoration(
            color: c.glass,
            border: Border(top: BorderSide(color: c.glassLine)),
          ),
          padding: EdgeInsets.fromLTRB(10, 8, 10, 14 + MediaQuery.paddingOf(context).bottom),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (final t in tabs)
                Semantics(
                  button: true,
                  selected: active == t.$1,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => s.tab(t.$1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SvgIcon(t.$3, size: 21, color: active == t.$1 ? c.ink : c.mute),
                          const SizedBox(height: 3),
                          Text(
                            s.tr(t.$2),
                            style: TextStyle(
                              fontSize: 11,
                              color: active == t.$1 ? c.ink : c.mute,
                              fontWeight: active == t.$1 ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
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

class _Toast extends StatelessWidget {
  final String text;
  const _Toast({super.key, required this.text});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Semantics(
      liveRegion: true,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: c.navy,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: c.shade, blurRadius: 40, offset: const Offset(0, 18), spreadRadius: -14)],
          ),
          child: Text(text, style: TextStyle(fontSize: 13, color: c.onNavy)),
        ),
      ),
    );
  }
}

/// The loader: the glass lens spinning over a soft paper veil, with one line
/// saying what is happening. In the real app it shows only while waiting for the server.
class _Loader extends StatefulWidget {
  final String text;
  const _Loader({required this.text});
  @override
  State<_Loader> createState() => _LoaderState();
}

class _LoaderState extends State<_Loader> with SingleTickerProviderStateMixin {
  late final AnimationController _dots = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  @override
  void dispose() {
    _dots.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final reduced = MediaQuery.of(context).disableAnimations;
    return Semantics(
      liveRegion: true,
      label: widget.text,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 180),
        builder: (context, o, child) => Opacity(opacity: o, child: child),
        child: ClipRect(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 3, sigmaY: 3),
            child: Container(
              color: c.paper.withValues(alpha: .88),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const LoaderLens(),
                  const SizedBox(height: 4),
                  AnimatedBuilder(
                    animation: _dots,
                    builder: (context, _) {
                      final n = reduced ? -1 : (_dots.value * 4).floor() % 4;
                      final dots = n < 0 ? '…' : '.' * n;
                      return Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: widget.text),
                            TextSpan(text: dots.padRight(3, ' ')),
                          ],
                        ),
                        style: TextStyle(fontSize: 13, color: c.ink2, letterSpacing: .13),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
