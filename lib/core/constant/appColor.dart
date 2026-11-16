import 'package:flutter/material.dart';

/// Colour tokens from the HTML app's :root (light) and dark blocks.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Color paper, card, card2, sunk, ink, ink2, mute, line, navy, onNavy;
  final Color good,
      goodSoft,
      warn,
      warnSoft,
      bad,
      badSoft,
      scrim,
      shade,
      raised;
  final Color glass, glass2, glassEdge, glassLine;
  final bool dark;

  const AppColors({
    required this.paper,
    required this.card,
    required this.card2,
    required this.sunk,
    required this.ink,
    required this.ink2,
    required this.mute,
    required this.line,
    required this.navy,
    required this.onNavy,
    required this.good,
    required this.goodSoft,
    required this.warn,
    required this.warnSoft,
    required this.bad,
    required this.badSoft,
    required this.scrim,
    required this.shade,
    required this.raised,
    required this.glass,
    required this.glass2,
    required this.glassEdge,
    required this.glassLine,
    required this.dark,
  });

  static const light = AppColors(
    paper: Color(0xFFF2EFE9),
    card: Color(0xFFFFFFFF),
    card2: Color(0xFFF7F5F0),
    sunk: Color(0xFFECE8E0),
    ink: Color(0xFF1B2130),
    ink2: Color(0xFF5D6370),
    mute: Color(0xFF989CA4),
    line: Color(0xFFE4DFD6),
    navy: Color(0xFF1D2433),
    onNavy: Color(0xFFFFFFFF),
    good: Color(0xFF3E7A57),
    goodSoft: Color(0xFFE3EFE6),
    warn: Color(0xFF9A6A1C),
    warnSoft: Color(0xFFF5EBD8),
    bad: Color(0xFFA3453E),
    badSoft: Color(0xFFF4E1DE),
    scrim: Color(0x6114161C), // rgba(20,22,28,.38)
    shade: Color(0x1A1B2130), // rgba(27,33,48,.10)
    raised: Color(0xFFFFFFFF),
    glass: Color(0xA8FFFFFF),
    glass2: Color(0xCCFFFFFF),
    glassEdge: Color(0xBFFFFFFF),
    glassLine: Color(0x121B2130),
    dark: false,
  );

  static const darkTheme = AppColors(
    paper: Color(0xFF121419),
    card: Color(0xFF1B1E25),
    card2: Color(0xFF22262E),
    sunk: Color(0xFF2A2E37),
    ink: Color(0xFFEEEBE5),
    ink2: Color(0xFFB5B8BF),
    mute: Color(0xFF80858F),
    line: Color(0xFF30343D),
    navy: Color(0xFFECE7DD),
    onNavy: Color(0xFF1B2130),
    good: Color(0xFF7FC29B),
    goodSoft: Color(0xFF1F3128),
    warn: Color(0xFFD9AE63),
    warnSoft: Color(0xFF382D1A),
    bad: Color(0xFFE39089),
    badSoft: Color(0xFF3A2220),
    scrim: Color(0x8C000000),
    shade: Color(0x59000000),
    raised: Color(0xFF23272F),
    glass: Color(0x9E1B1E25),
    glass2: Color(0xC723272F),
    glassEdge: Color(0x12FFFFFF),
    glassLine: Color(0x0FFFFFFF),
    dark: true,
  );

  /// `--e1`: hairline contact shadow plus a wide, faint fall-off.
  List<BoxShadow> get e1 => dark
      ? const [
          BoxShadow(color: Color(0x09FFFFFF), spreadRadius: 1),
          BoxShadow(
            color: Color(0x4D000000),
            offset: Offset(0, 1),
            blurRadius: 2,
          ),
          BoxShadow(
            color: Color(0x99000000),
            offset: Offset(0, 12),
            blurRadius: 30,
            spreadRadius: -14,
          ),
        ]
      : const [
          BoxShadow(color: Color(0x091B2130), spreadRadius: 1),
          BoxShadow(
            color: Color(0x0A1B2130),
            offset: Offset(0, 1),
            blurRadius: 2,
          ),
          BoxShadow(
            color: Color(0x291B2130),
            offset: Offset(0, 10),
            blurRadius: 28,
            spreadRadius: -14,
          ),
        ];

  /// `--e2`: raised sheets.
  List<BoxShadow> get e2 => dark
      ? const [
          BoxShadow(
            color: Color(0xBF000000),
            offset: Offset(0, -22),
            blurRadius: 64,
            spreadRadius: -18,
          ),
        ]
      : const [
          BoxShadow(
            color: Color(0x4D1B2130),
            offset: Offset(0, -20),
            blurRadius: 60,
            spreadRadius: -18,
          ),
        ];

  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) =>
      t < 0.5 ? this : (other as AppColors? ?? this);
}

const kSans = 'DMSans';
const kSerif = 'CormorantGaramond';
const kTabular = [FontFeature.tabularFigures()];

extension AppThemeX on BuildContext {
  AppColors get c => Theme.of(this).extension<AppColors>()!;
}

ThemeData buildTheme(AppColors c) {
  final base = ThemeData(
    useMaterial3: true,
    brightness: c.dark ? Brightness.dark : Brightness.light,
    fontFamily: kSans,
    scaffoldBackgroundColor: c.paper,
    colorScheme: ColorScheme.fromSeed(
      seedColor: c.navy,
      brightness: c.dark ? Brightness.dark : Brightness.light,
      surface: c.card,
      primary: c.navy,
      onPrimary: c.onNavy,
    ),
    splashFactory: InkRipple.splashFactory,
    extensions: [c],
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: c.ink,
      displayColor: c.ink,
      fontFamily: kSans,
    ),
    textSelectionTheme: TextSelectionThemeData(cursorColor: c.ink),
  );
}

/// Type scale from the CSS (font sizes in logical pixels).
class AppText {
  static TextStyle display(AppColors c) => TextStyle(
    fontFamily: kSerif,
    fontWeight: FontWeight.w600,
    fontSize: 31,
    height: 1.04,
    color: c.ink,
    letterSpacing: -0.15,
  );
  static TextStyle eyebrow(AppColors c) => TextStyle(
    fontSize: 11,
    letterSpacing: 11 * .14,
    fontWeight: FontWeight.w600,
    color: c.mute,
  );
  static TextStyle body(AppColors c) =>
      TextStyle(fontSize: 14, height: 1.45, color: c.ink);
  static TextStyle small(AppColors c, {Color? color}) =>
      TextStyle(fontSize: 12, height: 1.45, color: color ?? c.ink2);
  static TextStyle h(AppColors c) =>
      TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.ink);
}
