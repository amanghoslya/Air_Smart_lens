import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

Dio createDio() {
  Dio dio = Dio();

  // Pretty Dio Logger
  dio.interceptors.add(
    PrettyDioLogger(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseHeader: true,
      responseBody: true,
    ),
  );

  // Custom Interceptor
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        try {
          if (Hive.isBoxOpen('userdata')) {
            final token = Hive.box('userdata').get('token');
            if (token != null && token.toString().trim().isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
        } catch (_) {}
        return handler.next(options);
      },

      onResponse: (response, handler) {
        return handler.next(response);
      },

      onError: (DioException error, handler) {
        // Extract API error message using getDioErrorMessage
        final message = getDioErrorMessage(error);

        // Forward error with the clean server message
        return handler.next(error.copyWith(message: message, error: message));
      },
    ),
  );

  return dio;
}

// Common API Error Message
String getDioErrorMessage(DioException error) {
  dynamic data = error.response?.data;

  // If response body is a JSON string, decode it
  if (data is String) {
    try {
      data = jsonDecode(data);
    } catch (_) {}
  }

  if (data is Map) {
    final message = data['message'] ?? data['error'] ?? data['msg'];

    if (message != null && message.toString().isNotEmpty) {
      return message.toString();
    }
  }

  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return 'Connection timed out. Please try again.';

    case DioExceptionType.connectionError:
      return 'No internet connection.';

    case DioExceptionType.cancel:
      return 'Request cancelled.';

    default:
      if (error.message != null && error.message!.isNotEmpty) {
        return error.message!;
      }
      return 'Something went wrong. Please try again.'; 
  }
}
