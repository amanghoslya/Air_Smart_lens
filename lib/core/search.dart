/// Lens search with the trade's short forms (6 Nov 2026), as the prototype's `lensTags` / `lensMatch`.
///
/// Each lens gets tags from its name, base and coating; a short form in the query matches its tag as a whole word,
/// so PC never matches inside another word and HC never finds HMC.
///
///   BC / BRC  blue cut          PC  poly                 PG  photogray
///   HC        hard coat         V2 / prog  progressive   LRB low reflection blue
///   O2 / DC   double coating (taken as HMC, to confirm)  BBC blue cut with a blue coating
///
/// Every other word must appear somewhere in the lens's text, in any order ("air smart 1.60", "pg bc 1.56").
library;

import 'format.dart';
import 'models.dart';

const abbr = {
  'bc': 'bc', 'brc': 'bc', 'pc': 'pc', 'pg': 'pg', 'hc': 'hc', 'v2': 'prog', 'prog': 'prog', //
  'lrb': 'lrb', 'o2': 'dc', 'dc': 'dc', 'bbc': 'bbc',
};
const tagWords = {
  'bc': 'blue cut bluecut',
  'pc': 'poly polycarbonate',
  'pg': 'photogray photogrey photo grey photochromic',
  'hc': 'hard coat hardcoat hard coating',
  'prog': 'progressive',
  'lrb': 'low reflection blue',
  'dc': 'double coating double coat',
  'bbc': 'blue cut blue coating',
};

/// `lensTags(p)`: bc, pc, pg, hc, prog, lrb, dc, bbc.
List<String> lensTags(Product p) {
  final n = '${p.name} ${p.base} ${p.coating}'.toUpperCase();
  final t = <String>[];
  final bc = RegExp('BLUE CUT|BLUE FILTER').hasMatch(n);
  if (bc) t.add('bc');
  if (n.contains('POLY')) t.add('pc');
  if (RegExp(r'PHOTO GREY|\bPG\b').hasMatch(n)) t.add('pg');
  if (p.coating == 'HC' || RegExp(r'HARD COAT|\bHC\b').hasMatch(n)) t.add('hc');
  if (p.ptype == 'PROG') t.add('prog');
  if (RegExp('LRB|LOW REFLECTION').hasMatch(n)) t.add('lrb');
  if (p.coating == 'HMC') t.add('dc');
  if (bc && RegExp('DARK BLUE|CRYSTAL BLUE|OPAL|LRB').hasMatch(n)) t.add('bbc');
  return t;
}

String _typeWords(Product p) => p.ptype == 'SV'
    ? 'single vision sv'
    : p.ptype == 'KT'
    ? 'kt bifocal'
    : '';

/// The lowercase text a query is matched against, as the prototype's `lensText(p)`.
String lensText(Product p) {
  final t = lensTags(p);
  final s =
      ' ${[p.name, p.brand, p.coating, p.base, p.index, coatShort(p), _typeWords(p), p.lines.map((l) => l.range).join(' '), t.map((x) => '#$x ${tagWords[x]}').join(' ')].join(' ')} ';
  return s.toLowerCase().replaceAll(RegExp(r'[(),+]'), ' ').replaceAll(RegExp(r'\s+'), ' ');
}

/// `lensMatch(p, q)`: does the lens match every word of the query?
bool lensMatch(Product p, String q) {
  final t = lensText(p);
  final words = q.toLowerCase().replaceAll('−', '-').split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
  return words.every((w) => abbr.containsKey(w) ? t.contains(' #${abbr[w]} ') : t.contains(w));
}
