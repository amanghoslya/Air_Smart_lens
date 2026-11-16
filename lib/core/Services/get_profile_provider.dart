import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:air_smart_lens/core/AuthService/AuthServiceProvider.dart';
import 'package:air_smart_lens/core/Data/responseModel/getProfileResModel.dart';

final getProfileProvider = FutureProvider.autoDispose<GetProfileResModel>((ref) async {
  final service = ref.read(authServiceProvider);
  return await service.getProfileData();
});

