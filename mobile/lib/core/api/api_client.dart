import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/constants.dart';
import 'package:mobile/core/storage/token_storage.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

final tokenStorageProvider = Provider((ref) => TokenStorage());

final dioProvider = Provider((ref) {
  final storage = ref.watch(tokenStorageProvider);
  final dio = Dio(BaseOptions(
    baseUrl: apiBaseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    headers: {'Content-Type': 'application/json'},
  ));

  dio.interceptors.add(QueuedInterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await storage.getToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    },
    onError: (error, handler) async {
      final response = error.response;
      // Trigger token refresh only on 401, if we have stored credentials, and not already on the refresh route
      if (response?.statusCode == 401 && error.requestOptions.path != '/api/auth/refresh') {
        final currentToken = await storage.getToken();
        final currentRefreshToken = await storage.getRefreshToken();

        if (currentToken != null && currentRefreshToken != null) {
          try {
            // Create a dedicated client for token refresh to avoid looping
            final refreshDio = Dio(BaseOptions(
              baseUrl: apiBaseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ));

            final refreshResponse = await refreshDio.post('/api/auth/refresh', data: {
              'token': currentToken,
              'refreshToken': currentRefreshToken,
            });

            if (refreshResponse.statusCode == 200 || refreshResponse.statusCode == 201) {
              final newToken = refreshResponse.data['token'] as String;
              final newRefreshToken = refreshResponse.data['refreshToken'] as String;

              await storage.saveTokens(newToken, newRefreshToken);

              // Clone original options and retry
              final options = error.requestOptions;
              options.headers['Authorization'] = 'Bearer $newToken';

              final retryResponse = await dio.request(
                options.path,
                data: options.data,
                queryParameters: options.queryParameters,
                options: Options(
                  method: options.method,
                  headers: options.headers,
                  contentType: options.contentType,
                ),
              );

              return handler.resolve(retryResponse);
            }
          } catch (e) {
            // Token refresh failed or token is revoked, clear credentials
            await storage.clearAll();
          }
        } else {
          await storage.clearAll();
        }
      }
      Sentry.captureException(error, stackTrace: error.stackTrace);
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
