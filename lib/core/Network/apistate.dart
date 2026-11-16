import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:air_smart_lens/core/Data/BodyModel/sendOtpBodyModel.dart';
import 'package:air_smart_lens/core/Data/BodyModel/verifyOtpBodyModel.dart';
import 'package:air_smart_lens/core/Data/responseModel/brandsResModel.dart';
import 'package:air_smart_lens/core/Data/responseModel/getProfileResModel.dart';
import 'package:air_smart_lens/core/Data/responseModel/verifyOtpResModel.dart';

import '../Data/responseModel/sendOtpResModel.dart';

part 'apistate.g.dart';

@RestApi(baseUrl: 'https://opticale-backend.onrender.com/api/v1')
abstract class ApiState {
  factory ApiState(Dio dio, {String baseUrl}) = _ApiState;

  @POST('/customer/send-login-otp')
  Future<SendOtpResModel> sendOTP(@Body() SendOtpBodyModel body);

  @POST('/customer/verify-login-otp')
  Future<VerifyOtpResModel> verifyOtp(@Body() VerifyOtpBodyModel body);

  @GET('/customer/profile')
  Future<GetProfileResModel> getProfile();

  @GET('/customer/brands')
  Future<BrandsResModel> getBrands();
}
