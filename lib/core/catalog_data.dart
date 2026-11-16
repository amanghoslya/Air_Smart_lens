/// Parses the bundled JSON data (catalogue, Super Masters, simulated account).
/// Pure Dart: the Flutter layer reads the asset text and hands it here.
library;

import 'dart:convert';

import 'models.dart';

class CatalogMeta {
  final List<int> favs; // "My products"
  final int repeat; // product used for the repeat stock order
  const CatalogMeta({required this.favs, required this.repeat});
}

class CatalogData {
  final List<Product> catalog;
  final CatalogMeta meta;
  final Map<String, SuperMaster> superMasters;
  final Customer customer;
  final List<PastOrder> pastOrders;
  final Map<String, double> imageAspect;
  final Set<String> brandImages;
  final Set<String> envelopes; // envelope photos, one per range (assets/images/envelopes)
  final List<(String, String)> welcome; // welcome posters, a different one at each start
  final List<String> scanSamples; // sample QR codes for the Scan QR screen

  const CatalogData({
    required this.catalog,
    required this.meta,
    required this.superMasters,
    required this.customer,
    required this.pastOrders,
    required this.imageAspect,
    required this.brandImages,
    required this.envelopes,
    required this.welcome,
    required this.scanSamples,
  });

  factory CatalogData.parse({required String catalogJson, required String superMastersJson, required String accountJson}) {
    final c = jsonDecode(catalogJson) as Map<String, dynamic>;
    final sm = jsonDecode(superMastersJson) as Map<String, dynamic>;
    final a = jsonDecode(accountJson) as Map<String, dynamic>;
    final meta = c['meta'] as Map<String, dynamic>;
    return CatalogData(
      catalog: (c['catalog'] as List).map((e) => Product.fromJson(e as Map<String, dynamic>)).toList(),
      meta: CatalogMeta(favs: (meta['favs'] as List).map((e) => (e as num).toInt()).toList(), repeat: (meta['repeat'] as num).toInt()),
      superMasters: {for (final e in sm.entries) e.key: SuperMaster.fromJson(e.key, e.value as Map<String, dynamic>)},
      customer: Customer.fromJson(a['customer'] as Map<String, dynamic>),
      pastOrders: (a['pastOrders'] as List).map((e) => PastOrder.fromJson(e as Map<String, dynamic>)).toList(),
      imageAspect: {for (final e in (a['imageAspect'] as Map<String, dynamic>).entries) e.key: (e.value as num).toDouble()},
      brandImages: (a['brandImages'] as List).cast<String>().toSet(),
      envelopes: (a['envelopes'] as List).cast<String>().toSet(),
      welcome: [for (final w in a['welcome'] as List) ((w as List)[0] as String, w[1] as String)],
      scanSamples: (a['scanSamples'] as List).cast<String>(),
    );
  }
}
