import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/constants.dart';
import 'package:mobile/core/storage/token_storage.dart';

final tokenStorageProvider = Provider((ref) => TokenStorage());

final dioProvider = Provider((ref) {
  final storage = ref.watch(tokenStorageProvider);
  final dio = Dio(BaseOptions(
    baseUrl: apiBaseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    headers: {'Content-Type': 'application/json'},
  ));

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await storage.getToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    },
    onError: (error, handler) async {
      if (error.response?.statusCode == 401) {
        await storage.clearToken();
      }
      handler.next(error);
    },
  ));

  return dio;
});

String extractError(DioException e) {
  final data = e.response?.data;
  if (data is Map && data['error'] != null) {
    return data['error'] as String;
  }
  return e.message ?? 'Request failed';
}
