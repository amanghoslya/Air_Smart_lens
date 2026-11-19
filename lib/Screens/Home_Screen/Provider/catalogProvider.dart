import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:air_smart_lens/core/AuthService/AuthService.dart';
import 'package:air_smart_lens/core/AuthService/AuthServiceProvider.dart';
import 'package:air_smart_lens/core/Data/BodyModel/catalogBodyModel.dart';
import 'package:air_smart_lens/core/Data/responseModel/catalogResModel.dart';

class CatalogState {
  final bool isLoading;
  final bool isLoadMore;
  final CatalogResModel? data;
  final List<BrandElement> lensTypes;
  final List<ListElement> products;
  final int pageNo;
  final int limit;
  final bool hasNextPage;
  final String? error;

  const CatalogState({
    this.isLoading = false,
    this.isLoadMore = false,
    this.data,
    this.lensTypes = const [],
    this.products = const [],
    this.pageNo = 1,
    this.limit = 10,
    this.hasNextPage = true,
    this.error,
  });

  CatalogState copyWith({
    bool? isLoading,
    bool? isLoadMore,
    CatalogResModel? data,
    List<BrandElement>? lensTypes,
    List<ListElement>? products,
    int? pageNo,
    int? limit,
    bool? hasNextPage,
    String? error,
  }) {
    return CatalogState(
      isLoading: isLoading ?? this.isLoading,
      isLoadMore: isLoadMore ?? this.isLoadMore,
      data: data ?? this.data,
      lensTypes: lensTypes ?? this.lensTypes,
      products: products ?? this.products,
      pageNo: pageNo ?? this.pageNo,
      limit: limit ?? this.limit,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      error: error,
    );
  }
}

class CatalogNotifier extends StateNotifier<CatalogState> {
  final Ref ref;

  CatalogNotifier(this.ref) : super(const CatalogState(isLoading: true)) {
    getCatalogData();
  }

  /// Default Catalog API (first page or refresh)
  Future<void> getCatalogData({bool isRefresh = false}) async {
    if (!isRefresh && state.lensTypes.isNotEmpty) {
      if (state.isLoading) state = state.copyWith(isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final service = ref.read(authServiceProvider);

      final response = await service.catalogData(
        pageNo: 1,
        limit: state.limit,
        brand: '',
        index: '',
        lensType: '',
        base: '',
        coating: '',
        search: '',
        sortBy: '',
      );

      final lensTypes = response.data?.facets?.lensTypes ?? [];
      final products = response.data?.list ?? [];
      final hasNext = response.data?.hasNextPage ?? (products.length >= state.limit);

      state = state.copyWith(
        isLoading: false,
        data: response,
        lensTypes: lensTypes,
        products: products,
        pageNo: 1,
        hasNextPage: hasNext,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Pagination: load next page on scroll
  Future<void> loadMoreCatalogData() async {
    if (state.isLoading || state.isLoadMore || !state.hasNextPage) return;

    state = state.copyWith(isLoadMore: true);

    try {
      final service = ref.read(authServiceProvider);
      final nextPage = state.pageNo + 1;

      final response = await service.catalogData(
        pageNo: nextPage,
        limit: state.limit,
        brand: '',
        index: '',
        lensType: '',
        base: '',
        coating: '',
        search: '',
        sortBy: '',
      );

      final newLensTypes = response.data?.facets?.lensTypes ?? [];
      final newProducts = response.data?.list ?? [];

      // Merge lens types without duplicates by name
      final mergedLensTypes = List<BrandElement>.from(state.lensTypes);
      for (final item in newLensTypes) {
        final idx = mergedLensTypes.indexWhere(
          (e) => (e.name ?? '').trim().toLowerCase() == (item.name ?? '').trim().toLowerCase(),
        );
        if (idx != -1) {
          mergedLensTypes[idx] = item;
        } else {
          mergedLensTypes.add(item);
        }
      }

      final mergedProducts = [...state.products, ...newProducts];
      final hasNext = response.data?.hasNextPage ?? (newProducts.length >= state.limit);

      state = state.copyWith(
        isLoadMore: false,
        data: response,
        lensTypes: mergedLensTypes,
        products: mergedProducts,
        pageNo: nextPage,
        hasNextPage: hasNext,
      );
    } catch (e) {
      state = state.copyWith(isLoadMore: false);
    }
  }

  /// Filter Catalog API
  Future<void> filterCatalogData(CatalogeBodyModel body) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final service = ref.read(authServiceProvider);

      final response = await service.catalogData(body: body);

      final lensTypes = response.data?.facets?.lensTypes ?? [];
      final products = response.data?.list ?? [];
      final hasNext = response.data?.hasNextPage ?? (products.length >= (body.limit ?? state.limit));

      state = state.copyWith(
        isLoading: false,
        data: response,
        lensTypes: lensTypes,
        products: products,
        pageNo: body.pageNo ?? 1,
        hasNextPage: hasNext,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Clear Catalog Data
  void clearCatalogData() {
    state = const CatalogState();
  }
}

/// Catalog StateNotifier Provider
final catalogProvider = StateNotifierProvider<CatalogNotifier, CatalogState>((ref) {
  return CatalogNotifier(ref);
});

/// Resolves the app's LensType key ('SV', 'KT', 'PROG') to the exact `lens_type`
/// string returned by the backend catalog facets.
String resolveApiLensType(String appLensType, List<BrandElement> apiLensTypes) {
  for (final item in apiLensTypes) {
    final name = item.name?.trim() ?? '';
    if (name.isEmpty) continue;
    final clean = name.toLowerCase().replaceAll(RegExp(r'[\s_-]'), '');
    if (appLensType == 'SV' && (clean.contains('single') || clean == 'sv')) return name;
    if (appLensType == 'KT' && clean.contains('kt')) return name;
    if (appLensType == 'PROG' && clean.contains('prog')) return name;
    if (name.toLowerCase() == appLensType.trim().toLowerCase()) return name;
  }
  return appLensType;
}

/// Query key for live API filtering on Lens Options & Results screens.
typedef LensFilterQuery = ({String appLensType, String indicesKey, String coatingsKey});

String buildFilterKey(Set<String> values) {
  if (values.isEmpty) return '';
  final sorted = values.toList()..sort();
  return sorted.join('|');
}

String resolveApiCoatingKey(CoatingElement item) {
  final raw = (item.code?.trim().isNotEmpty == true ? item.code! : (item.name ?? '')).split('(').first.trim().toUpperCase();
  if (raw.isEmpty || raw == 'NONE' || raw == 'HARD COATING') return 'HC';
  if (raw.startsWith('OPAL')) return 'OPAL';
  if (raw.startsWith('SHINE')) return 'SHINE';
  return raw;
}

String _resolveApiCoatingValue(String coatKey, CatalogResModel? baseRes) {
  final facets = baseRes?.data?.facets?.coatings ?? const <CoatingElement>[];
  final products = baseRes?.data?.list ?? const <ListElement>[];

  for (final c in facets) {
    if (resolveApiCoatingKey(c) != coatKey) continue;
    final cCode = (c.code ?? '').trim();
    final cName = (c.name ?? '').trim();
    for (final p in products) {
      final pCoat = (p.coating ?? '').trim();
      if (pCoat.isEmpty) continue;
      if (cCode.isNotEmpty && pCoat.toLowerCase() == cCode.toLowerCase()) return pCoat;
      if (cName.isNotEmpty && pCoat.toLowerCase() == cName.toLowerCase()) return pCoat;
    }
  }

  for (final p in products) {
    final pCoat = (p.coating ?? '').trim();
    if (pCoat.isEmpty) continue;
    if (resolveApiCoatingKey(CoatingElement(name: pCoat, code: pCoat)) == coatKey) {
      return pCoat;
    }
  }

  for (final c in facets) {
    if (resolveApiCoatingKey(c) != coatKey) continue;
    if (c.code?.trim().isNotEmpty == true) return c.code!.trim();
    if (c.name?.trim().isNotEmpty == true) return c.name!.trim();
  }

  return coatKey;
}

Future<CatalogResModel> _fetchAllCatalogPages(
  AuthService service, {
  required String lensType,
  dynamic index = '',
  String coating = '',
}) async {
  final first = await service.catalogData(
    pageNo: 1,
    limit: 100,
    brand: '',
    index: index,
    lensType: lensType,
    base: '',
    coating: coating,
    search: '',
    sortBy: '',
  ); 

  final firstData = first.data;
  if (firstData == null) return first;

  final allItems = List<ListElement>.from(firstData.list ?? const <ListElement>[]);
  final totalPages = firstData.totalPages ?? 1;
  var hasNext = firstData.hasNextPage ?? (firstData.total != null && allItems.length < firstData.total!);
  var page = 1;

  while (hasNext && page < totalPages && page < 10) {
    page++;
    final next = await service.catalogData(
      pageNo: page,
      limit: 100,
      brand: '',
      index: index,
      lensType: lensType,
      base: '',
      coating: coating,
      search: '',
      sortBy: '',
    );
    final nextItems = next.data?.list ?? const <ListElement>[];
    if (nextItems.isEmpty) break;
    allItems.addAll(nextItems);
    hasNext = next.data?.hasNextPage ?? false;
  }

  return CatalogResModel(
    message: first.message,
    code: first.code,
    error: first.error,
    data: Data(
      total: firstData.total ?? allItems.length,
      totalPages: firstData.totalPages,
      pageNo: page,
      limit: firstData.limit,
      hasNextPage: hasNext,
      hasPrevPage: firstData.hasPrevPage,
      tabCounts: firstData.tabCounts,
      facets: firstData.facets,
      list: allItems,
    ),
  );
}

/// Fetches catalog facets (lens indices & coatings) and all products filtered by the selected lens type.
final lensOptionsProvider = FutureProvider.autoDispose.family<CatalogResModel, String>((ref, appLensType) async {
  final service = ref.read(authServiceProvider);

  var lensTypes = ref.read(catalogProvider).lensTypes;
  if (lensTypes.isEmpty) {
    await ref.read(catalogProvider.notifier).getCatalogData();
    lensTypes = ref.read(catalogProvider).lensTypes;
  }

  final apiLensType = resolveApiLensType(appLensType, lensTypes);
  return await _fetchAllCatalogPages(service, lensType: apiLensType);
});

/// Fetches live filtered catalog data from API whenever lens type, lens index, or coating changes
/// (or when the user taps the Show lenses button).
final filteredLensCatalogProvider = FutureProvider.autoDispose.family<CatalogResModel, LensFilterQuery>((ref, query) async {
  final service = ref.read(authServiceProvider);

  var lensTypes = ref.read(catalogProvider).lensTypes;
  if (lensTypes.isEmpty) {
    await ref.read(catalogProvider.notifier).getCatalogData();
    lensTypes = ref.read(catalogProvider).lensTypes;
  }

  final apiLensType = resolveApiLensType(query.appLensType, lensTypes);

  final selectedIndices = query.indicesKey.isEmpty
      ? <String>[]
      : query.indicesKey.split('|').where((e) => e.trim().isNotEmpty).toList();
  final selectedCoatings = query.coatingsKey.isEmpty
      ? <String>[]
      : query.coatingsKey.split('|').where((e) => e.trim().isNotEmpty).toList();

  if (selectedIndices.isEmpty && selectedCoatings.isEmpty) {
    return await _fetchAllCatalogPages(service, lensType: apiLensType);
  }

  final baseRes = ref.read(lensOptionsProvider(query.appLensType)).valueOrNull;

  final indexParams = selectedIndices.isEmpty
      ? <dynamic>['']
      : selectedIndices.map<dynamic>((v) => double.tryParse(v) ?? v).toList();
  final coatingParams = selectedCoatings.isEmpty
      ? <String>['']
      : selectedCoatings.map((k) => _resolveApiCoatingValue(k, baseRes)).toList();

  if (indexParams.length == 1 && coatingParams.length == 1) {
    return await _fetchAllCatalogPages(
      service,
      lensType: apiLensType,
      index: indexParams.first,
      coating: coatingParams.first,
    );
  }

  final futures = <Future<CatalogResModel>>[];
  for (final idx in indexParams) {
    for (final coat in coatingParams) {
      futures.add(
        _fetchAllCatalogPages(
          service,
          lensType: apiLensType,
          index: idx,
          coating: coat,
        ),
      );
    }
  }
  final responses = await Future.wait(futures);
  final seenIds = <String>{};
  final merged = <ListElement>[];
  for (final r in responses) {
    for (final item in r.data?.list ?? const <ListElement>[]) {
      final key = (item.id?.trim().isNotEmpty == true)
          ? item.id!.trim()
          : '${item.brand}|${item.productName}|${item.coating}|${item.index}|${item.rangeLabel}|${item.productCode}';
      if (seenIds.add(key)) {
        merged.add(item);
      }
    }
  }

  final first = responses.first;
  return CatalogResModel(
    message: first.message,
    code: first.code,
    error: first.error,
    data: Data(
      total: merged.length,
      totalPages: 1,
      pageNo: 1,
      limit: merged.length,
      hasNextPage: false,
      hasPrevPage: false,
      tabCounts: first.data?.tabCounts,
      facets: first.data?.facets,
      list: merged,
    ),
  );
});
