import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _key = 'rentlanka_token';
  static const _refreshKey = 'rentlanka_refresh_token';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> saveToken(String token) => _storage.write(key: _key, value: token);

  Future<String?> getToken() => _storage.read(key: _key);

  Future<void> clearToken() => _storage.delete(key: _key);

  Future<void> saveRefreshToken(String token) => _storage.write(key: _refreshKey, value: token);

  Future<String?> getRefreshToken() => _storage.read(key: _refreshKey);

  Future<void> clearRefreshToken() => _storage.delete(key: _refreshKey);

  Future<void> saveTokens(String token, String refreshToken) async {
    await saveToken(token);
    await saveRefreshToken(refreshToken);
  }

  Future<void> clearAll() async {
    await clearToken();
    await clearRefreshToken();
  }
}
