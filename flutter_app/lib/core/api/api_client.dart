import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

/// API Client Provider
final apiClientProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    // Automatic Environment Switching
    baseUrl: kDebugMode 
        ? 'http://localhost:8080' 
        : 'https://agripulse-api-991497139962.asia-south1.run.app', 
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 120),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ));

  // Add logging interceptor for debug
  dio.interceptors.add(LogInterceptor(
    requestBody: true,
    responseBody: true,
    logPrint: (obj) => debugPrint('🌐 API: $obj'),
  ));

  return dio;
});
