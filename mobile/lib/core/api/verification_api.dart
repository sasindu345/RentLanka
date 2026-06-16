import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/api/api_client.dart';

final verificationApiProvider = Provider((ref) {
  return VerificationApi(ref.watch(dioProvider));
});

class VerificationApi {
  final Dio _dio;

  VerificationApi(this._dio);

  Future<String?> sendEmailToken() async {
    final response = await _dio.post('/api/verification/send-email-token');
    return _readDevCode(response.data, 'devToken');
  }

  Future<void> verifyEmail(String token) async {
    await _dio.post('/api/verification/verify-email', data: {'token': token});
  }

  Future<String?> sendSmsOtp(String phoneNumber) async {
    final response = await _dio.post('/api/verification/send-sms-otp', data: {'phoneNumber': phoneNumber});
    return _readDevCode(response.data, 'devOtp');
  }

  Future<void> verifySmsOtp(String code) async {
    await _dio.post('/api/verification/verify-sms-otp', data: {'code': code});
  }

  Future<void> submitNic({required String nicNumber, required String documentUrl}) async {
    await _dio.post('/api/verification/nic', data: {
      'nicNumber': nicNumber,
      'documentUrl': documentUrl,
    });
  }

  Future<void> verifyFace(String biometricDataHash) async {
    await _dio.post('/api/verification/face', data: {'biometricDataHash': biometricDataHash});
  }

  String? _readDevCode(dynamic data, String key) {
    if (data is! Map) return null;
    final value = data[key];
    return value is String ? value : value?.toString();
  }
}
