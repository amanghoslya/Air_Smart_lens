import 'package:air_smart_lens/core/Data/BodyModel/catalogBodyModel.dart';
import 'package:air_smart_lens/core/Data/BodyModel/sendOtpBodyModel.dart';
import 'package:air_smart_lens/core/Data/BodyModel/verifyOtpBodyModel.dart';
import 'package:air_smart_lens/core/Data/responseModel/brandsResModel.dart';
import 'package:air_smart_lens/core/Data/responseModel/catalogResModel.dart' hide LensType;
import 'package:air_smart_lens/core/Data/responseModel/getProfileResModel.dart' hide Data;
import 'package:air_smart_lens/core/Data/responseModel/productDetailsResModel.dart';
import 'package:air_smart_lens/core/Data/responseModel/verifyOtpResModel.dart';
import 'package:air_smart_lens/core/Network/apistate.dart';

import '../Data/responseModel/sendOtpResModel.dart';

class AuthService {
  final ApiState api;

  AuthService(this.api);

  Future<SendOtpResModel> sendOTP({
    required String phone,
    required String deviceId,
  }) async {
    try {
      final body = SendOtpBodyModel(
        phone: phone,
        deviceId: deviceId,
        platform: "app",
      );
      final response = await api.sendOTP(body);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<VerifyOtpResModel> verifyOtpData({
    required String phone,
    required String otp,
    required String deviceId,
    required String deviceName,
    required String platform,
  }) async {
    try {
      final body = VerifyOtpBodyModel(
        deviceId: deviceId,
        otp: otp,
        deviceName: deviceName,
        phone: phone,
        platform: platform,
      );
      final response = await api.verifyOtp(body);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<GetProfileResModel> getProfileData() async {
    try {
      final response = await api.getProfile();
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<BrandsResModel> getBrandsData() async {
    try {
      return await api.getBrands();
    } catch (e) {
      rethrow;
    }
  }

  Future<CatalogResModel> catalogData({
    CatalogeBodyModel? body,
    int? pageNo,
    int? limit,
    String? brand,
    dynamic index,
    String? lensType,
    String? base,
    String? coating,
    String? search,
    String? sortBy,
  }) async {
    try {
      final requestBody = body ??
          CatalogeBodyModel(
            pageNo: pageNo,
            limit: limit,
            brand: brand,
            index: index,
            lensType: lensType,
            base: base,
            coating: coating,
            search: search,
            sortBy: sortBy,
          );
      final response = await api.filterCatalog(requestBody);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<ProductDetailsResModel> productDetailsData({
    required String id,
  }) async {
    try {
      final response = await api.productDetails(id);
      return response;
    } catch (e) {
      rethrow;
    }
  }
  Future<searchPowerResModel> searchPowerData({
  String? lensType,
  int? sph,
  double? cyl,
  String? brand,
  int? axis,
  int? add,
  String? index,
  String? coating,
  bool? availableOnly,
}) async {
  try {
    final requestBody = {
      "lens_type": lensType,
      "sph": sph,
      "cyl": cyl,
      "brand": brand ?? "",
      "axis": axis ?? 0,
      "add": add ?? 0,
      "index": index ?? "",
      "coating": coating ?? "",
      "available_only": availableOnly ?? true,
    };

    final response = await api.searchPower(requestBody);

    return response;
  } catch (e) {
    rethrow;
  }
}
}
