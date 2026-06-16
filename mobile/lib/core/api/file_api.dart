import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/api/api_client.dart';

final fileApiProvider = Provider((ref) {
  return FileApi(ref.watch(dioProvider));
});

class FileApi {
  final Dio _dio;

  FileApi(this._dio);

  Future<String> uploadListingImage(String filePath) async {
    final fileName = filePath.split('/').last;
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });
    final response = await _dio.post(
      '/api/file/listing-image',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    final data = response.data as Map<String, dynamic>;
    return data['imageUrl'] as String;
  }

  Future<String> uploadAvatar(String filePath) async {
    final fileName = filePath.split('/').last;
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });
    final response = await _dio.post(
      '/api/file/avatar',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    final data = response.data as Map<String, dynamic>;
    return data['avatarUrl'] as String;
  }
}
