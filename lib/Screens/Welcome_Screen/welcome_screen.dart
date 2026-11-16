import 'package:flutter/material.dart';

import '../../state/app_scope.dart';
import '../../state/app_state.dart';
import '../../ui/shell.dart';
import '../../ui/theme.dart';

/// ScreenView builder for the welcome screen used in the screen registry.
ScreenView welcomeScreen(BuildContext context, AppState s) => ScreenView([
  WelcomeScreen(s: s),
], bleed: true);

class WelcomeScreen extends StatefulWidget {
  final AppState? s;

  const WelcomeScreen({super.key, this.s});

  static ScreenView view(BuildContext context, AppState s) => welcomeScreen(context, s);

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  Widget build(BuildContext context) {
    final s = widget.s ?? AppScope.of(context);

    return Semantics(
      button: true,
      label: 'VeriWide Optical: a clearer tomorrow for everyone. Tap to start.',
      child: GestureDetector(
        onTap: s.toLogin,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Solid base background color while image is decoding
            const Positioned.fill(
              child: ColoredBox(color: Color(0xFF2A2622)),
            ),

            // Background clean image (text-free portrait)
            Positioned.fill(
              child: Image.asset(
                'assets/images/brand/welcome_bg.jpg',
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                alignment: Alignment.center,
                errorBuilder: (context, error, stackTrace) {
                  return Image.asset(
                    'assets/images/brand/welcome_full.jpg',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    alignment: Alignment.center,
                    errorBuilder: (ctx, err, st) => const SizedBox(),
                  );
                },
              ),
            ),

            // Gradient overlays for contrast and readability over the clean photo
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: const Alignment(0, -0.2),
                    colors: [
                      Colors.black.withValues(alpha: 0.45),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: const Alignment(0, 0.15),
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.55),
                      Colors.black.withValues(alpha: 0.8),
                    ],
                  ),
                ),
              ),
            ),

            // Top Header: VeriWide OPTICAL
            SafeArea(
              child: Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 26,
                    vertical: 22,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'VeriWide',
                        style: TextStyle(
                          fontFamily: kSerif,
                          fontSize: 44,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                          height: 1.0,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'OPTICAL',
                        style: TextStyle(
                          fontFamily: kSans,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.85),
                          letterSpacing: 5.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Content: Title, subtitle and arrow button
            SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(26, 0, 26, 30),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Text Column
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'A clearer\ntomorrow\nfor everyone',
                              style: TextStyle(
                                fontFamily: kSerif,
                                fontSize: 38,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Premium lenses.\nGlobal vision.',
                              style: TextStyle(
                                fontFamily: kSans,
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: Colors.white.withValues(alpha: 0.85),
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Circular action button
                      Material(
                        color: Colors.white,
                        shape: const CircleBorder(),
                        elevation: 6,
                        shadowColor: const Color(0x66000000),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: s.toLogin,
                          child: const SizedBox(
                            width: 60,
                            height: 60,
                            child: Icon(
                              Icons.arrow_forward,
                              color: Color(0xFF1B2130),
                              size: 26,
                            ),
                          ),
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
    );
  }
}
