import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/api/api_client.dart';

final notificationsApiProvider = Provider((ref) {
  return NotificationsApi(ref.watch(dioProvider));
});

class NotificationsApi {
  final Dio _dio;

  NotificationsApi(this._dio);

  Future<void> registerDeviceToken(String token) async {
    final platform = Platform.isAndroid ? 'Android' : 'iOS';
    await _dio.post(
      '/api/notifications/token',
      data: {
        'token': token,
        'platform': platform,
      },
    );
  }
}
