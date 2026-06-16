import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/api/api_client.dart';
import 'package:mobile/core/models/listing.dart';
import 'package:mobile/core/storage/token_storage.dart';

final listingsApiProvider = Provider((ref) {
  return ListingsApi(
    ref.watch(dioProvider),
    ref.watch(tokenStorageProvider),
  );
});

class ListingsApi {
  final Dio _dio;
  final TokenStorage _storage;

  ListingsApi(this._dio, this._storage);

  Future<void> login(String email, String password) async {
    final response = await _dio.post('/api/auth/login', data: {
      'email': email,
      'password': password,
    });
    final token = response.data['token'] as String;
    await _storage.saveToken(token);
  }

  Future<void> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phoneNumber,
  }) async {
    await _dio.post('/api/auth/register', data: {
      'email': email,
      'password': password,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
    });
    await login(email, password);
  }

  Future<void> logout() => _storage.clearToken();

  Future<bool> isLoggedIn() async {
    final token = await _storage.getToken();
    return token != null && token.isNotEmpty;
  }

  Future<UserProfile> getCurrentUser() async {
    final response = await _dio.get('/api/users/me');
    return UserProfile.fromJson(response.data as Map<String, dynamic>);
  }

  Future<UserProfile> updateProfile({
    required String firstName,
    required String lastName,
    required String phoneNumber,
  }) async {
    final response = await _dio.patch('/api/users/me', data: {
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
    });
    return UserProfile.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PaginatedListings> searchListings({
    String? query,
    String? category,
    String? district,
    int page = 1,
    int pageSize = 20,
    String sortBy = 'newest',
  }) async {
    final response = await _dio.get('/api/listings/search', queryParameters: {
      if (query != null && query.isNotEmpty) 'query': query,
      if (category != null && category.isNotEmpty) 'category': category,
      if (district != null && district.isNotEmpty) 'district': district,
      'page': page,
      'pageSize': pageSize,
      'sortBy': sortBy,
    });
    return PaginatedListings.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Listing> getListing(String id) async {
    final response = await _dio.get('/api/listings/$id');
    return Listing.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Listing> createListing(Map<String, dynamic> data) async {
    final response = await _dio.post('/api/listings', data: data);
    return Listing.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Listing> updateListing(String id, Map<String, dynamic> data) async {
    final response = await _dio.put('/api/listings/$id', data: data);
    return Listing.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Listing> togglePauseListing(String id) async {
    final response = await _dio.patch('/api/listings/$id/pause');
    return Listing.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteListing(String id) async {
    await _dio.delete('/api/listings/$id');
  }

  Future<List<Listing>> getMyListings() async {
    final response = await _dio.get('/api/listings/mine');
    return (response.data as List<dynamic>)
        .map((e) => Listing.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PaginatedListings> getWishlist({int page = 1}) async {
    final response = await _dio.get('/api/wishlist', queryParameters: {'page': page});
    return PaginatedListings.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> addToWishlist(String listingId) async {
    await _dio.post('/api/wishlist/$listingId');
  }

  Future<void> removeFromWishlist(String listingId) async {
    await _dio.delete('/api/wishlist/$listingId');
  }

  static String formatPrice(double amount) {
    return 'LKR ${amount.toStringAsFixed(0)}';
  }
}
