import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:air_smart_lens/core/AuthService/AuthServiceProvider.dart';
import 'package:air_smart_lens/core/Data/responseModel/productDetailsResModel.dart';

/// Fetches full product details by product ID (`GET /customer/product/{id}/detail`).
final productDetailsProvider = FutureProvider.family.autoDispose<ProductDetailsResModel, String>((ref, id) async {
  final service = ref.read(authServiceProvider);
  return await service.productDetailsData(id: id);
});
