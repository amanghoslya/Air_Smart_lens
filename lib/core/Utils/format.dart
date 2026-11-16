/// Text formatting shared by every screen: powers, money, names and codes.
library;

import '../Data/Model/brands.dart';
import 'js_compat.dart';
import '../Data/Model/models.dart';

const minus = '−';

/// A power with its sign and two decimals, using the true minus sign: −2.00, +1.25, 0.00.
String fmt(num v) =>
    (v > 0
        ? '+'
        : v < 0
        ? minus
        : '') +
    v.abs().toStringAsFixed(2);

/// Price-file codes are written with hyphens; show the true minus sign.
String rg(String? s) => (s ?? '').replaceAll('-', minus);

/// Indian rupees with Indian digit grouping: ₹2,47,968.
String money(num n) => '₹${indianGroup(jsRound(n))}';

String indianGroup(int n) {
  final neg = n < 0;
  var s = n.abs().toString();
  if (s.length > 3) {
    final last3 = s.substring(s.length - 3);
    var rest = s.substring(0, s.length - 3);
    final parts = <String>[];
    while (rest.length > 2) {
      parts.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) parts.insert(0, rest);
    s = '${parts.join(',')},$last3';
  }
  return neg ? '-$s' : s;
}

/// `titlecase` in the HTML app: lower-case, then capitalise each word start.
String titlecase(String s) => s.toLowerCase().replaceAllMapped(RegExp(r'\b\w'), (m) => m.group(0)!.toUpperCase());

String coatShort(Product p) {
  final c = p.coating.split('(').first.trim();
  if (c.isEmpty || RegExp(r'^(HC|NONE)$', caseSensitive: false).hasMatch(c)) return 'Hard coat';
  if (RegExp(r'^HMC$', caseSensitive: false).hasMatch(c)) return 'HMC';
  if (RegExp(r'^UNCOATED$', caseSensitive: false).hasMatch(c)) return 'Uncoated';
  return titlecase(c).replaceAll('Kopperx', 'Kopper X');
}

/// Brand titles: the HTML app renamed "Kopperx" to "Kopper X" everywhere.
String brandTitle(String brand) => titlecase(brand).replaceAll('Kopperx', 'Kopper X');

/// "Air Smart · Green 1.60", plus the variant from the price file ("· Photo grey, Poly").
String shortName(Product p) => '${bname(p.brand)} · ${coatShort(p)} ${p.index}${p.variant.isNotEmpty ? ' · ${p.variant}' : ''}';

String coatKey(Product p) {
  var c = p.coating.split('(').first.trim().toUpperCase();
  if (c.isEmpty || c == 'NONE') c = 'HC';
  return c;
}

const coatColorHex = <String, int>{
  'GREEN': 0xFF4C8A3F,
  'OPAL': 0xFF4C7DB8,
  'DARK BLUE': 0xFF2B3E8C,
  'VOLT': 0xFF2B3E8C,
  'SHINE': 0xFF3C9A8C,
  'BLUE-GREEN': 0xFF3C9A8C,
  'KOPPERX': 0xFFB5651D,
  'SOLARA GOLD': 0xFFC9A227,
  'CRYSTAL BLUE': 0xFF7DB7E8,
  'HC': 0xFFC9CFCC,
  'HMC': 0xFFAEB8C4,
  'UNCOATED': 0xFFE2E5E4,
};

String coatName(String k) => k == 'HC'
    ? 'Plain hard coat'
    : k.startsWith('OPAL')
    ? 'Opal low reflection'
    : k.startsWith('SHINE')
    ? 'Shine'
    : titlecase(k);

/// "-6.00-2.00" -> "−6−2"
String prettyCode(String r) => r.replaceAll('.00', '').replaceAllMapped(RegExp(r'\.(?=\D|$)'), (_) => '').replaceAll('-', minus);

const indexNames = <String, String>{'1.56': 'Standard', '1.59': 'Polycarbonate', '1.60': 'Thin', '1.61': 'Thin', '1.67': 'Ultra thin', '1.74': 'Thinnest'};

/// "−2.00 / −0.50 × 90° · ADD +2.00"
String powerTxt(Rx x, String lt) =>
    fmt(x.sph) +
    (x.cyl != 0 ? ' / ${fmt(x.cyl)}' : '') +
    (lt != LensType.sv && x.cyl != 0 ? ' × ${x.axis}°' : '') +
    (lt != LensType.sv ? ' · ADD ${fmt(x.add)}' : '');

/// Field value as shown on the power table and wheels.
String fieldValue(String f, num v) => f == 'axis' ? '${v.round()}°' : fmt(v);

/// "4:35 pm"
String hhmm(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final m = d.minute.toString().padLeft(2, '0');
  return '$h:$m ${d.hour < 12 ? 'am' : 'pm'}';
}
