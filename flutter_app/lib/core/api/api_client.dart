import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// API Client Provider
final apiClientProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    // Update with Cloud Run URL for production
    baseUrl: 'http://localhost:8000', // Right now, it matches local backend port
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ));

  // Add logging interceptor for debug
  dio.interceptors.add(LogInterceptor(
    requestBody: true,
    responseBody: true,
    logPrint: (obj) => print('🌐 API: $obj'),
  ));

  return dio;
});
