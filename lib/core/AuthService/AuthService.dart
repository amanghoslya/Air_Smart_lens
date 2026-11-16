import 'package:air_smart_lens/core/Data/BodyModel/sendOtpBodyModel.dart';
import 'package:air_smart_lens/core/Data/BodyModel/verifyOtpBodyModel.dart';
import 'package:air_smart_lens/core/Data/responseModel/getProfileResModel.dart' hide Data;
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
}
