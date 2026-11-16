import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:air_smart_lens/core/AuthService/AuthService.dart';
import 'package:air_smart_lens/core/Network/apistate.dart';
import 'package:air_smart_lens/core/Utils/pretty.dio.dart';

final dioProvider = Provider<Dio>((ref) {
  return createDio();
});

final apiProvider = Provider((ref) {
  final dio = ref.read(dioProvider);
  return ApiState(dio);
});

final authServiceProvider = Provider((ref) {
  final api = ref.read(apiProvider);
  return AuthService(api);
});
