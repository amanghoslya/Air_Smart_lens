/// Data models for the catalogue, powers, matches, grids and the cart.
/// Pure Dart (no Flutter), so the business logic can be tested on its own.
library;

/// JavaScript truthiness for flags stored as true/1 in the data files.
bool jsTruthy(Object? v) => v != null && v != false && v != 0 && v != '';

/// A block of powers inside a price line: sphere span [s], cylinder span [c]
/// (signed, from -> to), optional steps, the Cross rule and a stocked axis.
class PowerBlock {
  final List<double> s;
  final List<double> c;
  final double? ss;
  final double? cs;
  final bool cross;
  final int? ax;
  const PowerBlock({required this.s, required this.c, this.ss, this.cs, this.cross = false, this.ax});

  factory PowerBlock.fromJson(Map<String, dynamic> j) => PowerBlock(
        s: (j['s'] as List).map((e) => (e as num).toDouble()).toList(),
        c: (j['c'] as List).map((e) => (e as num).toDouble()).toList(),
        ss: (j['ss'] as num?)?.toDouble(),
        cs: (j['cs'] as num?)?.toDouble(),
        cross: jsTruthy(j['cross']),
        ax: (j['ax'] as num?)?.toInt(),
      );
}

/// One price line of a product: a power range with its price and diameter.
class PriceLine {
  final int? dia;
  final String range;
  final String add;
  final String axis;
  final int? price;
  final String status; // 'ok' or 'coming soon'
  final String read; // plain-language reading of the range
  final List<PowerBlock> boxes;
  final String? sm; // linked Super Master code, e.g. 'M05'
  final String? env; // envelope photo of this range (assets/images/envelopes/<env>.jpg)
  final bool est; // price estimated (missing in the price file)
  const PriceLine({
    this.dia,
    required this.range,
    required this.add,
    required this.axis,
    this.price,
    required this.status,
    required this.read,
    required this.boxes,
    this.sm,
    this.env,
    this.est = false,
  });

  factory PriceLine.fromJson(Map<String, dynamic> j) => PriceLine(
        dia: (j['dia'] as num?)?.toInt(),
        range: (j['range'] ?? '').toString(),
        add: (j['add'] ?? '').toString(),
        axis: (j['axis'] ?? '').toString(),
        price: (j['price'] as num?)?.toInt(),
        status: (j['status'] ?? 'ok').toString(),
        read: (j['read'] ?? '').toString(),
        boxes: ((j['boxes'] as List?) ?? const []).map((b) => PowerBlock.fromJson(b as Map<String, dynamic>)).toList(),
        sm: j['sm'] as String?,
        env: j['env'] as String?,
        est: j['est'] == true,
      );
}

/// Lens types. SV = single vision, KT = KT (bifocal), PROG = progressive.
class LensType {
  static const sv = 'SV';
  static const kt = 'KT';
  static const prog = 'PROG';
  static const all = [sv, kt, prog];
  static const names = {sv: 'Single vision', kt: 'KT', prog: 'Progressive'};
}

class Product {
  final int id;
  final String brand;
  final String name;
  final String coating;
  final String base;
  final String ptype;
  final bool rx; // made to order (RX progressive)
  final String index;
  final String? material;
  final String? features;
  final int? page;
  final String variant; // e.g. 'Photo grey, Poly' (2 Nov price file); '' when none
  final String? env; // the product's first envelope photo
  final List<PriceLine> lines;
  final String? apiId; // non-null when created from the live catalog API
  final String? imageUrl; // product_image / brand_image URL from API
  final bool? apiAvailable; // available flag from API
  final bool apiNa; // n_a_flag from API
  const Product({
    required this.id,
    required this.brand,
    required this.name,
    required this.coating,
    required this.base,
    required this.ptype,
    required this.rx,
    required this.index,
    this.material,
    this.features,
    this.page,
    this.variant = '',
    this.env,
    required this.lines,
    this.apiId,
    this.imageUrl,
    this.apiAvailable,
    this.apiNa = false,
  });

  factory Product.fromJson(Map<String, dynamic> j) => Product(
        id: (j['id'] as num).toInt(),
        brand: (j['brand'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        coating: (j['coating'] ?? '').toString(),
        base: (j['base'] ?? '').toString(),
        ptype: (j['ptype'] ?? 'SV').toString(),
        rx: jsTruthy(j['rx']),
        index: (j['index'] ?? '').toString(),
        material: j['material'] as String?,
        features: j['features'] as String?,
        page: (j['page'] as num?)?.toInt(),
        variant: (j['variant'] ?? '').toString(),
        env: j['env'] as String?,
        lines: (j['lines'] as List).map((l) => PriceLine.fromJson(l as Map<String, dynamic>)).toList(),
      );
}

/// A power: sphere, cylinder, axis and addition.
class Rx {
  final double sph;
  final double cyl;
  final int axis;
  final double add;
  const Rx({required this.sph, required this.cyl, required this.axis, required this.add});

  Rx copyWith({double? sph, double? cyl, int? axis, double? add}) =>
      Rx(sph: sph ?? this.sph, cyl: cyl ?? this.cyl, axis: axis ?? this.axis, add: add ?? this.add);

  double field(String f) => switch (f) {
        'sph' => sph,
        'cyl' => cyl,
        'axis' => axis.toDouble(),
        _ => add,
      };

  Rx withField(String f, double v) => switch (f) {
        'sph' => copyWith(sph: v),
        'cyl' => copyWith(cyl: v),
        'axis' => copyWith(axis: v.round()),
        _ => copyWith(add: v),
      };

  @override
  bool operator ==(Object other) => other is Rx && other.sph == sph && other.cyl == cyl && other.axis == axis && other.add == add;
  @override
  int get hashCode => Object.hash(sph, cyl, axis, add);

  Map<String, dynamic> toJson() => {'sph': sph, 'cyl': cyl, 'axis': axis, 'add': add};
  factory Rx.fromJson(Map<String, dynamic> j) =>
      Rx(sph: (j['sph'] as num).toDouble(), cyl: (j['cyl'] as num).toDouble(), axis: (j['axis'] as num).toInt(), add: (j['add'] as num).toDouble());
}

/// A Super Master: one of the standard power grids (range only).
class SuperMaster {
  final String code;
  final String title;
  final bool add;
  final bool cross;
  final List<SmRow> rows;
  final List<double> cols;
  const SuperMaster({required this.code, required this.title, required this.add, required this.cross, required this.rows, required this.cols});

  factory SuperMaster.fromJson(String code, Map<String, dynamic> j) => SuperMaster(
        code: code,
        title: (j['t'] ?? '').toString(),
        add: jsTruthy(j['add']),
        cross: jsTruthy(j['cross']),
        rows: (j['rows'] as List).map((r) {
          final l = r as List;
          return SmRow((l[0] as num).toDouble(), (l[1] as num?)?.toDouble(), (l[2] as num?)?.toInt());
        }).toList(),
        cols: (j['cols'] as List).map((e) => (e as num).toDouble()).toList(),
      );
}

class SmRow {
  final double s;
  final double? c;
  final int? ax;
  const SmRow(this.s, this.c, this.ax);
}

/// Stock status of a range or a power, as customers see it (status only).
class StockStatus {
  final String state; // in | zero | na | soon | mto
  final int? qty; // simulated pairs on hand: never shown, only used for the cart's shortfall
  final String? eta;
  final bool low; // 'in' but low stock (still orderable)
  const StockStatus(this.state, {this.qty, this.eta, this.low = false});

  /// What customers see (30 Oct): Available · Low stock · Sold out (pre-order) · N/A (not kept).
  static const labels = {'in': 'Available', 'zero': 'Sold out', 'na': 'N/A', 'soon': 'Coming soon', 'mto': 'Made to order'};
  String get label => low && state == 'in' ? 'Low stock' : (labels[state] ?? state);

  static int rank(StockStatus s) => const {'in': 0, 'zero': 1, 'soon': 2, 'mto': 2, 'na': 3}[s.state] ?? 3;

  /// `worst(a, b)` in the HTML app.
  static StockStatus worst(StockStatus a, StockStatus b) => rank(b) > rank(a) ? b : a;
}

/// A product that has the asked power (or the nearest one, one step away).
class Match {
  final Product p;
  final int li;
  final int liL;
  final Rx uR;
  final Rx? uL;
  final bool dR;
  final bool dL;
  final bool diff;
  final bool mto;
  final int mi;
  const Match({
    required this.p,
    required this.li,
    required this.liL,
    required this.uR,
    this.uL,
    this.dR = false,
    this.dL = false,
    this.diff = false,
    this.mto = false,
    this.mi = 0,
  });

  Match withIndex(int i) => Match(p: p, li: li, liL: liL, uR: uR, uL: uL, dR: dR, dL: dL, diff: diff, mto: mto, mi: i);
}

class GridRow {
  final String key;
  final double s;
  final double c;
  final int ax;
  String label;
  GridRow({required this.key, required this.s, required this.c, required this.ax, required this.label});
}

/// The bulk-order power grid for one price line.
class PowerGrid {
  final bool isAdd;
  final List<GridRow> rows;
  final List<double> cols;
  final Set<String> cells;
  final String? sm;
  final String? smt;
  const PowerGrid({required this.isAdd, required this.rows, required this.cols, required this.cells, this.sm, this.smt});
}

/// A cart line. kind: 'one' (parcel), 'grid' (stock order), 'rxreq' (RX request).
class CartLine {
  String kind;
  int? pid;
  int li;
  int? liL;
  double qR;
  double qL;
  double qty; // pairs
  double price; // per pair
  Rx rx;
  Rx? rxL;
  bool diff;
  Rx? wantR;
  Rx? wantL;
  String stock;
  Map<String, double> grid; // grid key -> pairs (or lenses for one-eye progressive)
  String eye; // grid lines: 'P' pair, 'R' / 'L' one-eye progressive
  double? lenses; // one-eye grid lines: number of lenses
  int cells;
  int list;
  String? lt;
  String ref;
  String note;
  String pref;

  /// Which order the line belongs to (5 Nov 2026): 'parcel' or 'bulk'; null = by kind (grid lines bulk, others parcel).
  String? grp;

  /// The line came from a brand, search, favourites, Shop by range or a product page: the customer picks Parcel or
  /// Bulk in the cart ("Order as").
  bool free;

  CartLine({
    required this.kind,
    this.pid,
    this.li = 0,
    this.liL,
    this.qR = 0,
    this.qL = 0,
    this.qty = 0,
    this.price = 0,
    this.rx = const Rx(sph: 0, cyl: 0, axis: 90, add: 2),
    this.rxL,
    this.diff = false,
    this.wantR,
    this.wantL,
    this.stock = 'in',
    Map<String, double>? grid,
    this.eye = 'P',
    this.lenses,
    this.cells = 0,
    this.list = 0,
    this.lt,
    this.ref = '',
    this.note = '',
    this.pref = '',
    this.grp,
    this.free = false,
  }) : grid = grid ?? {};

  /// `cgroup(c)`: the order this line is checked out with.
  String get group => grp ?? (kind == 'grid' ? 'bulk' : 'parcel');

  CartLine copy() => CartLine(
        kind: kind,
        pid: pid,
        li: li,
        liL: liL,
        qR: qR,
        qL: qL,
        qty: qty,
        price: price,
        rx: rx,
        rxL: rxL,
        diff: diff,
        wantR: wantR,
        wantL: wantL,
        stock: stock,
        grid: Map.of(grid),
        eye: eye,
        lenses: lenses,
        cells: cells,
        list: list,
        lt: lt,
        ref: ref,
        note: note,
        pref: pref,
        grp: grp,
        free: free,
      );
}

/// A past order the shop can repeat (simulated history).
class PastOrder {
  final String id;
  final String date;
  final String kind;
  final String desc;
  final List<(int pid, Rx rx)> lines;
  final int? pid;
  final int? li;
  final String? seed;
  const PastOrder({required this.id, required this.date, required this.kind, required this.desc, this.lines = const [], this.pid, this.li, this.seed});

  factory PastOrder.fromJson(Map<String, dynamic> j) => PastOrder(
        id: j['id'] as String,
        date: j['date'] as String,
        kind: j['kind'] as String,
        desc: j['desc'] as String,
        lines: ((j['lines'] as List?) ?? const []).map((l) => ((l['pid'] as num).toInt(), Rx.fromJson(l['rx'] as Map<String, dynamic>))).toList(),
        pid: (j['pid'] as num?)?.toInt(),
        li: (j['li'] as num?)?.toInt(),
        seed: j['seed'] as String?,
      );
}

/// The shop the app is signed in as (simulated for the prototype).
class Customer {
  final String name;
  final String tier;
  final double tierFactor;
  final int limit;
  final int outstanding;
  const Customer({required this.name, required this.tier, required this.tierFactor, required this.limit, required this.outstanding});
  factory Customer.fromJson(Map<String, dynamic> j) => Customer(
        name: j['name'] as String,
        tier: j['tier'] as String,
        tierFactor: (j['tierFactor'] as num).toDouble(),
        limit: (j['limit'] as num).toInt(),
        outstanding: (j['outstanding'] as num).toInt(),
      );
}
