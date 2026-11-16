import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../core/brands.dart';
import '../core/Data/responseModel/brandsResModel.dart';
import '../core/catalog_data.dart';
import '../core/format.dart';
import '../core/js_compat.dart';
import '../core/logic.dart';
import '../core/models.dart';
import '../core/quantity.dart';
import '../core/stock.dart';
import '../data/content.dart';
import '../data/ordering_api.dart';
import '../services/device_store.dart';
import '../services/sound_service.dart';

/// Who is using the app. Vishal sets four switches per account and staff login:
/// show prices, show availability, add to cart, place order.
class Persona {
  final bool price;
  final bool order;
  final String send;
  const Persona(this.price, this.order, this.send);
  static const all = {
    'owner': Persona(true, true, 'Place order'),
    'staff': Persona(true, false, 'Save to shop cart'),
    'sub': Persona(false, false, 'Send to my distributor'),
  };
}

class ProdView {
  int? mi; // index into matches (product opened from a power)
  int? pid; // product opened from a brand, search or favorites
  double n; // quantity
  bool scan; // opened from a scanned QR code
  ProdView({this.mi, this.pid, this.n = 1, this.scan = false});
}

class BulkState {
  int? pid;
  int li;
  Map<String, double> grid; // pairs, or lenses for a one-eye progressive grid
  String? sel;
  String eye; // progressive grids: 'P' pair, 'R' / 'L' one eye

  /// 5 Nov: every range of the product keeps its own grid while the customer moves between range tabs.
  /// `grids` holds one grid per range index; `grid` is the grid of the open range.
  Map<int, Map<String, double>> grids;

  /// Set when a cart line is reopened on the grid: it goes back into the same order.
  String? grp;
  BulkState({this.pid, this.li = 0, Map<String, double>? grid, this.sel, this.eye = 'P', this.grp}) : grid = grid ?? {}, grids = {};
}

class RxDetails {
  String ref, idx, coat, note;
  int? pick;
  RxDetails({this.ref = '', this.idx = '', this.coat = '', this.note = '', this.pick});
}

class LastOrder {
  final double n;
  final double v;
  final List<CartLine> cart;
  final DateTime until;
  bool cancelled;
  final String as;
  final String number;
  final String group; // 'parcel' or 'bulk' (5 Nov: each is placed on its own)
  LastOrder({required this.n, required this.v, required this.cart, required this.until, required this.as, required this.number, this.group = 'parcel'})
    : cancelled = false;
  bool get open => as == 'owner' && !cancelled && DateTime.now().isBefore(until);
}

/// A pre-order: a sold-out power held and sent as soon as stock arrives (not charged until then), or a whole
/// range pre-ordered from the price list.
class PreOrder {
  final String kind; // 'power' or 'range'
  final int pid, li;
  final Rx? rx, rxL;
  final double qR, qL, qty; // qty in pairs
  final String eye; // 'H' single vision / KT, 'P' pair, 'R' / 'L' one eye
  final String eta;
  const PreOrder({
    this.kind = 'power',
    required this.pid,
    required this.li,
    this.rx,
    this.rxL,
    this.qR = 0,
    this.qL = 0,
    required this.qty,
    this.eye = 'P',
    this.eta = '',
  });
}

/// The lock of a parcel order to one range of one lens.
typedef RangeLock = ({int pid, int li});

/// What a VOC1 code holds, in words (`qrInfo`).
class QrInfo {
  final String code;
  final Product p;
  final String eye;
  final int li;
  final String eyeTxt;
  final List<String> pw;
  final String range;
  final String name;
  const QrInfo({
    required this.code,
    required this.p,
    required this.eye,
    required this.li,
    required this.eyeTxt,
    required this.pw,
    required this.range,
    required this.name,
  });
}

/// `lockInfo()`: the lens (and range) a parcel order is limited to.
class LockInfo {
  final Product p;
  final int? li;
  final List<PowerBlock> bx;
  final bool cyl;
  const LockInfo(this.p, this.li, this.bx, this.cyl);
}

class LoaderState {
  final String text;
  const LoaderState(this.text);
}

/// The whole app state, mirroring `S` in the HTML prototype, with its actions.
class AppState extends ChangeNotifier {
  final OrderingApi api;
  final SoundService sound;
  final DeviceStore store;
  late final CatalogData data;
  late final AccountContent content;
  late final LensLogic logic;
  late final List<String> brands;
  final ValueNotifier<({String eye, String f, double v})?> wheelLive = ValueNotifier(null);
  String loginMobile = '';
  String loginCode = '';
  bool loginOtpSent = false;

  void setLoginOtpSent(bool v) {
    loginOtpSent = v;
    notifyListeners();
  }

  AppState({required this.api, required this.sound, DeviceStore? store}) : store = store ?? MemoryStore();

  Future<void> init() async {
    final d = await api.load();
    data = d.catalog;
    content = d.content;
    logic = LensLogic(catalog: data.catalog, superMasters: data.superMasters, stock: api.stock, customer: data.customer);
    brands = brandOrder(data.catalog);
    wish = LinkedHashSet.of([data.meta.favs[0], data.meta.favs[3]]);
    staffLogins = content.staffLogins;
    // settings kept on the phone
    final w = int.tryParse(store.getString('asl.welcome') ?? '') ?? -1;
    welcomeI = (w + 1) % data.welcome.length; // a different welcome poster every time the app opens
    store.setString('asl.welcome', '$welcomeI');
    if (store.getString('asl.unit') == 'pcs') unit = 'pcs';
    if (store.getString('asl.qrmake') == '0') qrMake = false;
    final t = store.getString('asl.theme');
    if (t == 'dark' || t == 'light') darkN.value = t == 'dark';
    if (store.getString('vo_fb') == '0') sound.enabled = false;
    try {
      final v = jsonDecode(store.getString('asl.wishp') ?? '[]');
      if (v is List) {
        wishP = [
          for (final x in v)
            if (x is String && qrInfo(x) != null) x,
        ];
      }
    } catch (_) {}
    loginMobile = api.demoMobile ?? '';
    loginCode = api.demoCode ?? '';

    // Check saved session / token (auto-login):
    String? token;
    try {
      if (Hive.isBoxOpen('userdata')) {
        token = Hive.box('userdata').get('token')?.toString();
      }
    } catch (_) {}
    token ??= store.getString('asl.token');

    if (token != null && token.trim().isNotEmpty) {
      screen = 'home';
    }
  }

  List<Product> get catalog => data.catalog;
  Customer get cust => data.customer;
  StockService get stock => api.stock;
  Product product(int pid) => catalog[pid - 1];

  // ---------------- navigation ----------------
  String screen = 'welcome';
  List<String> hist = [];

  /// Changes whenever the screen should start again at the top.
  int viewEpoch = 0;
  bool _keepScroll = false;

  // ---------------- parcel order ----------------
  String lens = LensType.sv;
  Rx rx = const Rx(sph: -2, cyl: -0.5, axis: 90, add: 2);
  Rx? rxL;
  String eye = 'R';
  String field = 'sph';
  final Set<String> optIdx = {};
  final Set<String> optCoat = {};
  int? only;
  List<Match> matches = [];
  ProdView? prod;
  String peye = 'P';
  double aq = 1;
  double pickSign = -1;
  bool rxMode = false;
  RxDetails rxd = RxDetails();

  // ---------------- stock order ----------------
  BulkState bulk = BulkState();
  String? stype;
  String q = '';

  // ---------------- browsing ----------------
  String? brand;
  /// The brand as the API sent it (picture, name, description, product count) for the brand page; null when the
  /// page was opened without it.
  BrandItem? brandInfo;
  String btab = 'All';
  String bfilter = 'All';
  String? plBrand;

  // ---------------- session ----------------
  final List<CartLine> cart = [];

  /// 5 Nov: lines saved for later (never ordered; stock is checked again when moved back).
  final List<CartLine> saved = [];

  /// The group being checked out ('parcel' / 'bulk'), the cart view ('all' / 'parcel' / 'bulk') and the cart lines
  /// whose power table is opened in full.
  String? coGroup;
  String cview = 'all';
  final Set<int> cexp = {};

  /// Where the order being built started (5 Nov): 'parcel' (the parcel flow), 'bulk' (the bulk flow) or 'free'
  /// (brands, search, favourites, Shop by range, a product page). Free lines get Order as: Parcel / Bulk in the cart.
  String via = 'free';
  LastOrder? lastOrder;
  double dropped = 0;
  String persona = 'owner';
  late LinkedHashSet<int> wish;
  final LinkedHashSet<String> wishR = LinkedHashSet(); // saved ranges, 'pid:li'
  List<String> wishP = []; // saved powers, as VOC1 codes
  final Set<int> bopen = {}; // brand cards with their range details open
  String remark = '';
  final List<PreOrder> pre = [];

  // ---------------- 29 Oct – 3 Nov ----------------
  String unit = 'pairs'; // 'pairs' or 'pcs' (single vision and KT)
  Map<String, bool> off = {'sph': false, 'cyl': false}; // SPH / CYL switched off on the wheels (3 Nov)
  RangeLock? lockR; // parcel order inside one range
  String pview = 'wheel'; // inside a range: 'wheel' or 'chart'
  Map<String, double> pq = {}; // power chart quantities, grid key -> pairs (or lenses for one eye)
  Map<int, Map<String, double>> pqs = {}; // 6 Nov: power chart quantities of the other ranges (Order by power)
  int? pcLi; // 6 Nov: the range the power chart shows
  /// 6 Nov: Order by power for a whole lens (free wheels over every range, range strip, chart with range tabs).
  /// A range chosen on the product page works as before: that range only, no strip, no tabs.
  bool byPow = false;
  String? pcSel; // power chart: selected box
  bool qrMake = true; // side menu › button beside each power: QR code (true) or Favorite (false)
  bool? get dark => darkN.value; // null = follow the phone
  final ValueNotifier<bool?> darkN = ValueNotifier(null);
  String rgType = LensType.sv; // Shop by range
  int rgI = 0;
  int bulkPre = 0; // sold-out boxes pre-ordered by the last Add of a grid
  List<String> myQR = []; // QR labels made on this phone
  int welcomeI = -1;
  String lang = 'en';
  late List<StaffLogin> staffLogins;
  bool get fb => sound.enabled;

  // transient UI
  String? toastMsg;
  int toastId = 0;
  Timer? _toastT;
  LoaderState? loader;
  Timer? _loaderT;
  bool drawerOpen = false;

  bool get canOrder => Persona.all[persona]!.order;
  bool get showPrice => Persona.all[persona]!.price;
  String pr(num v) => showPrice ? money(v) : '';
  String tr(String s) => lang == 'hi' && hindi.containsKey(s) ? hindi[s]! : s;

  // ---------------- core helpers ----------------

  String? _lastScreen;

  void _render({bool keep = false}) {
    if (!(keep || _keepScroll)) viewEpoch++;
    _keepScroll = false;
    // every redraw closes the toast and the side menu, as render() did
    _toastT?.cancel();
    toastMsg = null;
    drawerOpen = false;
    _normalize();
    if (screen == 'cart') cview = cartView; // a chosen group that is now empty shows All again
    // a gentle heads-up when the cart opens with a line that cannot be supplied in full
    if (screen == 'cart' && _lastScreen != 'cart' && cart.any((c) => logic.lineAvail(c) < c.qty)) {
      Timer(const Duration(milliseconds: 220), sound.warn);
    }
    _lastScreen = screen;
    // the cart nudge runs only while there is something in the cart (3 Nov)
    if (cart.isEmpty) {
      _nudgeT?.cancel();
      nudge = false;
    } else if (_nudgeT == null || !_nudgeT!.isActive) {
      _armNudge();
    }
    notifyListeners();
  }

  /// Keep the current scroll position on the next render (`S.keepScroll = true`).
  void refresh() => _render(keep: true);

  /// The state fix-ups the HTML app did while drawing a screen.
  void _normalize() {
    if (screen == 'rx') {
      if (lens != LensType.sv) {
        rx = rx.copyWith(axis: nearestAx(rx.axis, lens));
        if (rxL != null) rxL = rxL!.copyWith(axis: nearestAx(rxL!.axis, lens));
      }
      fitLock();
      offFix();
      if ((qKind(lens, peye) != 'P' || !rxMode) && rxL != null) {
        // 30 Oct: a parcel pair is one power for both eyes; a different eye is ordered with Right / Left eye only
        rxL = null;
        eye = 'R';
      }
      if (!rxCols.contains(field)) field = 'sph';
    }
    if (screen == 'options' || screen == 'results') filtered();
    if (screen == 'product') {
      prod ??= ProdView(pid: data.meta.favs[0]);
    }
    if (screen == 'rxdetails') {
      final m = logic.matchProducts(lens, rx, rxL).where((x) => x.mto).toList();
      matches = [for (var i = 0; i < m.length; i++) m[i].withIndex(i)];
      if (rxd.pick == null || rxd.pick! >= m.length) rxd.pick = m.isNotEmpty ? 0 : -1;
    }
  }

  /// Screens where a new order is not yet parcel or bulk (5 Nov): lines added after them are 'free'.
  static const freeScreens = {'home', 'shop', 'brands', 'brand', 'search', 'wishlist', 'rangetype', 'ranges', 'rangelist', 'favorites'};

  void go(String sc, {bool push = true}) {
    if (freeScreens.contains(sc)) via = 'free';
    if (push && screen != sc) hist.add(screen);
    screen = sc;
    drawerOpen = false;
    _render();
  }

  void back() {
    screen = hist.isNotEmpty ? hist.removeLast() : 'home';
    drawerOpen = false;
    _render();
  }

  void toast(String msg) {
    _toastT?.cancel();
    toastMsg = msg;
    toastId++;
    notifyListeners();
    _toastT = Timer(const Duration(milliseconds: 2800), () {
      toastMsg = null;
      notifyListeners();
    });
  }

  void showLoader(String text, int? ms, [VoidCallback? then]) {
    _loaderT?.cancel();
    loader = LoaderState(text);
    notifyListeners();
    if (ms != null) {
      _loaderT = Timer(Duration(milliseconds: ms), () {
        loader = null;
        notifyListeners();
        then?.call();
      });
    }
  }

  void hideLoader() {
    _loaderT?.cancel();
    loader = null;
    notifyListeners();
  }

  void resetOrder() {
    byPow = false;
    off = {'sph': false, 'cyl': false};
    rxMode = false;
    pq = {};
    pqs = {};
    pcLi = null;
    pcSel = null;
    rxL = null;
    eye = 'R';
    only = null;
    lockR = null;
    peye = 'P';
    aq = 1;
    optIdx.clear();
    optCoat.clear();
  }

  ({double n, double v}) get cartTotals {
    var n = 0.0, v = 0.0;
    for (final c in cart) {
      n += c.qty;
      v += c.qty * c.price;
    }
    return (n: n, v: v);
  }

  /// `rxCols()`: no CYL or AXIS wheel inside a lens or range made without cylinder.
  List<String> get rxCols {
    final base = lens == LensType.sv ? const ['sph', 'cyl'] : const ['sph', 'cyl', 'axis', 'add'];
    final l = lockInfo;
    return l != null && !l.cyl ? base.where((c) => c != 'cyl' && c != 'axis').toList() : base;
  }

  // ---------------- ordering inside one product or range (29 Oct) ----------------

  LockInfo? get lockInfo {
    if (rxMode || only == null) return null;
    final p = product(only!);
    if (p.rx) return null;
    final li = lockR != null && lockR!.pid == p.id ? lockR!.li : null;
    final bx = [
      for (final i in li != null ? [li] : List.generate(p.lines.length, (i) => i)) ...p.lines[i].boxes,
    ];
    if (bx.isEmpty) return null;
    return LockInfo(p, li, bx, bx.any((b) => b.c[0] != 0 || b.c[1] != 0));
  }

  static List<double> _uniqS(Iterable<double> a) => ({for (final v in a) toFixedNum(v)}.toList()..sort());

  /// `lockVals(f, T)`: the values a field can take inside the lock, or null for any.
  List<double>? lockVals(String f, Rx t) {
    final l = lockInfo;
    if (l == null) return null;
    switch (f) {
      case 'sph':
        return _uniqS(l.bx.expand((b) => spanVals(b.s, b.ss ?? 0.25)));
      case 'cyl':
        final v = _uniqS(
          l.bx.expand(
            (b) => inSpan(t.sph, b.s, b.ss ?? 0.25) ? spanVals(b.c, b.cs ?? 0.25).where((c) => !b.cross || t.sph.abs() < c.abs() - eps) : const <double>[],
          ),
        );
        return v.isNotEmpty ? v : const [0.0];
      case 'axis':
        if (t.cyl == 0) return null;
        final a = {
          for (final b in l.bx)
            if (b.ax != null && b.ax != 0 && blockHas(b, t.sph, t.cyl)) b.ax!.toDouble(),
        }.toList()..sort();
        return a.isNotEmpty ? a : null;
      case 'add':
        return l.p.ptype == LensType.sv ? null : List.of(adds);
    }
    return null;
  }

  int? axisFixed(Rx t) {
    final a = lockVals('axis', t);
    return a != null && a.length == 1 ? a[0].round() : null;
  }

  static double nearestIn(double v, List<double> list) => list.reduce((b, x) => (x - v).abs() < (b - v).abs() ? x : b);

  /// `fitLock()`: every input snaps into the lock.
  void fitLock() {
    if (lockInfo == null) return;
    Rx fit(Rx t) {
      for (final f in const ['sph', 'cyl', 'axis', 'add']) {
        final v = lockVals(f, t);
        if (v != null && v.isNotEmpty) t = t.withField(f, nearestIn(t.field(f), v));
      }
      return t;
    }

    rx = fit(rx);
    if (rxL != null) rxL = fit(rxL!);
    if (!rxCols.contains(field)) field = 'sph';
  }

  /// `fxMatch(m)`: the chosen lens's match for the dialled power; inside a locked range it is always that range.
  Match? fxMatch(List<Match> m) {
    if (only == null) return null;
    final fx = product(only!);
    final l = lockInfo;
    if (l != null && l.li != null) {
      final ok = logic.lineMatches(fx, l.li!, rx) && (rxL == null || logic.lineMatches(fx, l.li!, rxL!));
      return ok ? Match(p: fx, li: l.li!, liL: l.li!, uR: rx, uL: rxL) : null;
    }
    return m.where((x) => x.p.id == fx.id).firstOrNull;
  }

  // ---------------- SPH / CYL switches (3 Nov) ----------------
  /// Off = that power is 0 and its wheel is greyed out. CYL off also greys out AXIS. One of the two stays on.
  bool fOff(String f) => f == 'axis' ? off['cyl']! : (off[f] ?? false);

  void offFix() {
    Rx fx(Rx t) => t.copyWith(sph: fOff('sph') ? 0 : t.sph, cyl: fOff('cyl') ? 0 : t.cyl);
    rx = fx(rx);
    if (rxL != null) rxL = fx(rxL!);
  }

  bool canTog(String f, List<String> cols) {
    if (f != 'sph' && f != 'cyl') return false;
    if (!cols.contains('sph') || !cols.contains('cyl')) return false;
    if (fOff(f)) return true;
    final lv = lockVals(f, padTarget);
    return lv == null || (lv.length > 1 && lv.any((v) => v.abs() < 1e-6));
  }

  /// Sphere off and no cylinder set yet: the power is not complete.
  bool get needCyl => fOff('sph') && [rx, if (rxL != null) rxL!].any((t) => t.cyl == 0);

  void toggleField(String f) {
    final other = f == 'sph' ? 'cyl' : 'sph';
    if (!off[f]! && off[other]!) off[other] = false; // one of the two is always on
    off[f] = !off[f]!;
    if (off[f]! && field == f) field = f == 'sph' ? 'cyl' : 'sph';
    offFix();
    sound.toggle();
    final msg = !off[f]!
        ? '${f == 'sph' ? 'Sphere' : 'Cylinder'} on: set it on its wheel.'
        : f == 'cyl'
        ? 'Cylinder off${lens != LensType.sv ? ' (and axis)' : ''}: sphere only.'
        : 'Sphere off: cylinder only.';
    refresh();
    toast(msg);
  }

  /// The power being set: the right eye, or the left when it is entered separately.
  Rx get padTarget => (eye == 'L' && rxL != null) ? rxL! : rx;
  set padTarget(Rx v) {
    if (eye == 'L' && rxL != null) {
      rxL = v;
    } else {
      rx = v;
    }
  }

  String get eyeLab {
    if (lens != LensType.prog) return 'BE · both eyes';
    if (peye == 'R') return 'Right eye (OD)';
    if (peye == 'L') return 'Left eye (OS)';
    if (!rxMode) return 'BE';
    return eye == 'L' && rxL != null ? 'Left eye (OS)' : 'Right eye (OD)';
  }

  ({List<Match> m, int nEx, int nNear, int nMto, String mode}) rxModeInfo(String lt) {
    final m = logic.matchProducts(lt, rx, rxL);
    final nEx = m.where((x) => !x.mto && !x.diff && logic.orderable(x)).length;
    final nNear = m.where((x) => x.diff && logic.orderable(x)).length;
    final nMto = m.where((x) => x.mto).length;
    final nList = m.where((x) => !x.mto && !x.diff).length;
    final mode = nEx > 0
        ? 'ok'
        : nNear > 0
        ? 'near'
        : nMto > 0
        ? 'mto'
        : nList > 0
        ? 'listed'
        : 'rx';
    return (m: m, nEx: nEx, nNear: nNear, nMto: nMto, mode: mode);
  }

  ({List<Match> all, List<Match> list}) filtered() {
    final m = logic.matchProducts(lens, rx, rxL);
    final all = [for (var i = 0; i < m.length; i++) m[i].withIndex(i)];
    matches = all;
    var list = all;
    if (only != null) list = list.where((x) => x.p.id == only).toList();
    if (optIdx.isNotEmpty) list = list.where((x) => optIdx.contains(x.p.index)).toList();
    if (optCoat.isNotEmpty) list = list.where((x) => optCoat.contains(coatKey(x.p))).toList();
    return (all: all, list: list);
  }

  int? pairPrice(Product p, int li, [int? liL]) {
    final a = p.lines[li].price, b = p.lines[liL ?? li].price;
    return a != null && b != null ? logic.tier((a + b) / 2) : null;
  }

  int? fromPrice(Product p) {
    final ps = p.lines.where((l) => l.price != null).map((l) => l.price!).toList();
    if (ps.isEmpty) return null;
    return logic.tier(ps.reduce((a, b) => a < b ? a : b));
  }

  String pwShort(Rx x, Rx asked, String lt) =>
      fmt(x.sph) + (x.cyl != 0 ? ' / ${fmt(x.cyl)}' : '') + (lt != LensType.sv && x.add != asked.add ? ' · ADD ${fmt(x.add)}' : '');

  String diffText(Match m, String lt) {
    final l = rxL ?? rx;
    if (m.uL == null) return 'supplied as ${pwShort(m.uR, rx, lt)}';
    return 'supplied as ${[if (m.dR) 'R ${pwShort(m.uR, rx, lt)}', if (m.dL) 'L ${pwShort(m.uL!, l, lt)}'].join(' · ')}';
  }

  void _pushLine(Match m, double qR, double qL) {
    cart.add(
      logic.makeLine(m, qR, qL, asked: rx, askedL: rxL)
        ..grp = via == 'bulk' ? 'bulk' : 'parcel'
        ..free = via == 'free',
    );
  }

  // ---------------- cart groups (5 Nov) ----------------

  /// `cartGroups()`: the cart split into its two orders, with each line's index.
  ({List<int> parcel, List<int> bulk}) get cartGroups {
    final p = <int>[], b = <int>[];
    for (var i = 0; i < cart.length; i++) {
      (cart[i].group == 'bulk' ? b : p).add(i);
    }
    return (parcel: p, bulk: b);
  }

  static ({double n, double v}) groupTotals(Iterable<CartLine> l) {
    var n = 0.0, v = 0.0;
    for (final c in l) {
      n += c.qty;
      v += c.qty * c.price;
    }
    return (n: n, v: v);
  }

  /// `coGroup()`: the group being checked out.
  String get checkoutGroup {
    final g = cartGroups;
    if (coGroup == 'parcel' && g.parcel.isNotEmpty) return 'parcel';
    if (coGroup == 'bulk' && g.bulk.isNotEmpty) return 'bulk';
    return g.parcel.isNotEmpty ? 'parcel' : 'bulk';
  }

  /// Order as: Parcel / Bulk on a free line.
  void setLineGroup(int i, String g) {
    if (i < 0 || i >= cart.length) return;
    sound.toggle();
    cart[i].grp = g;
    refresh();
    toast('Moved to the $g order');
  }

  /// The group of the cart's main Check out button: the shown group, the only group, or parcel first.
  String get cartCheckoutDefault {
    final g = cartGroups;
    final v = cartView;
    if (v != 'all') return v;
    return g.parcel.isNotEmpty ? 'parcel' : 'bulk';
  }

  /// The cart view, back to 'all' when the chosen group is empty.
  String get cartView {
    final g = cartGroups;
    if (cview == 'parcel' && g.parcel.isEmpty) return 'all';
    if (cview == 'bulk' && g.bulk.isEmpty) return 'all';
    return cview;
  }

  void setCview(String v) {
    cview = v;
    refresh();
  }

  void toggleCexp(int i) {
    if (!cexp.remove(i)) cexp.add(i);
    refresh();
  }

  void saveForLater(int i) {
    if (i < 0 || i >= cart.length) return;
    saved.insert(0, cart.removeAt(i));
    refresh();
    toast('Saved for later. It will not be ordered.');
  }

  void moveToCart(int i) {
    if (i < 0 || i >= saved.length) return;
    final c = saved.removeAt(i);
    cart.add(c);
    refresh();
    toast('Moved back to the ${c.group == 'bulk' ? 'bulk' : 'parcel'} order');
  }

  void removeSaved(int i) {
    if (i < 0 || i >= saved.length) return;
    sound.remove();
    saved.removeAt(i);
    refresh();
  }

  // ---------------- actions (data-a) ----------------

  void toLogin() {
    loginOtpSent = false;
    go('login');
  }

  void signIn() {
    showLoader('Signing you in', null);
    api.verifyOtp(loginMobile, loginCode).then((ok) {
      hideLoader();
      if (!ok) {
        toast('That code did not match. Try again.');
        return;
      }
      hist = [];
      go('home', push: false);
    });
  }

  void openCart() => go('cart');
  void toSearch() {
    q = '';
    go('search');
  }

  void openBrand(String b, {BrandItem? info}) {
    brand = b;
    brandInfo = info;
    btab = screen == 'brands' && bfilter != 'All' ? bfilter : 'All'; // opens on the type chosen on Brands
    go('brand');
  }

  void setBrandFilter(String v) {
    bfilter = v;
    _render();
  }

  void setBrandTab(String v) {
    btab = v;
    _render();
  }

  void openDrawer() {
    drawerOpen = true;
    notifyListeners();
  }

  void closeDrawer() {
    drawerOpen = false;
    notifyListeners();
  }

  /// A side-menu item.
  void menuGo(String m) {
    drawerOpen = false;
    if (m == 'signout') {
      signOut();
      return;
    }
    hist = ['home'];
    if (m == 'orders' || m == 'account') {
      hist = [];
      go(m, push: false);
      return;
    }
    go(m, push: false);
  }

  void toParcel() {
    resetOrder();
    rxMode = false;
    via = 'parcel';
    go('lenstype');
  }

  void toStock() {
    resetOrder();
    rxMode = false;
    via = 'bulk';
    q = '';
    stype = null;
    go('stocktype');
  }

  void pickStockType(String v) {
    stype = v;
    q = '';
    go('stockpick');
  }

  void switchStockType(String v) {
    stype = v;
    refresh();
  }

  void stockSearch() {
    stype = null;
    q = '';
    go('stockpick');
  }

  void shopTab() {
    hist = [];
    go('shop', push: false);
  }

  void chooseLens(String v) {
    lens = v;
    rxL = null;
    eye = 'R';
    only = null;
    peye = 'P';
    aq = 1;
    optIdx.clear();
    optCoat.clear();
    go('rx');
  }

  void segLens(String v) {
    sound.toggle();
    lens = v;
    aq = 1;
    if (v != LensType.prog) {
      rxL = null;
      eye = 'R';
    }
    optIdx.clear();
    optCoat.clear();
    _render();
  }

  void tapCell(String e, String f) {
    sound.toggle();
    if (e == 'L' && rxL == null) rxL = rx;
    eye = e;
    field = f;
    refresh();
  }

  void leftSameAsRight() {
    rxL = null;
    eye = 'R';
    _render();
  }

  /// "Left eye different ›" on the wheels.
  void leftDifferent() {
    rxL ??= rx;
    eye = 'L';
    field = 'sph';
    refresh();
  }

  void switchEye(String e) => tapCell(e, field);

  /// A scroll wheel settled on a value.
  void setField(String f, double v) {
    final t = padTarget;
    if ((t.field(f) - v).abs() < 1e-6) return;
    padTarget = t.withField(f, v);
    refresh();
  }

  /// The Type sheet's Done.
  void applyTyped(Map<String, double> values, Map<String, int> signs) {
    var t = padTarget;
    values.forEach((c, v0) {
      var v = v0;
      if (c == 'sph' || c == 'cyl') {
        v = signs[c]! * v.abs();
        pickSign = signs[c]!.toDouble();
      }
      t = switch (c) {
        'axis' => t.copyWith(axis: nearestAx(v.round().clamp(1, 180), lens)),
        'sph' => t.copyWith(sph: snapTo(v, 0.25, -20, 10)),
        'cyl' => t.copyWith(cyl: snapTo(v, 0.25, -6, 6)),
        _ => t.copyWith(add: snapTo(v.abs(), 0.25, 0.75, 4)),
      };
    });
    padTarget = t;
    fitLock();
    qtyFocusReq++; // 5 Nov: after Done in the Type sheet the quantity box takes the focus
    refresh();
  }

  /// Bumped when the quantity box on the power screen should take the keyboard focus.
  int qtyFocusReq = 0;

  void rxContinue() {
    final m = rxModeInfo(lens).m;
    if (m.isEmpty) {
      go('results');
      return;
    }
    showLoader('Checking stock for this power', 700, () => go('options'));
  }

  void toggleIdx(String v) {
    sound.toggle();
    optIdx.contains(v) ? optIdx.remove(v) : optIdx.add(v);
    refresh();
  }

  void toggleCoat(String v) {
    sound.toggle();
    optCoat.contains(v) ? optCoat.remove(v) : optCoat.add(v);
    refresh();
  }

  void toResults() => showLoader('Finding lenses', 650, () => go('results'));

  void toOptions() {
    if (hist.isNotEmpty && hist.last == 'options') {
      back();
    } else {
      go('options');
    }
  }

  void clearFilters() {
    optIdx.clear();
    optCoat.clear();
    only = null;
    _render();
  }

  void openMatch(int mi) {
    prod = ProdView(mi: mi, n: 1);
    go('product');
  }

  void openProduct(int pid) {
    prod = ProdView(pid: pid);
    go('product');
  }

  void prodQty(int d) {
    final m = matches[prod!.mi!];
    prod!.n = qStepN(qKind(m.p.ptype, peye), prod!.n, d);
    refresh();
  }

  /// A typed quantity (pairs, or lenses for one eye), rounded to what can be ordered.
  double _roundQty(String k, double v) {
    final st = k == 'H' ? 0.5 : 1.0;
    return toFixedNum(math.max(qMin(k), jsRound(v / st) * st));
  }

  void setAq(double v) {
    aq = _roundQty(qKind(lens, peye), v);
    refresh();
  }

  void setProdN(double v) {
    final m = prod?.mi != null ? matches[prod!.mi!] : null;
    if (m == null) return;
    prod!.n = _roundQty(qKind(m.p.ptype, peye), v);
    refresh();
  }

  void aqStep(int d) {
    aq = qStepN(qKind(lens, peye), aq, d);
    refresh();
  }

  void setPeye(String v) {
    peye = v;
    if (v != 'P') {
      rxL = null;
      eye = 'R';
    }
    aq = 1;
    refresh();
  }

  void quickAdd() {
    final x = fxMatch(rxModeInfo(lens).m);
    if (x == null || x.mto || needCyl) return;
    final k = qKind(lens, peye);
    final t = toLR(k, aq);
    _pushLine(x, t.r, t.l);
    sound.add();
    final txt = x.uL != null ? 'R ${powerTxt(x.uR, lens)} · L ${powerTxt(x.uL!, lens)}' : powerTxt(x.uR, lens);
    final word = qWord(k, aq, unit: unit);
    aq = 1;
    refresh();
    toast('Added $txt · $word');
  }

  void otherLenses() {
    only = null;
    final m = rxModeInfo(lens).m;
    if (m.isEmpty) {
      go('results');
      return;
    }
    showLoader('Checking stock for this power', 700, () => go('options'));
  }

  void toggleWish(int id) {
    final on = !wish.contains(id);
    sound.heart(on);
    if (on) {
      wish.add(id);
    } else {
      wish.remove(id);
    }
    refresh();
    toast(on ? 'Saved to favorites' : 'Removed from favorites');
  }

  /// The heart beside a range.
  void toggleWishRange(int pid, int li) {
    final k = '$pid:$li', r = rg(product(pid).lines[li].range);
    final on = !wishR.contains(k);
    sound.heart(on);
    if (on) {
      wishR.add(k);
    } else {
      wishR.remove(k);
    }
    refresh();
    toast(on ? 'Range $r saved to favorites' : 'Range $r removed from favorites');
  }

  /// The heart beside a power (when the side menu's button beside each power is Favorite).
  void togglePowerFav(String code) {
    final i = qrInfo(code);
    if (i == null) return;
    final on = !wishP.contains(code);
    sound.heart(on);
    if (on) {
      wishP.insert(0, code);
    } else {
      wishP.remove(code);
    }
    store.setString('asl.wishp', jsonEncode(wishP));
    refresh();
    toast('${on ? 'Saved to' : 'Removed from'} favorites: ${i.pw.join(' · ')}');
  }

  /// `favSub()`: what Favorites holds, for the account page and the side menu.
  String get favSub {
    final a = wish.length, r = wishR.length, w = wishP.length;
    final t = [if (a > 0) '$a lens${a == 1 ? '' : 'es'}', if (r > 0) '$r range${r == 1 ? '' : 's'}', if (w > 0) '$w power${w == 1 ? '' : 's'}'].join(' · ');
    return t.isEmpty ? 'Nothing saved yet' : t;
  }

  void toggleBrandCard(int pid) {
    bopen.contains(pid) ? bopen.remove(pid) : bopen.add(pid);
    refresh();
  }

  void addToCart() {
    final m = matches[prod!.mi!];
    final k = qKind(m.p.ptype, peye);
    final t = toLR(k, prod!.n);
    _pushLine(m, t.r, t.l);
    sound.add();
    if (prod!.scan) {
      final n = prod!.n;
      hist = ['home'];
      screen = 'scan';
      _render();
      toast('Added ${qWord(k, n, unit: unit)}. Scan the next envelope, or check out.');
      return;
    }
    only = m.p.id;
    // 3 Nov: the range stays chosen, so the next power can be set on the wheels or the power chart
    final keepR = !m.mto && m.li == m.liL;
    lockR = keepR ? (pid: m.p.id, li: m.li) : null;
    pview = 'wheel';
    aq = 1;
    hist = ['shop', 'lenstype'];
    screen = 'rx';
    _render();
    toast(keepR ? 'Added to cart. Next power in this range: wheels or the power chart.' : 'Added to cart. Dial the next power for this lens, or check out.');
  }

  /// Sold-out power on the product page: Pre-order.
  void addPreFromProduct() {
    final m = matches[prod!.mi!];
    final k = qKind(m.p.ptype, peye);
    final t = toLR(k, prod!.n);
    _pushPre(m, t.r, t.l, k);
    sound.add();
    final n = prod!.n;
    prod!.n = 1;
    refresh();
    toast('Pre-ordered ${qWord(k, n, unit: unit)}. See Pre-orders in the menu.');
  }

  /// Sold-out power on the power screen: Pre-order.
  void preAdd() {
    final x = fxMatch(rxModeInfo(lens).m);
    if (x == null) return;
    final k = qKind(lens, peye);
    final t = toLR(k, aq);
    _pushPre(x, t.r, t.l, k);
    sound.add();
    final txt = x.uL != null ? 'R ${powerTxt(x.uR, lens)} · L ${powerTxt(x.uL!, lens)}' : powerTxt(x.uR, lens);
    final word = qWord(k, aq, unit: unit);
    aq = 1;
    refresh();
    toast('Pre-ordered $txt · $word. See Pre-orders in the menu.');
  }

  void _pushPre(Match m, double qR, double qL, String eye) {
    pre.add(PreOrder(pid: m.p.id, li: m.li, rx: m.uR, rxL: m.uL, qR: qR, qL: qL, qty: (qR + qL) / 2, eye: eye, eta: logic.powStock(m).eta ?? ''));
  }

  void removePre(int i) {
    sound.remove();
    pre.removeAt(i);
    refresh();
    toast('Pre-order cancelled');
  }

  /// `preTxt(x)`: a pre-order in words.
  String preTxt(PreOrder x) {
    final p = product(x.pid);
    if (x.kind != 'power') return '${rg(p.lines[x.li].range)} · ${jsNum(x.qty)} pairs';
    final pw = x.rxL != null ? 'R ${powerTxt(x.rx!, p.ptype)} · L ${powerTxt(x.rxL!, p.ptype)}' : powerTxt(x.rx!, p.ptype);
    final q = x.qR != 0 && x.qL == 0
        ? '${nfmt(x.qR)} right${x.qR == 1 ? '' : ' lenses'}'
        : x.qR == 0 && x.qL != 0
        ? '${nfmt(x.qL)} left${x.qL == 1 ? '' : ' lenses'}'
        : qWord('P', x.qty);
    return '$pw · ${rg(p.lines[x.li].range)} · $q';
  }

  /// N/A power: one step (0.25) on the sphere or the cylinder in the same range.
  void naAlt(Rx alt, {required bool fromProduct}) {
    if (fromProduct) {
      final m = matches[prod!.mi!];
      rx = m.uR.copyWith(sph: alt.sph, cyl: alt.cyl);
      lens = m.p.ptype;
      only = m.p.id;
      go('rx');
      return;
    }
    rx = rx.copyWith(sph: alt.sph, cyl: alt.cyl);
    refresh();
  }

  /// N/A power: the same power in other brands.
  void naOther() {
    if (prod != null && prod!.mi != null && screen == 'product') {
      final m = matches[prod!.mi!];
      rx = m.uR;
      lens = m.p.ptype;
    }
    otherLenses();
  }

  /// A range of a lens: Parcel order inside it (wheels or the power chart).
  /// 6 Nov: no Parcel / Bulk question; the line gets Order as: Parcel / Bulk in the cart.
  void parcelInRange(int pid, int li) {
    final p = product(pid);
    resetOrder();
    via = 'free';
    lens = p.ptype;
    only = p.id;
    lockR = (pid: p.id, li: li);
    field = 'sph';
    pview = 'wheel';
    go('rx');
  }

  /// A range of a lens: Bulk order on its power grid.
  void bulkInRange(int pid, int li) {
    resetOrder();
    bulk = BulkState(pid: pid, li: li);
    go('grid');
  }

  void unlockRange() {
    lockR = null;
    byPow = true;
    pcLi = null;
    refresh();
    toast('Scroll any range of this lens.');
  }

  void clearLens() {
    only = null;
    lockR = null;
    refresh();
    toast('Lens removed. Set the power and tap Continue to see every lens.');
  }

  /// Order by power (5 Nov): the wheels for this lens across all its ranges; the app finds the range.
  void productParcel(int pid) {
    final p = product(pid);
    resetOrder();
    via = 'free';
    byPow = true;
    lens = p.ptype;
    only = p.id;
    lockR = null;
    pview = 'wheel';
    go('rx');
  }

  /// `rjump`: a range in the range strip was tapped: the wheels move to the nearest power inside it.
  void rangeJump(int li) {
    final p = product(only!);
    final l = lockInfo;
    if (l != null && l.li != null) {
      lockR = (pid: p.id, li: li);
      fitLock();
    } else {
      final keep = lockR;
      lockR = (pid: p.id, li: li);
      fitLock();
      lockR = keep;
    }
    refresh();
    toast('Range ${rg(p.lines[li].range)}');
  }

  /// `stripOn(p)`: the range of the range strip that is highlighted.
  int stripOn(Product p, [Rx? t]) {
    final l = lockInfo;
    if (l != null && l.li != null) return l.li!;
    return logic.exactLine(p, t ?? padTarget);
  }

  void productStock(int pid) {
    resetOrder();
    bulk = BulkState(pid: pid);
    go('stockrange');
  }

  void addRxRequest() {
    cart.add(CartLine(kind: 'rxreq', lt: lens, qR: 1, qL: 1, qty: 1, price: 0, rx: rx, rxL: rxL, stock: 'rx'));
    sound.add();
    go('cart');
  }

  void removeLine(int i) {
    sound.remove();
    cart.removeAt(i);
    refresh();
  }

  void clearCart() {
    sound.remove();
    cart.clear();
    _render();
  }

  void takeAvailable(int i) {
    sound.tick('major');
    if (!logic.capLine(cart[i])) cart.removeAt(i);
    _render();
    toast('Set to what is available');
  }

  /// Pencil on a bulk line: reopen its grid (the line goes back into the same order).
  void editGridLine(int i) {
    final c = cart.removeAt(i);
    via = c.free ? 'free' : 'bulk';
    bulk = BulkState(pid: c.pid, li: c.li, grid: Map.of(c.grid), eye: c.eye, grp: c.grp);
    go('grid');
  }

  /// Save from the Change quantity sheet.
  void setLineQty(int i, String k, double n) {
    final c = cart[i];
    final per = c.price * c.qty / ((c.qR + c.qL) == 0 ? 1 : (c.qR + c.qL));
    final t = toLR(k, n);
    c.qR = t.r;
    c.qL = t.l;
    c.qty = (t.r + t.l) / 2;
    c.price = per * 2;
    _render();
  }

  /// 3 Nov: Add more goes to Shop (Shop by brand, parcel, bulk, RX, Shop by range).
  void addMore() {
    resetOrder();
    hist = [];
    go('shop', push: false);
  }

  void toCheckout([String? g]) {
    coGroup = g;
    go('checkout');
  }

  void place() {
    final as = persona;
    final label = as == 'owner'
        ? 'Placing your order'
        : as == 'staff'
        ? 'Saving to the shop cart'
        : 'Sending to your distributor';
    showLoader(label, null);
    final g = checkoutGroup;
    final lines = cart.where((c) => c.group == g).toList();
    api.placeOrder(OrderDraft(lines: lines, remark: remark, persona: as, group: g)).then((placed) {
      hideLoader();
      _finish(as, number: placed.number, until: placed.changeableUntil);
    });
  }

  /// `finish()`: only the group being checked out is placed; the other group stays in the cart.
  void _finish(String sentAs, {String? number, DateTime? until}) {
    final g = checkoutGroup;
    final rest = cart.where((c) => c.group != g).toList();
    final mine = cart.where((c) => c.group == g).toList();
    dropped = sentAs == 'owner' ? logic.capCart(mine) : 0;
    final t = groupTotals(mine);
    lastOrder = LastOrder(
      n: t.n,
      v: t.v,
      cart: mine.map((c) => c.copy()).toList(),
      until: until ?? DateTime.now().add(const Duration(hours: 1)),
      as: sentAs,
      number: number ?? content.nextOrderNumber,
      group: g,
    );
    cart
      ..clear()
      ..addAll(sentAs == 'owner' ? rest : [...mine, ...rest]);
    coGroup = null;
    cexp.clear();
    hist = [];
    go('placed', push: false);
  }

  void goHome() {
    hist = [];
    go('home', push: false);
  }

  void goOrders() {
    hist = [];
    go('orders', push: false);
  }

  void changeOrder() {
    final lo = lastOrder;
    if (lo == null || DateTime.now().isAfter(lo.until)) return;
    final others = List.of(cart);
    cart
      ..clear()
      ..addAll(lo.cart.map((c) => c.copy()))
      ..addAll(others);
    lo.cancelled = true;
    hist = [];
    go('cart', push: false);
    toast('Order reopened: change it and place it again');
  }

  void cancelOrder() {
    final lo = lastOrder;
    if (lo == null) return;
    sound.cancel();
    lo.cancelled = true;
    unawaited(api.cancelOrder(lo.number));
    hist = [];
    go('orders', push: false);
    toast('Order ${lo.number} cancelled');
  }

  void reorder(int i) {
    final o = data.pastOrders[i];
    resetOrder();
    cart.clear();
    sound.add();
    if (o.kind == 'grid') {
      bulk = BulkState(pid: o.pid, li: o.li ?? 0, grid: logic.fillPast(o.seed!, o.pid!, o.li ?? 0));
      _pushGrid();
    } else {
      lens = product(o.lines[0].$1).ptype;
      for (final ln in o.lines) {
        final p = product(ln.$1);
        rx = ln.$2;
        rxL = null;
        final m = logic.matchProducts(p.ptype, rx, null).where((x) => x.p.id == p.id).firstOrNull;
        if (m != null) _pushLine(m, 1, 1);
      }
    }
    hist = ['orders'];
    go('cart', push: false);
    toast('Copied ${o.id} into the cart');
  }

  void signOut() {
    try {
      if (Hive.isBoxOpen('userdata')) {
        Hive.box('userdata').delete('token');
      }
    } catch (_) {}
    store.setString('asl.token', '');
    loginMobile = '';
    loginCode = '';
    loginOtpSent = false;
    welcomeI = (welcomeI + 1) % data.welcome.length;
    hist = [];
    go('welcome', push: false);
  }

  void pickProduct(int pid) {
    bulk = BulkState(pid: pid);
    go('stockrange');
  }

  void pickRange(int li) {
    bulkTo(li);
    go('grid');
  }

  void rangeTab(int li) {
    bulkTo(li);
    refresh();
  }

  /// `bulkTo(li)`: open another range of the product, keeping what was typed in each range.
  void bulkTo(int li) {
    bulk.grids[bulk.li] = bulk.grid;
    bulk.li = li;
    bulk.grid = bulk.grids[li] ?? {};
    bulk.grids[li] = bulk.grid;
    bulk.sel = null;
  }

  /// `bulkAll()`: every range with quantities, in range order.
  List<(int, Map<String, double>)> get bulkAll {
    final g = Map.of(bulk.grids)..[bulk.li] = bulk.grid;
    final keys = g.keys.toList()..sort();
    return [
      for (final li in keys)
        if (g[li]!.values.any((q) => q > 0)) (li, g[li]!),
    ];
  }

  static double bulkTot(Map<String, double>? g) => (g ?? const {}).values.fold<double>(0, (a, b) => a + b);

  // grid typing: the keyboard stays open, so only the footer and the cell change
  void gridSelect(String k) {
    bulk.sel = k;
    notifyListeners();
  }

  /// `gEye()`: 'H' (single vision / KT, pairs or pieces), or 'P' / 'R' / 'L' for a progressive grid.
  String get gEye {
    final p = bulk.pid != null ? product(bulk.pid!) : null;
    return p != null && p.ptype == LensType.prog ? bulk.eye : 'H';
  }

  /// Typed number in a grid box (pieces in pieces mode), stored as pairs (lenses for one eye).
  void gridType(String k, double typed) {
    final n = typed / (gEye == 'H' ? uMul('H', unit) : 1);
    if (n > 0) {
      bulk.grid[k] = n;
    } else {
      bulk.grid.remove(k);
    }
    notifyListeners();
  }

  void gridRemove(String k) {
    sound.remove();
    bulk.grid.remove(k);
    refresh();
  }

  void gridClear() {
    sound.remove();
    bulk.grid = {};
    refresh();
  }

  /// Progressive grid: Pair / Right eye only / Left eye only. Changing it clears the grid.
  void setBulkEye(String v) {
    if (bulk.eye == v) return;
    sound.toggle();
    final had = bulkAll.isNotEmpty;
    bulk.eye = v;
    bulk.grid = {};
    bulk.grids = {};
    bulk.sel = null;
    refresh();
    if (had) toast('Grid cleared: quantities now count ${v == 'P' ? 'pairs' : 'pieces for the ${v == 'R' ? 'right' : 'left'} eye'}');
  }

  void setUnit(String v) {
    if (unit == v) return;
    sound.toggle();
    unit = v;
    store.setString('asl.unit', v);
    refresh();
  }

  /// `pushGrid()` (5 Nov): every range with quantities becomes its own cart line.
  void _pushGrid() {
    final cur = bulk.li;
    final all = bulkAll;
    var pre = 0;
    if (all.isEmpty) {
      bulk.grid = {};
      bulk.grids = {};
      bulk.sel = null;
      return;
    }
    for (final (li, g) in all) {
      bulk.li = li;
      bulk.grid = g;
      _pushGridOne();
      pre += bulkPre;
    }
    bulkPre = pre;
    bulk.li = cur;
    bulk.grid = {};
    bulk.grids = {};
    bulk.sel = null;
  }

  /// `pushGridOne()`: sold-out boxes become pre-orders, the rest one cart line.
  void _pushGridOne() {
    final p = product(bulk.pid!);
    final eye0 = p.ptype == LensType.prog ? bulk.eye : 'P';
    final g = <String, double>{};
    var np = 0;
    bulk.grid.forEach((k, q) {
      if (stock.cellStock(p, bulk.li, k).state == 'zero') {
        final lr = eye0 == 'R'
            ? (r: q, l: 0.0)
            : eye0 == 'L'
            ? (r: 0.0, l: q)
            : (r: q, l: q);
        _pushPre(Match(p: p, li: bulk.li, liL: bulk.li, uR: logic.cellPower(p, k)), lr.r, lr.l, eye0);
        np++;
      } else {
        g[k] = q;
      }
    });
    bulkPre = np;
    final line = g.isEmpty ? null : logic.makeGridLine(bulk.pid!, bulk.li, g, eye: eye0);
    if (line != null) {
      cart.add(
        line
          ..grp = bulk.grp ?? (via == 'parcel' ? 'parcel' : 'bulk')
          ..free = via == 'free',
      );
    }
    bulk.grid = {};
    bulk.sel = null;
  }

  void addGrid() {
    if (bulkAll.isEmpty) return;
    sound.add();
    _pushGrid();
    final np = bulkPre;
    go('cart');
    if (np > 0) toast('$np sold-out power${np == 1 ? ' was' : 's were'} pre-ordered. See Pre-orders in the menu.');
  }

  void setQuery(String v) {
    q = v;
    refresh();
  }

  void trySearch(String v) {
    q = v;
    _render();
  }

  void orderPower(double sph, double cyl) {
    resetOrder();
    lens = LensType.sv;
    rx = Rx(sph: sph, cyl: cyl, axis: 90, add: 2);
    go('rx');
  }

  void setRemark(String v) => remark = v;

  // ---------------- actions (data-x) ----------------

  void setPriceListBrand(String b) {
    plBrand = b;
    refresh();
  }

  void setLang(String v) {
    sound.toggle();
    lang = v;
    _render();
  }

  void toggleStaffSwitch(int i, int j) {
    sound.toggle();
    staffLogins[i].switches[j] = !staffLogins[i].switches[j];
    refresh();
  }

  void placePreOrder(int pid, int li, int qty) {
    sound.add();
    pre.add(PreOrder(kind: 'range', pid: pid, li: li, qty: qty.toDouble()));
    refresh();
    toast('Pre-order placed');
  }

  void toggleSound() {
    sound.enabled = !sound.enabled;
    store.setString('vo_fb', sound.enabled ? '1' : '0');
    if (sound.enabled) sound.tick('major');
    refresh();
  }

  // RX orders
  void toRx() {
    rxL = null;
    eye = 'R';
    only = null;
    rxMode = true;
    rxd = RxDetails();
    go('rxhome');
  }

  void rxType(String v) {
    rxMode = true;
    lens = v;
    rxL = null;
    eye = 'R';
    only = null;
    field = 'sph';
    rxd.pick = null;
    go('rx');
  }

  void rxDetailsGo() {
    rxd.pick = null;
    go('rxdetails');
  }

  void rxPick(int v) {
    rxd.pick = v;
    refresh();
  }

  void rxAdd() {
    final d = rxd, m = matches;
    if (d.pick != null && d.pick! >= 0 && d.pick! < m.length) {
      _pushLine(m[d.pick!], 1, 1);
      final c = cart.last;
      c.ref = d.ref;
      c.note = d.note;
    } else {
      cart.add(
        CartLine(
          kind: 'rxreq',
          lt: lens,
          qR: 1,
          qL: 1,
          qty: 1,
          price: 0,
          rx: rx,
          rxL: rxL,
          stock: 'rx',
          ref: d.ref,
          note: d.note,
          pref: [d.idx, d.coat].where((s) => s.isNotEmpty).join(' · '),
        ),
      );
    }
    sound.add();
    rxd = RxDetails();
    go('cart');
  }

  // ---------------- power chart inside a range (29 Oct) ----------------

  void setPview(String v) {
    sound.toggle();
    final was = pview;
    pview = v;
    if (v == 'chart' && was != 'chart') {
      pcLi = null;
      chartLK;
    }
    if (v == 'wheel' && was == 'chart' && lockR != null && pcLi != null && !byPow) {
      lockR = (pid: lockR!.pid, li: pcLi!);
      fitLock();
    }
    refresh();
  }

  /// `chartLK()`: the lens and range the power chart shows. Order by power: any range (tabs); a range chosen on the
  /// product page: that range only.
  ({Product p, int li})? get chartLK {
    final l = lockInfo;
    if (l == null) return null;
    if (!byPow && l.li != null) {
      pcLi = l.li;
      return (p: l.p, li: l.li!);
    }
    pcLi ??= l.li ?? math.max(0, logic.exactLine(l.p, padTarget));
    return (p: l.p, li: pcLi!);
  }

  /// `pctab`: another range tab of the power chart (each range keeps its own quantities).
  void chartTab(int li) {
    if (pcLi != null) pqs[pcLi!] = pq;
    pcLi = li;
    pq = pqs[li] ?? {};
    pcSel = null;
    refresh();
  }

  /// `pqAll()`: every range of the chart with quantities.
  List<(int, Map<String, double>)> get pqAll {
    final lk = chartLK;
    final g = Map.of(pqs);
    if (lk != null) g[lk.li] = pq;
    final keys = g.keys.toList()..sort();
    return [
      for (final li in keys)
        if (g[li]!.values.any((v) => v > 0)) (li, g[li]!),
    ];
  }

  /// The quantity kind on the power screen: 'H' single vision / KT, 'P' / 'R' / 'L' progressive.
  String get pe => lens == LensType.prog ? peye : 'H';

  /// A box of the power chart was focused.
  void chartSelect(String k) {
    pcSel = k;
    notifyListeners();
  }

  /// Typed number in a power chart box (pieces in pieces mode); stored in pairs (lenses for one eye).
  void chartType(String k, double typed, {bool round = false}) {
    final st = pe == 'H' ? 0.5 : 1.0;
    var n = typed / uMul(pe, unit);
    if (round && n > 0) n = toFixedNum(math.max(qMin(pe), jsRound(n / st) * st));
    if (n > 0) {
      pq[k] = n;
    } else {
      pq.remove(k);
    }
    notifyListeners();
  }

  ({List<String> ks, double pairs, double value, String pe, int nr}) get pqTotals {
    final lk = chartLK;
    final all = pqAll;
    final ks = <String>[];
    var pairs = 0.0, value = 0.0;
    for (final (li, q) in all) {
      final unitPrice = lk != null ? (logic.pairPrice(lk.p, li, li) ?? 0) : 0;
      q.forEach((k, v) {
        if (!(v > 0)) return;
        ks.add('$li:$k');
        final pr = pairsOf(pe, v);
        pairs += pr;
        value += pr * unitPrice;
      });
    }
    return (ks: ks, pairs: pairs, value: value, pe: pe, nr: all.length);
  }

  /// Add every typed power of the chart: sold-out boxes become pre-orders, the rest cart lines.
  void chartAdd() {
    final lk = chartLK;
    if (lk == null) return;
    final t = pqTotals;
    if (t.ks.isEmpty) return;
    var np = 0;
    for (final (li, q0) in pqAll) {
      q0.forEach((k, q) {
        if (!(q > 0)) return;
        final lr = toLR(t.pe, q);
        final mm = Match(p: lk.p, li: li, liL: li, uR: logic.cellPower(lk.p, k));
        if (stock.cellStock(lk.p, li, k).state == 'zero') {
          _pushPre(mm, lr.r, lr.l, t.pe);
          np++;
        } else {
          _pushLine(mm, lr.r, lr.l);
        }
      });
    }
    sound.add();
    final n = t.ks.length - np;
    pq = {};
    pqs = {};
    pcSel = null;
    refresh();
    toast('Added $n power${n == 1 ? '' : 's'} · ${t.pe == 'R' || t.pe == 'L' ? qWord(t.pe, t.pairs * 2) : qWord('P', t.pairs)}');
    if (np > 0) {
      Timer(const Duration(milliseconds: 1600), () => toast('$np sold-out power${np == 1 ? ' was' : 's were'} pre-ordered; the rest went to the cart.'));
    }
  }

  // ---------------- QR codes (29 Oct) ----------------

  /// `qrInfo(code)`: what a VOC1 code holds, in words, or null when it cannot be read.
  QrInfo? qrInfo(String code) {
    final r = logic.parseScan(code);
    if (!r.ok) return null;
    final p = r.p!;
    final eyeTxt = p.ptype != LensType.prog
        ? 'BE · both eyes (same lens for either eye)'
        : r.eye == 'R'
        ? 'Right eye only'
        : r.eye == 'L'
        ? 'Left eye only'
        : 'BE · both eyes';
    final pw = r.rxL != null ? ['R ${powerTxt(r.rx!, p.ptype)}', 'L ${powerTxt(r.rxL!, p.ptype)}'] : [powerTxt(r.rx!, p.ptype)];
    final range = r.liL != r.li ? 'R ${rg(p.lines[r.li].range)} · L ${rg(p.lines[r.liL].range)}' : rg(p.lines[r.li].range);
    return QrInfo(
      code: code,
      p: p,
      eye: r.eye,
      li: r.li,
      eyeTxt: eyeTxt,
      pw: pw,
      range: range,
      name: '${bname(p.brand)} ${coatShort(p)} ${p.index}${p.variant.isNotEmpty ? ' · ${p.variant}' : ''}',
    );
  }

  /// The code of a cart line's power (`cartCode`).
  String cartCode(CartLine c) {
    final p = product(c.pid!);
    final eye = p.ptype == LensType.prog
        ? (c.qR != 0 && c.qL == 0
              ? 'R'
              : c.qR == 0 && c.qL != 0
              ? 'L'
              : 'P')
        : 'P';
    return logic.qrCodeFor(p, c.li, c.rx, eye, liL: c.liL ?? c.li, uL: c.rxL);
  }

  /// The code of a box of the bulk grid (`cellCode`).
  String cellCode(String k) {
    final p = product(bulk.pid!);
    return logic.qrCodeFor(p, bulk.li, logic.cellPower(p, k), gEye == 'H' ? 'P' : gEye);
  }

  /// The code of the power on the product page or the power screen, or null.
  String? productCode() {
    final m = prod?.mi != null && prod!.mi! < matches.length ? matches[prod!.mi!] : null;
    if (m == null || m.mto) return null;
    return logic.qrCodeFor(m.p, m.li, m.uR, m.p.ptype == LensType.prog ? peye : 'P', liL: m.liL, uL: m.uL);
  }

  String? powerScreenCode() {
    final x = fxMatch(rxModeInfo(lens).m);
    if (x == null || x.mto) return null;
    return logic.qrCodeFor(x.p, x.li, x.uR, lens == LensType.prog ? peye : 'P', liL: x.liL, uL: x.uL);
  }

  /// A QR label was shown: keep it in "QR codes you made".
  void rememberQR(String code) {
    if (!myQR.contains(code)) myQR.insert(0, code);
  }

  /// `openScan(code)`: a scanned (or typed) code opens the product page with lens, range and power filled in.
  bool openScan(String code) {
    final r = logic.parseScan(code);
    if (!r.ok) {
      sound.warn();
      toast(r.err!);
      return false;
    }
    final p = r.p!;
    resetOrder();
    lens = p.ptype;
    peye = r.eye;
    rx = r.rx!;
    rxL = r.rxL;
    matches = [Match(p: p, li: r.li, liL: r.liL, uR: r.rx!, uL: r.rxL)];
    prod = ProdView(mi: 0, n: 1, scan: true);
    showLoader('Reading the code', 550, () => go('product'));
    return true;
  }

  void openScanScreen() => go('scan');

  // ---------------- side menu › Display (29 Oct) ----------------

  void setDark(bool v) {
    sound.toggle();
    darkN.value = v;
    store.setString('asl.theme', v ? 'dark' : 'light');
    notifyListeners();
  }

  void setQrMake(bool v) {
    if (qrMake == v) return;
    qrMake = v;
    store.setString('asl.qrmake', v ? '1' : '0');
    sound.toggle();
    refresh();
    drawerOpen = true;
    toast(v ? 'Each power you add now has a QR code button' : 'Each power you add now has a heart to save it. Scan QR still works.');
  }

  // ---------------- Shop by range (3 Nov) ----------------

  void toRange() => go('rangetype');

  void pickRangeType(String t, {bool stay = false}) {
    rgType = t;
    if (stay) {
      _render();
    } else {
      go('rangelist');
    }
  }

  void pickRangeCode(int i) {
    rgI = i;
    go('rangeprods');
  }

  // ---------------- cart reminders (3 Nov) ----------------
  // The cart icon shakes gently when there is something in the cart and nothing has been touched for 5 minutes;
  // any touch stops it. When the app goes to the background with a cart, a local notification is scheduled for
  // 10 minutes later and cancelled if the app comes back first (see ReminderService).

  /// Debug menu › Reminders: short times to try the shake (10 s) and the notification (30 s).
  bool fastReminders = false;
  Duration get nudgeAfter => fastReminders ? const Duration(seconds: 10) : const Duration(minutes: 5);
  Duration get remindAfter => fastReminders ? const Duration(seconds: 30) : const Duration(minutes: 10);

  void setFastReminders(bool v) {
    fastReminders = v;
    activity();
    notifyListeners();
  }

  DateTime lastActivity = DateTime.now();
  bool nudge = false;
  Timer? _nudgeT;

  bool get cartWaiting => cart.isNotEmpty && !const ['checkout', 'placed', 'welcome', 'login'].contains(screen);

  /// Any touch, scroll or key in the app.
  void activity() {
    lastActivity = DateTime.now();
    if (nudge) {
      nudge = false;
      notifyListeners();
    }
    _nudgeT?.cancel();
    if (cart.isNotEmpty) _armNudge();
  }

  void _armNudge() {
    _nudgeT?.cancel();
    _nudgeT = Timer(nudgeAfter, () {
      if (cartWaiting) {
        nudge = true;
        notifyListeners();
      }
    });
  }

  /// The text of the cart reminder notification.
  ({String title, String body})? get cartReminder {
    if (cart.isEmpty) return null;
    final n = cart.length, q = cart.fold<double>(0, (a, c) => a + c.qty);
    return (
      title: 'Your cart is waiting',
      body: '$n line${n == 1 ? '' : 's'}${q > 0 ? ' · ${nfmt(q)} pair${q == 1 ? '' : 's'}' : ''} in your cart. Check out when you are ready.',
    );
  }

  /// Opened from the reminder notification.
  void openCartFromReminder() {
    hist = ['home'];
    go('cart', push: false);
  }

  /// A plain message for things the prototype only describes (downloads, sharing, calls).
  void info(String msg) => toast(msg);

  // ---------------- prototype tools (debug menu) ----------------

  void setPersona(String p) {
    persona = p;
    refresh();
  }

  void setStockMode(StockMode m) {
    stock.mode = m;
    refresh();
  }

  /// "Jump to a screen", with the same set-up the prototype did.
  void jump(String sc) {
    if (sc == 'placed') {
      // fbInit only
    }
    if (sc == 'rx') rxMode = false;
    if (sc == 'rxhome' || sc == 'rxdetails') {
      rxMode = true;
      lens = LensType.prog;
    }
    if (sc == 'loading') {
      showLoader('Finding lenses', 3600);
      return;
    }
    if (const ['options', 'results', 'product'].contains(sc) && matches.isEmpty) filtered();
    if (sc == 'product') {
      final i = matches.indexWhere((x) => !x.diff && !x.mto && logic.orderable(x));
      prod = ProdView(mi: i < 0 ? 0 : i, n: 1);
    }
    if ((sc == 'grid' || sc == 'stockrange') && bulk.pid == null) bulk = BulkState(pid: data.meta.repeat);
    if (sc == 'welcome') welcomeI = (welcomeI + 1) % data.welcome.length;
    if ((sc == 'cart' || sc == 'checkout') && cart.isEmpty) {
      final m = logic.matchProducts(LensType.sv, rx, null).where((x) => !x.diff && !x.mto && logic.orderable(x)).firstOrNull;
      if (m != null) _pushLine(m, 2, 2);
    }
    if (sc == 'placed' && lastOrder == null) {
      final m = logic.matchProducts(LensType.sv, rx, null).where((x) => !x.diff && !x.mto && logic.orderable(x)).firstOrNull;
      if (m != null && cart.isEmpty) _pushLine(m, 1, 1);
      _finish('owner');
      return;
    }
    hist = sc == 'welcome' || tabFor(sc) != null ? [] : ['home'];
    go(sc, push: false);
  }

  /// Which tab is lit for a screen (`TABFOR`). Null hides the tab bar.
  /// 'brand' (the brand detail page) is deliberately not listed: it opens as its own page, under no tab.
  static String? tabFor(String sc) => switch (sc) {
    'home' => 'home',
    'shop' ||
    'lenstype' ||
    'brands' ||
    'stockpick' ||
    'stocktype' ||
    'search' ||
    'wishlist' ||
    'rxhome' ||
    'rangetype' ||
    'rangelist' ||
    'rangeprods' => 'shop',
    'orders' => 'orders',
    'account' ||
    'preorder' ||
    'posters' ||
    'videos' ||
    'certs' ||
    'pricelist' ||
    'ledger' ||
    'transactions' ||
    'invoices' ||
    'salesreport' ||
    'analysis' ||
    'stafflogins' ||
    'weblogin' ||
    'language' ||
    'contact' ||
    'faq' ||
    'about' ||
    'terms' => 'account',
    _ => null,
  };

  /// The tab lit right now. A Shop-group screen (a brand, Brands, Search, ...) that was opened from Home keeps Home
  /// lit instead of jumping to Shop; opening it from the Shop tab keeps Shop lit.
  String? get activeTab {
    final t = tabFor(screen);
    if (t == 'shop' && hist.isNotEmpty && hist.first == 'home') return 'home';
    return t;
  }

  void tab(String t) {
    hist = [];
    go(t, push: false);
  }

  @override
  void dispose() {
    _nudgeT?.cancel();
    _toastT?.cancel();
    _loaderT?.cancel();
    super.dispose();
  }
}
