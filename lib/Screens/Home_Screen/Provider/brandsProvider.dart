import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:air_smart_lens/core/AuthService/AuthServiceProvider.dart';
import 'package:air_smart_lens/core/Data/responseModel/brandsResModel.dart';

/// Brands for Home's "Shop by brand" (GET /customer/brands).
final brandsProvider = FutureProvider<List<BrandItem>>((ref) async {
  final res = await ref.read(authServiceProvider).getBrandsData();
  return res.data ?? const [];
});
