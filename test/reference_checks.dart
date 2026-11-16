// The Dart business logic against results produced by the HTML prototype's own JavaScript
// (test/fixtures/js_reference.json, made by tool/reference_check/export.js). Pure Dart: used by
// tool/verify_logic.dart (no device needed) and test/logic_test.dart.
import 'dart:convert';
import 'dart:io';

import 'package:air_smart_lens/core/catalog_data.dart';
import 'package:air_smart_lens/core/format.dart';
import 'package:air_smart_lens/core/js_compat.dart';
import 'package:air_smart_lens/core/logic.dart';
import 'package:air_smart_lens/core/models.dart';
import 'package:air_smart_lens/core/search.dart';
import 'package:air_smart_lens/core/stock.dart';
import 'package:air_smart_lens/services/qr_label.dart';

LensLogic loadLogic() {
  final data = CatalogData.parse(
    catalogJson: File('assets/data/catalog.json').readAsStringSync(),
    superMastersJson: File('assets/data/super_masters.json').readAsStringSync(),
    accountJson: File('assets/data/simulated_account.json').readAsStringSync(),
  );
  return LensLogic(catalog: data.catalog, superMasters: data.superMasters, stock: StockService(), customer: data.customer);
}

Rx rxOf(Map j) => Rx.fromJson(j.cast<String, dynamic>());

/// Every check against test/fixtures/js_reference.json. Returns the number of checks and what failed.
({int checks, List<String> fails, int matchLines}) runReferenceChecks() {
  final v = jsonDecode(File('test/fixtures/js_reference.json').readAsStringSync()) as Map<String, dynamic>;
  final logic = loadLogic();
  var checks = 0;
  final fails = <String>[];
  void check(bool ok, String what) {
    checks++;
    if (!ok) fails.add(what);
  }

  for (final h in v['hash'] as List) {
    check((jsHash(h[0] as String) - (h[1] as num)).abs() < 1e-12, 'hash ${h[0]}');
  }
  for (final m in v['money'] as List) {
    check(money(m[0] as num) == m[1], 'money ${m[0]} -> ${money(m[0] as num)} (want ${m[1]})');
  }
  for (final c in v['codes'] as List) {
    final got = rangeCode((c[0] as num).toDouble(), (c[1] as num).toDouble());
    check(got == c[2], 'rangeCode ${c[0]} ${c[1]} -> $got (want ${c[2]})');
  }
  for (final g in v['grids'] as List) {
    final p = logic.product(g['pid'] as int);
    final gr = logic.lineGrid(p, g['li'] as int);
    final rows = gr.rows.map((r) => [r.key, r.label]).toList();
    final want = (g['rows'] as List).map((r) => [r[0], r[1]]).toList();
    final cells = gr.cells.toList()..sort();
    final ok =
        gr.isAdd == g['isAdd'] &&
        jsonEncode(rows) == jsonEncode(want) &&
        jsonEncode(gr.cols.map(jsNum).toList()) == jsonEncode((g['cols'] as List).map((e) => jsNum(e as num)).toList()) &&
        jsonEncode(cells) == jsonEncode(g['cells']) &&
        gr.sm == g['sm'] &&
        gr.smt == g['smt'];
    check(ok, 'grid ${g['pid']}:${g['li']}');
  }
  var matchLines = 0;
  for (final m in v['match'] as List) {
    final rx = rxOf(m['rx'] as Map);
    final rxL = m['rxL'] == null ? null : rxOf(m['rxL'] as Map);
    final res = logic.matchProducts(m['lt'] as String, rx, rxL);
    final got = res.map((x) {
      final a = <Object?>[x.p.id, x.li, x.liL, x.uR.sph, x.uR.cyl, x.uR.axis, x.uR.add, x.diff, x.mto];
      if (rxL != null) a.addAll([x.uL?.sph, x.uL?.cyl]);
      return a;
    }).toList();
    String norm(List l) => jsonEncode(l.map((r) => (r as List).map((e) => e is num ? jsNum(e) : e).toList()).toList());
    matchLines += res.length;
    check(norm(got) == norm(m['res'] as List), 'match ${m['lt']} ${jsonEncode(m['rx'])} ${m['rxL'] ?? ''}');
    final code = logic.rxCode(res, rx, rxL);
    check(code == m['code'], 'code ${m['lt']} ${jsonEncode(m['rx'])} -> $code (want ${m['code']})');
  }
  for (final s in v['sentences'] as List) {
    final j = s[0] as Map;
    final c = CartLine(
      kind: j['kind'] as String,
      pid: j['pid'] as int,
      li: j['li'] as int,
      liL: j['liL'] as int?,
      qR: (j['qR'] as num).toDouble(),
      qL: (j['qL'] as num).toDouble(),
      qty: (j['qty'] as num).toDouble(),
      price: (j['price'] as num).toDouble(),
      rx: rxOf(j['rx'] as Map),
      rxL: j['rxL'] == null ? null : rxOf(j['rxL'] as Map),
      diff: j['diff'] == true,
    );
    final got = logic.sentence(c);
    check(got == s[1], 'sentence -> $got\n   want ${s[1]}');
    // Rebuild the same line through makeLine and compare price/qty.
  }
  final meta = jsonDecode(File('assets/data/catalog.json').readAsStringSync())['meta'] as Map;
  for (final f in v['fill'] as List) {
    final got = logic.fillPast(f[0] as String, meta['repeat'] as int, 0).map((k, v) => MapEntry(k, jsNum(v)));
    final want = (f[1] as Map).map((k, v) => MapEntry(k as String, jsNum(v as num)));
    check(jsonEncode(got) == jsonEncode(want), 'fillPast ${f[0]}');
  }

  // ---- 30 Oct to 3 Nov: stock per power, N/A alternatives, QR codes, scanning, Shop by range, prices ----
  for (final x in v['cells'] as List) {
    final st = logic.stock.cellStock(logic.product(x[0] as int), x[1] as int, x[2] as String);
    check(
      st.state == x[3] && st.low == x[4] && (x[5] == null || st.qty == x[5]) && (st.eta ?? '') == x[6],
      'cellStock ${x.take(3).join(':')} -> ${st.state} ${st.low} ${st.qty} ${st.eta} (want ${x.skip(3).join(' ')})',
    );
  }
  final matchCache = <String, List<Match>>{};
  List<Match> matchesOf(Map x) {
    final rx = rxOf(x['rx'] as Map), rxL = x['rxL'] == null ? null : rxOf(x['rxL'] as Map);
    return matchCache.putIfAbsent('${x['lt']}${jsonEncode(x['rx'])}${jsonEncode(x['rxL'])}', () => logic.matchProducts(x['lt'] as String, rx, rxL));
  }

  for (final x in (v['pow'] as List).cast<Map>()) {
    final m = matchesOf(x)[x['i'] as int];
    final ps = logic.powStock(m);
    check(logic.cellKey(m.p, m.li, m.uR) == x['key'], 'cellKey ${x['lt']} ${jsonEncode(x['rx'])} #${x['i']}');
    check(ps.state == x['state'] && ps.low == x['low'] && (ps.eta ?? '') == x['eta'], 'powStock ${x['lt']} ${jsonEncode(x['rx'])} #${x['i']} -> ${ps.state}');
  }
  for (final x in (v['na'] as List).cast<Map>()) {
    final got = logic.naAlts(matchesOf(x)[x['i'] as int]).map((a) => {'sph': jsNum(a.rx.sph), 'cyl': jsNum(a.rx.cyl), 'label': a.label, 'low': a.low}).toList();
    final want = (x['alts'] as List).map((a) => {'sph': jsNum(a['sph'] as num), 'cyl': jsNum(a['cyl'] as num), 'label': a['label'], 'low': a['low']}).toList();
    check(jsonEncode(got) == jsonEncode(want), 'naAlts ${x['lt']} ${jsonEncode(x['rx'])} #${x['i']} -> $got (want $want)');
  }
  for (final x in (v['qr'] as List).cast<Map>()) {
    final m = matchesOf(x)[x['i'] as int];
    final got = logic.qrCodeFor(m.p, m.li, m.uR, x['eye'] as String, liL: m.liL, uL: m.uL);
    check(got == x['code'], 'qrCodeFor -> $got (want ${x['code']})');
  }
  for (final x in (v['scan'] as List).cast<Map>()) {
    final r = logic.parseScan(x['code'] as String);
    if (x['err'] != null) {
      check(r.err == x['err'], 'parseScan ${x['code']} -> ${r.err} (want ${x['err']})');
    } else {
      final ok =
          r.ok &&
          r.p!.id == x['pid'] &&
          r.eye == x['eye'] &&
          r.li == x['li'] &&
          r.liL == x['liL'] &&
          jsonEncode(r.rx!.toJson()) == jsonEncode(rxOf(x['rx'] as Map).toJson()) &&
          jsonEncode(r.rxL?.toJson()) == jsonEncode(x['rxL'] == null ? null : rxOf(x['rxL'] as Map).toJson());
      check(ok, 'parseScan ${x['code']} -> ${r.err ?? 'ok'}');
    }
  }
  for (final x in v['qrm'] as List) {
    final got = qrMatrix(x[0] as String).map((r) => r.map((b) => b ? '1' : '0').join()).join('/');
    check(got == x[1], 'QR modules of ${x[0]}');
  }
  for (final t in (v['ranges'] as Map).keys) {
    final got = logic.rangeIndex(t).map((r) => [r.code, r.group, r.items.length, r.from]).toList();
    check(jsonEncode(got) == jsonEncode(v['ranges'][t]), 'rangeIndex $t (${got.length} ranges, want ${(v['ranges'][t] as List).length})');
  }
  for (final x in v['price'] as List) {
    final p = logic.product(x[0] as int);
    check(logic.fromPrice(p) == x[1], 'fromPrice ${p.id} -> ${logic.fromPrice(p)} (want ${x[1]})');
    final pp = [for (var li = 0; li < p.lines.length; li++) logic.pairPrice(p, li, li)];
    check(jsonEncode(pp) == jsonEncode(x[2]), 'pairPrice ${p.id} -> $pp (want ${x[2]})');
  }
  // 6 Nov: search with the trade's short forms
  for (final x in v['tags'] as List) {
    final p = logic.product(x[0] as int);
    check(jsonEncode(lensTags(p)) == jsonEncode(x[1]), 'lensTags ${p.id} -> ${lensTags(p)} (want ${x[1]})');
  }
  for (final x in v['search'] as List) {
    final got = logic.catalog.where((p) => lensMatch(p, x[0] as String)).map((p) => p.id).toList();
    check(jsonEncode(got) == jsonEncode(x[1]), 'lensMatch "${x[0]}" -> ${got.length} lenses (want ${(x[1] as List).length})');
  }
  return (checks: checks, fails: fails, matchLines: matchLines);
}
