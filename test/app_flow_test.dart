// Runs the same 171 steps on AppState that tool/reference_check/run_original.js
// ran on the HTML prototype (v116, 6 Nov), and compares the state after every step with
// test/fixtures/js_flow_reference.json (screen, history, cart lines and prices,
// last order, favourites, pre-orders, bulk grid, lens and powers, range lock, SPH/CYL
// switches, power chart, Shop by range).
//
//   flutter test test/app_flow_test.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:air_smart_lens/core/js_compat.dart';
import 'package:air_smart_lens/core/models.dart';
import 'package:air_smart_lens/data/mock_ordering_api.dart';
import 'package:air_smart_lens/services/sound_service.dart';
import 'package:air_smart_lens/state/app_state.dart';

List<String> rowKeys(AppState s, String row) {
  final p = s.product(s.bulk.pid!);
  final gr = s.logic.lineGrid(p, s.bulk.li);
  return [
    for (final c in gr.cols)
      if (gr.cells.contains('$row|${jsNum(c)}')) '$row|${jsNum(c)}',
  ];
}

Map? _rx(Rx? r) => r == null ? null : {'sph': r.sph, 'cyl': r.cyl, 'axis': r.axis, 'add': r.add};
double _r3(double v) => (v * 1000).round() / 1000;

Object? _norm(Object? x) {
  if (x is Map) return {for (final e in x.entries) e.key.toString(): _norm(e.value)};
  if (x is List) return x.map(_norm).toList();
  if (x is num) return x == x.roundToDouble() ? x.toInt() : x.toDouble();
  return x;
}

Map _cartLine(Map c) {
  final m = Map.of(c);
  if (m['kind'] != 'one') {
    for (final k in ['qR', 'qL', 'rx', 'liL']) {
      m.remove(k);
    }
  }
  m.removeWhere((k, v) => (v == null || v == '' || (v is Map && v.isEmpty) || v == 0 || v == false) && k != 'qty' && k != 'price');
  return m;
}

Map snapshot(AppState s) {
  final m = {
    'screen': s.screen,
    'hist': [...s.hist],
    'lens': s.lens,
    'rx': _rx(s.rx),
    'rxL': _rx(s.rxL),
    'eye': s.eye,
    'only': s.only,
    'peye': s.peye,
    'aq': s.aq,
    'persona': s.persona,
    'wish': s.wish.toList(),
    'dropped': s.dropped,
    'bulk': {
      'pid': s.bulk.pid,
      'li': s.bulk.li,
      'grid': Map.of(s.bulk.grid),
      'grids': {
        for (final e in (s.bulk.grids.entries.toList()..sort((a, b) => a.key.compareTo(b.key))))
          if (e.value.isNotEmpty) '${e.key}': Map.of(e.value),
      },
    },
    'cart': [
      for (final c in s.cart)
        _cartLine({
          'kind': c.kind,
          'pid': c.pid,
          'li': c.li,
          'liL': c.liL,
          'qR': c.qR,
          'qL': c.qL,
          'qty': c.qty,
          'price': _r3(c.price),
          'rx': _rx(c.rx),
          'rxL': _rx(c.rxL),
          'diff': c.diff,
          'stock': c.stock,
          'cells': c.cells,
          'grid': Map.of(c.grid),
          'ref': c.ref,
          'note': c.note,
          'pref': c.pref,
          'grp': c.group,
          'free': c.free,
        }),
    ],
    'last': s.lastOrder == null
        ? null
        : {'n': s.lastOrder!.n, 'v': _r3(s.lastOrder!.v), 'as': s.lastOrder!.as, 'cancelled': s.lastOrder!.cancelled, 'group': s.lastOrder!.group},
    'matches': s.matches.length,
    'prod': s.prod == null ? null : {'mi': s.prod!.mi, 'pid': s.prod!.pid, if (s.prod!.mi != null) 'n': s.prod!.n},
    'rxMode': s.rxMode,
    'field': s.field,
    // 30 Oct to 3 Nov
    'lockR': s.lockR == null ? null : {'pid': s.lockR!.pid, 'li': s.lockR!.li},
    'off': Map.of(s.off),
    'pview': s.pview,
    'pq': Map.of(s.pq),
    'rgType': s.rgType,
    'rgI': s.rgI,
    'wishR': s.wishR.toList(),
    'wishP': [...s.wishP],
    'pre': [
      for (final x in s.pre) {'kind': x.kind, 'pid': x.pid, 'li': x.li, 'rx': _rx(x.rx), 'qR': x.qR, 'qL': x.qL, 'qty': x.qty, 'eye': x.eye, 'eta': x.eta},
    ],
    'bopen': s.bopen.toList(),
    // 5-6 Nov
    'via': s.via,
    'byPow': s.byPow,
    'pcLi': s.pcLi,
    'pqs': {
      for (final e in (s.pqs.entries.toList()..sort((a, b) => a.key.compareTo(b.key))))
        if (e.value.isNotEmpty) '${e.key}': Map.of(e.value),
    },
    'coGroup': s.coGroup,
    'cview': s.cview,
    'saved': [
      for (final c in s.saved) {'kind': c.kind, 'pid': c.pid, 'li': c.li, 'qty': c.qty, 'grp': c.group},
    ],
  };
  return _norm(jsonDecode(jsonEncode(m))) as Map;
}

Map normaliseReference(Map st) {
  final m = _norm(st) as Map;
  m['cart'] = [for (final c in m['cart'] as List) _cartLine(c as Map)];
  final prod = m['prod'] as Map?;
  if (prod != null && prod['mi'] == null) prod.remove('n');
  return m;
}

// The same steps as tool/reference_check/scenarios.py.
final steps = <({String name, int wait, void Function(AppState) run})>[
  (name: 'start', wait: 40, run: (AppState s) {}),
  (
    name: 'tologin',
    wait: 40,
    run: (AppState s) {
      s.toLogin();
    },
  ),
  (
    name: 'signin',
    wait: 1100,
    run: (AppState s) {
      s.signIn();
    },
  ),
  (
    name: 'toparcel',
    wait: 40,
    run: (AppState s) {
      s.toParcel();
    },
  ),
  (
    name: 'lensSV',
    wait: 40,
    run: (AppState s) {
      s.chooseLens('SV');
    },
  ),
  (
    name: 'power -3/-0.75',
    wait: 40,
    run: (AppState s) {
      s.setField('sph', -3.0);
      s.setField('cyl', -0.75);
    },
  ),
  (
    name: 'rxcontinue',
    wait: 800,
    run: (AppState s) {
      s.rxContinue();
    },
  ),
  (
    name: 'optidx 1.56',
    wait: 40,
    run: (AppState s) {
      s.toggleIdx('1.56');
    },
  ),
  (
    name: 'optidx off',
    wait: 40,
    run: (AppState s) {
      s.toggleIdx('1.56');
    },
  ),
  (
    name: 'toresults',
    wait: 750,
    run: (AppState s) {
      s.toResults();
    },
  ),
  (
    name: 'prodm0',
    wait: 40,
    run: (AppState s) {
      s.openMatch(0);
    },
  ),
  (
    name: 'pq+',
    wait: 40,
    run: (AppState s) {
      s.prodQty(1);
    },
  ),
  (
    name: 'pq+2',
    wait: 40,
    run: (AppState s) {
      s.prodQty(1);
    },
  ),
  (
    name: 'pq-',
    wait: 40,
    run: (AppState s) {
      s.prodQty(-1);
    },
  ),
  (
    name: 'addcart',
    wait: 40,
    run: (AppState s) {
      s.addToCart();
    },
  ),
  (
    name: 'power -3.25',
    wait: 40,
    run: (AppState s) {
      s.setField('sph', -3.25);
    },
  ),
  (
    name: 'aq+',
    wait: 40,
    run: (AppState s) {
      s.aqStep(1);
    },
  ),
  (
    name: 'quickadd',
    wait: 40,
    run: (AppState s) {
      s.quickAdd();
    },
  ),
  (
    name: 'power far',
    wait: 40,
    run: (AppState s) {
      s.setField('sph', -9.5);
      s.setField('cyl', -3.0);
    },
  ),
  (
    name: 'otherlens',
    wait: 800,
    run: (AppState s) {
      s.otherLenses();
    },
  ),
  (
    name: 'back',
    wait: 40,
    run: (AppState s) {
      s.back();
    },
  ),
  (
    name: 'cart',
    wait: 40,
    run: (AppState s) {
      s.go('cart');
    },
  ),
  (
    name: 'editline0 +',
    wait: 40,
    run: (AppState s) {
      s.setLineQty(0, 'H', s.cart[0].qty + 0.5);
    },
  ),
  (
    name: 'rm1',
    wait: 40,
    run: (AppState s) {
      s.removeLine(1);
    },
  ),
  (
    name: 'checkout',
    wait: 40,
    run: (AppState s) {
      s.toCheckout(s.cartCheckoutDefault);
    },
  ),
  (
    name: 'place',
    wait: 1100,
    run: (AppState s) {
      s.place();
    },
  ),
  (
    name: 'changeorder',
    wait: 40,
    run: (AppState s) {
      s.changeOrder();
    },
  ),
  (
    name: 'checkout2',
    wait: 40,
    run: (AppState s) {
      s.toCheckout(s.cartCheckoutDefault);
    },
  ),
  (
    name: 'place2',
    wait: 1100,
    run: (AppState s) {
      s.place();
    },
  ),
  (
    name: 'orders',
    wait: 40,
    run: (AppState s) {
      s.goOrders();
    },
  ),
  (
    name: 'cancelorder',
    wait: 40,
    run: (AppState s) {
      s.cancelOrder();
    },
  ),
  (
    name: 'again0',
    wait: 40,
    run: (AppState s) {
      s.reorder(0);
    },
  ),
  (
    name: 'again1',
    wait: 40,
    run: (AppState s) {
      s.screen = 'orders';
      s.refresh();
      s.reorder(1);
    },
  ),
  (
    name: 'editgrid',
    wait: 40,
    run: (AppState s) {
      s.editGridLine(0);
    },
  ),
  (
    name: 'rtab1',
    wait: 40,
    run: (AppState s) {
      s.rangeTab(1);
    },
  ),
  (
    name: 'rtab0',
    wait: 40,
    run: (AppState s) {
      s.rangeTab(0);
    },
  ),
  (
    name: 'type -1|-0.5',
    wait: 40,
    run: (AppState s) {
      s.gridSelect('-1|-0.5');
      s.gridType('-1|-0.5', 5);
    },
  ),
  (
    name: 'type big',
    wait: 40,
    run: (AppState s) {
      s.gridSelect('-2|-1');
      s.gridType('-2|-1', 1200);
    },
  ),
  (
    name: 'addgrid',
    wait: 40,
    run: (AppState s) {
      s.addGrid();
    },
  ),
  (
    name: 'takeavail',
    wait: 40,
    run: (AppState s) {
      s.takeAvailable(0);
    },
  ),
  (
    name: 'clearcart',
    wait: 40,
    run: (AppState s) {
      s.clearCart();
    },
  ),
  (
    name: 'tab home',
    wait: 40,
    run: (AppState s) {
      s.tab('home');
    },
  ),
  (
    name: 'toparcel2',
    wait: 40,
    run: (AppState s) {
      s.toParcel();
    },
  ),
  (
    name: 'lensPROG',
    wait: 40,
    run: (AppState s) {
      s.chooseLens('PROG');
    },
  ),
  (
    name: 'power prog',
    wait: 40,
    run: (AppState s) {
      s.setField('sph', -1.5);
      s.setField('cyl', -0.5);
      s.setField('axis', 95.0);
      s.setField('add', 2.25);
    },
  ),
  (
    name: 'eyeL',
    wait: 40,
    run: (AppState s) {
      s.tapCell('L', 'sph');
    },
  ),
  (
    name: 'left -1.75',
    wait: 40,
    run: (AppState s) {
      s.setField('sph', -1.75);
    },
  ),
  (
    name: 'rxcontinue2',
    wait: 800,
    run: (AppState s) {
      s.rxContinue();
    },
  ),
  (
    name: 'toresults2',
    wait: 750,
    run: (AppState s) {
      s.toResults();
    },
  ),
  (
    name: 'prodm0b',
    wait: 40,
    run: (AppState s) {
      s.openMatch(0);
    },
  ),
  (
    name: 'addcart2',
    wait: 40,
    run: (AppState s) {
      s.addToCart();
    },
  ),
  (
    name: 'peyeR',
    wait: 40,
    run: (AppState s) {
      s.setPeye('R');
    },
  ),
  (
    name: 'quickaddR',
    wait: 40,
    run: (AppState s) {
      s.quickAdd();
    },
  ),
  (
    name: 'peyeL',
    wait: 40,
    run: (AppState s) {
      s.setPeye('L');
    },
  ),
  (
    name: 'aq+L',
    wait: 40,
    run: (AppState s) {
      s.aqStep(1);
    },
  ),
  (
    name: 'quickaddL',
    wait: 40,
    run: (AppState s) {
      s.quickAdd();
    },
  ),
  (
    name: 'seglens KT',
    wait: 40,
    run: (AppState s) {
      s.only = null;
      s.refresh();
      s.segLens('KT');
    },
  ),
  (
    name: 'type sheet',
    wait: 40,
    run: (AppState s) {
      final t = s.padTarget;
      s.applyTyped(
        {'sph': 2.37, 'cyl': t.cyl.abs(), 'axis': t.axis.toDouble(), 'add': t.add},
        {
          'sph': 1,
          'cyl': t.cyl > 0
              ? 1
              : t.cyl < 0
              ? -1
              : s.pickSign.round(),
        },
      );
    },
  ),
  (
    name: 'sameL',
    wait: 40,
    run: (AppState s) {
      s.lens = 'PROG';
      s.peye = 'P';
      s.rxMode = true;
      s.rxL = s.rx.copyWith(sph: -4);
      s.eye = 'L';
      s.refresh();
      s.leftSameAsRight();
    },
  ),
  (
    name: 'cart nothing',
    wait: 40,
    run: (AppState s) {
      s.cart.clear();
      s.refresh();
    },
  ),
  (
    name: 'torx',
    wait: 40,
    run: (AppState s) {
      s.hist = [];
      s.go('home', push: false);
      s.toRx();
    },
  ),
  (
    name: 'rxtype',
    wait: 40,
    run: (AppState s) {
      s.rxType('PROG');
    },
  ),
  (
    name: 'rx power',
    wait: 40,
    run: (AppState s) {
      s.setField('sph', 1.5);
      s.setField('cyl', -0.75);
      s.setField('axis', 85.0);
      s.setField('add', 2.0);
    },
  ),
  (
    name: 'rxdet',
    wait: 40,
    run: (AppState s) {
      s.rxDetailsGo();
    },
  ),
  (
    name: 'rxadd',
    wait: 40,
    run: (AppState s) {
      s.rxAdd();
    },
  ),
  (
    name: 'torx2',
    wait: 40,
    run: (AppState s) {
      s.back();
      s.screen = 'home';
      s.hist = [];
      s.refresh();
      s.toRx();
    },
  ),
  (
    name: 'rxtype2',
    wait: 40,
    run: (AppState s) {
      s.rxType('PROG');
    },
  ),
  (
    name: 'rx far',
    wait: 40,
    run: (AppState s) {
      s.setField('sph', 5.0);
    },
  ),
  (
    name: 'rxdet2',
    wait: 40,
    run: (AppState s) {
      s.rxDetailsGo();
    },
  ),
  (
    name: 'rxadd2',
    wait: 40,
    run: (AppState s) {
      s.rxAdd();
    },
  ),
  (
    name: 'home',
    wait: 40,
    run: (AppState s) {
      s.hist = [];
      s.go('home', push: false);
    },
  ),
  (
    name: 'tosearch',
    wait: 40,
    run: (AppState s) {
      s.toSearch();
    },
  ),
  (
    name: 'try power',
    wait: 40,
    run: (AppState s) {
      s.trySearch('−2.00/−0.50');
    },
  ),
  (
    name: 'power',
    wait: 40,
    run: (AppState s) {
      s.orderPower(-2, -0.5);
    },
  ),
  (
    name: 'home2',
    wait: 40,
    run: (AppState s) {
      s.hist = [];
      s.go('home', push: false);
    },
  ),
  (
    name: 'brands',
    wait: 40,
    run: (AppState s) {
      s.go('brands');
    },
  ),
  (
    name: 'bfilt PROG',
    wait: 40,
    run: (AppState s) {
      s.setBrandFilter('PROG');
    },
  ),
  (
    name: 'brand BOLD',
    wait: 40,
    run: (AppState s) {
      s.openBrand('BOLD');
    },
  ),
  (
    name: 'btab KT',
    wait: 40,
    run: (AppState s) {
      s.setBrandTab('KT');
    },
  ),
  (
    name: 'prodp 64',
    wait: 40,
    run: (AppState s) {
      s.openProduct(64);
    },
  ),
  (
    name: 'wish 64',
    wait: 40,
    run: (AppState s) {
      s.toggleWish(64);
    },
  ),
  (
    name: 'wish 64 off',
    wait: 40,
    run: (AppState s) {
      s.toggleWish(64);
    },
  ),
  (
    name: 'back brand',
    wait: 40,
    run: (AppState s) {
      s.back();
    },
  ),
  (
    name: 'bopen 64',
    wait: 40,
    run: (AppState s) {
      s.toggleBrandCard(64);
    },
  ),
  (
    name: 'wishr 64:1',
    wait: 40,
    run: (AppState s) {
      s.toggleWishRange(64, 1);
    },
  ),
  (
    name: 'range from brand card',
    wait: 40,
    run: (AppState s) {
      s.parcelInRange(64, 1);
    },
  ),
  (
    name: 'bulk in range',
    wait: 40,
    run: (AppState s) {
      s.resetOrder();
      s.bulk = BulkState(pid: 64, li: 1);
      s.go('grid');
    },
  ),
  (
    name: 'type -1|1.5',
    wait: 40,
    run: (AppState s) {
      s.bulk.grid['-1/0|1.5'] = 4;
      s.refresh();
    },
  ),
  (
    name: 'gclear',
    wait: 40,
    run: (AppState s) {
      s.gridClear();
    },
  ),
  (
    name: 'type again',
    wait: 40,
    run: (AppState s) {
      s.bulk.grid['-1/0|1.5'] = 3;
      s.refresh();
    },
  ),
  (
    name: 'addgrid2',
    wait: 40,
    run: (AppState s) {
      s.addGrid();
    },
  ),
  (
    name: 'addmore',
    wait: 40,
    run: (AppState s) {
      s.addMore();
    },
  ),
  (
    name: 'tostock',
    wait: 40,
    run: (AppState s) {
      s.toStock();
    },
  ),
  (
    name: 'stype SV',
    wait: 40,
    run: (AppState s) {
      s.pickStockType('SV');
    },
  ),
  (
    name: 'stype2 KT',
    wait: 40,
    run: (AppState s) {
      s.switchStockType('KT');
    },
  ),
  (
    name: 'pick 64',
    wait: 40,
    run: (AppState s) {
      s.pickProduct(64);
    },
  ),
  (
    name: 'shop tab',
    wait: 40,
    run: (AppState s) {
      s.tab('shop');
    },
  ),
  (
    name: 'torange',
    wait: 40,
    run: (AppState s) {
      s.toRange();
    },
  ),
  (
    name: 'rgtype SV',
    wait: 40,
    run: (AppState s) {
      s.pickRangeType('SV');
    },
  ),
  (
    name: 'rgtype KT stay',
    wait: 40,
    run: (AppState s) {
      s.pickRangeType('KT', stay: true);
    },
  ),
  (
    name: 'rgtype SV stay',
    wait: 40,
    run: (AppState s) {
      s.pickRangeType('SV', stay: true);
    },
  ),
  (
    name: 'rgcode 0',
    wait: 40,
    run: (AppState s) {
      s.pickRangeCode(0);
    },
  ),
  (
    name: 'parcel in range',
    wait: 40,
    run: (AppState s) {
      s.parcelInRange(2, 0);
    },
  ),
  (
    name: 'range power',
    wait: 40,
    run: (AppState s) {
      s.setField('sph', -2.0);
      s.setField('cyl', -0.5);
    },
  ),
  (
    name: 'cyl off',
    wait: 40,
    run: (AppState s) {
      s.toggleField('cyl');
    },
  ),
  (
    name: 'sph off',
    wait: 40,
    run: (AppState s) {
      s.toggleField('sph');
    },
  ),
  (
    name: 'cyl off again',
    wait: 40,
    run: (AppState s) {
      s.toggleField('cyl');
    },
  ),
  (
    name: 'range power 2',
    wait: 40,
    run: (AppState s) {
      s.setField('sph', -1.5);
      s.setField('cyl', -0.75);
    },
  ),
  (
    name: 'quickadd range',
    wait: 40,
    run: (AppState s) {
      s.quickAdd();
    },
  ),
  (
    name: 'chart view',
    wait: 40,
    run: (AppState s) {
      s.setPview('chart');
    },
  ),
  (
    name: 'chart type',
    wait: 40,
    run: (AppState s) {
      s.chartType('-1|-0.5', 2);
      s.chartType('-2|-1', 1.5);
    },
  ),
  (
    name: 'chartadd',
    wait: 40,
    run: (AppState s) {
      s.chartAdd();
    },
  ),
  (
    name: 'wheel view',
    wait: 40,
    run: (AppState s) {
      s.setPview('wheel');
    },
  ),
  (
    name: 'unlock range',
    wait: 40,
    run: (AppState s) {
      s.unlockRange();
    },
  ),
  (
    name: 'scan',
    wait: 40,
    run: (AppState s) {
      s.hist = ['home'];
      s.go('scan', push: false);
    },
  ),
  (
    name: 'scan sample',
    wait: 800,
    run: (AppState s) {
      s.openScan('VOC1|36|P|0|1.50|0.00|180|2.00');
    },
  ),
  (
    name: 'scan add',
    wait: 40,
    run: (AppState s) {
      s.addToCart();
    },
  ),
  (
    name: 'scan bad',
    wait: 40,
    run: (AppState s) {
      s.openScan('hello');
    },
  ),
  (
    name: 'qrmake off',
    wait: 40,
    run: (AppState s) {
      s.qrMake = false;
      s.go('cart');
    },
  ),
  (
    name: 'powfav',
    wait: 40,
    run: (AppState s) {
      s.togglePowerFav(s.cartCode(s.cart.firstWhere((c) => c.kind == 'one' && c.stock != 'mto')));
    },
  ),
  (
    name: 'favorites',
    wait: 40,
    run: (AppState s) {
      s.go('wishlist');
    },
  ),
  (
    name: 'powopen',
    wait: 800,
    run: (AppState s) {
      s.openScan(s.wishP.first);
    },
  ),
  (
    name: 'qrmake on',
    wait: 40,
    run: (AppState s) {
      s.qrMake = true;
      s.refresh();
    },
  ),
  (
    name: 'g search',
    wait: 40,
    run: (AppState s) {
      s.hist = [];
      s.go('home', push: false);
      s.q = 'air smart 1.60';
      s.go('search');
    },
  ),
  (
    name: 'g product 1',
    wait: 40,
    run: (AppState s) {
      s.openProduct(1);
    },
  ),
  (
    name: 'g order by power',
    wait: 40,
    run: (AppState s) {
      s.productParcel(1);
    },
  ),
  (
    name: 'g power',
    wait: 40,
    run: (AppState s) {
      s.setField('sph', -2.5);
      s.setField('cyl', -0.75);
    },
  ),
  (
    name: 'g quickadd',
    wait: 40,
    run: (AppState s) {
      s.quickAdd();
    },
  ),
  (
    name: 'g rjump 2',
    wait: 40,
    run: (AppState s) {
      s.rangeJump(2);
    },
  ),
  (
    name: 'g quickadd 2',
    wait: 40,
    run: (AppState s) {
      s.quickAdd();
    },
  ),
  (
    name: 'g chart',
    wait: 40,
    run: (AppState s) {
      s.setPview('chart');
    },
  ),
  (
    name: 'g chart type',
    wait: 40,
    run: (AppState s) {
      final k = s.logic.lineGrid(s.product(1), s.pcLi!).cells.elementAt(3);
      s.chartType(k, 2);
    },
  ),
  (
    name: 'g pctab 1',
    wait: 40,
    run: (AppState s) {
      s.chartTab(1);
    },
  ),
  (
    name: 'g chart type 2',
    wait: 40,
    run: (AppState s) {
      final k = s.logic.lineGrid(s.product(1), 1).cells.elementAt(5);
      s.chartType(k, 1.5);
    },
  ),
  (
    name: 'g pctab back',
    wait: 40,
    run: (AppState s) {
      s.chartTab(0);
    },
  ),
  (
    name: 'g chartadd',
    wait: 40,
    run: (AppState s) {
      s.chartAdd();
    },
  ),
  (
    name: 'g wheel',
    wait: 40,
    run: (AppState s) {
      s.setPview('wheel');
    },
  ),
  (
    name: 'g bulk 2 ranges',
    wait: 40,
    run: (AppState s) {
      s.resetOrder();
      s.via = 'bulk';
      s.bulk = BulkState(pid: 1);
      s.go('grid');
      s.gridType(s.logic.lineGrid(s.product(1), 0).cells.elementAt(2), 4);
    },
  ),
  (
    name: 'g rtab 1',
    wait: 40,
    run: (AppState s) {
      s.rangeTab(1);
    },
  ),
  (
    name: 'g bulk type 2',
    wait: 40,
    run: (AppState s) {
      s.gridType(s.logic.lineGrid(s.product(1), 1).cells.elementAt(1), 6);
    },
  ),
  (
    name: 'g rtab 0',
    wait: 40,
    run: (AppState s) {
      s.rangeTab(0);
    },
  ),
  (
    name: 'g addgrid',
    wait: 40,
    run: (AppState s) {
      s.addGrid();
    },
  ),
  (
    name: 'g cgrp bulk',
    wait: 40,
    run: (AppState s) {
      s.setLineGroup(s.cartGroups.parcel.firstWhere((i) => s.cart[i].free), 'bulk');
    },
  ),
  (
    name: 'g cgrp parcel',
    wait: 40,
    run: (AppState s) {
      s.setLineGroup([...s.cartGroups.parcel, ...s.cartGroups.bulk].firstWhere((i) => s.cart[i].free), 'parcel');
    },
  ),
  (
    name: 'g savelater',
    wait: 40,
    run: (AppState s) {
      s.saveForLater([...s.cartGroups.parcel, ...s.cartGroups.bulk].first);
    },
  ),
  (
    name: 'g movecart',
    wait: 40,
    run: (AppState s) {
      s.moveToCart(0);
    },
  ),
  (
    name: 'g cview bulk',
    wait: 40,
    run: (AppState s) {
      s.setCview('bulk');
    },
  ),
  (
    name: 'g checkout bulk',
    wait: 40,
    run: (AppState s) {
      s.toCheckout(s.cartCheckoutDefault);
    },
  ),
  (
    name: 'g place bulk',
    wait: 1100,
    run: (AppState s) {
      s.place();
    },
  ),
  (
    name: 'g cart after',
    wait: 40,
    run: (AppState s) {
      s.go('cart');
    },
  ),
  (
    name: 'g checkout parcel',
    wait: 40,
    run: (AppState s) {
      s.toCheckout(s.cartCheckoutDefault);
    },
  ),
  (
    name: 'g place parcel',
    wait: 1100,
    run: (AppState s) {
      s.place();
    },
  ),
  (
    name: 'g change order',
    wait: 40,
    run: (AppState s) {
      s.changeOrder();
    },
  ),
  (
    name: 'staff',
    wait: 40,
    run: (AppState s) {
      s.setPersona('staff');
    },
  ),
  (
    name: 'cart2',
    wait: 40,
    run: (AppState s) {
      s.go('cart');
    },
  ),
  (
    name: 'checkout staff',
    wait: 40,
    run: (AppState s) {
      s.toCheckout(s.cartCheckoutDefault);
    },
  ),
  (
    name: 'place staff',
    wait: 1100,
    run: (AppState s) {
      s.place();
    },
  ),
  (
    name: 'sub',
    wait: 40,
    run: (AppState s) {
      s.setPersona('sub');
    },
  ),
  (
    name: 'place sub',
    wait: 1100,
    run: (AppState s) {
      s.go('checkout');
      s.place();
    },
  ),
  (
    name: 'owner',
    wait: 40,
    run: (AppState s) {
      s.setPersona('owner');
    },
  ),
  (
    name: 'place owner',
    wait: 1100,
    run: (AppState s) {
      s.go('checkout');
      s.place();
    },
  ),
  (
    name: 'jump grid',
    wait: 40,
    run: (AppState s) {
      s.jump('grid');
    },
  ),
  (
    name: 'jump product',
    wait: 40,
    run: (AppState s) {
      s.jump('product');
    },
  ),
  (
    name: 'jump cart',
    wait: 40,
    run: (AppState s) {
      s.jump('cart');
    },
  ),
  (
    name: 'jump rxdetails',
    wait: 40,
    run: (AppState s) {
      s.jump('rxdetails');
    },
  ),
  (
    name: 'jump ledger',
    wait: 40,
    run: (AppState s) {
      s.jump('ledger');
    },
  ),
  (
    name: 'back2',
    wait: 40,
    run: (AppState s) {
      s.back();
    },
  ),
  (
    name: 'menu stafflogins',
    wait: 40,
    run: (AppState s) {
      s.openDrawer();
      s.menuGo('stafflogins');
    },
  ),
  (
    name: 'sw',
    wait: 40,
    run: (AppState s) {
      s.toggleStaffSwitch(1, 0);
    },
  ),
  (
    name: 'menu orders',
    wait: 40,
    run: (AppState s) {
      s.openDrawer();
      s.menuGo('orders');
    },
  ),
  (
    name: 'signout',
    wait: 40,
    run: (AppState s) {
      s.openDrawer();
      s.menuGo('signout');
    },
  ),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the app state follows the original HTML app step by step', () async {
    final ref = jsonDecode(File('test/fixtures/js_flow_reference.json').readAsStringSync()) as List;
    expect(ref.length, steps.length);
    final s = AppState(api: MockOrderingApi(), sound: SoundService());
    await s.init();
    for (var i = 0; i < steps.length; i++) {
      steps[i].run(s);
      await Future<void>.delayed(Duration(milliseconds: steps[i].wait));
      final want = normaliseReference((ref[i] as Map)['state'] as Map);
      final got = snapshot(s);
      for (final k in want.keys) {
        expect(got[k], equals(want[k]), reason: 'step $i "${steps[i].name}": $k');
      }
    }
  }, timeout: const Timeout(Duration(minutes: 2)));
}
