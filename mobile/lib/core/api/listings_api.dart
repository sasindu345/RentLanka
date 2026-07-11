import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/api/api_client.dart';
import 'package:mobile/core/models/listing.dart';
import 'package:mobile/core/storage/token_storage.dart';
import 'package:mobile/core/services/notification_service.dart';

final listingsApiProvider = Provider((ref) {
  return ListingsApi(
    ref.watch(dioProvider),
    ref.watch(tokenStorageProvider),
    ref,
  );
});

class ListingsApi {
  final Dio _dio;
  final TokenStorage _storage;
  final Ref _ref;

  ListingsApi(this._dio, this._storage, this._ref);

  Future<void> login(String email, String password) async {
    final response = await _dio.post(
      '/api/auth/login',
      data: {'email': email, 'password': password},
    );
    final token = response.data['token'] as String;
    final refreshToken = response.data['refreshToken'] as String;
    await _storage.saveTokens(token, refreshToken);

    // Register FCM Device Token for the newly logged-in user
    await _ref.read(notificationServiceProvider).registerToken();
  }

  Future<String> loginWithGoogle({
    String? idToken,
    String? email,
    String? firstName,
    String? lastName,
    String? role,
  }) async {
    final response = await _dio.post(
      '/api/auth/google',
      data: {
        'idToken': idToken,
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'role': role,
      },
    );
    final token = response.data['token'] as String;
    final refreshToken = response.data['refreshToken'] as String;
    final returnedRole = response.data['role'] as String;
    await _storage.saveTokens(token, refreshToken);

    // Register FCM Device Token for the newly logged-in user
    await _ref.read(notificationServiceProvider).registerToken();

    return returnedRole;
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String role,
  }) async {
    final response = await _dio.post(
      '/api/auth/register',
      data: {
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
        'phoneNumber': phoneNumber,
        'role': role,
      },
    );
    await login(email, password);
    return response.data as Map<String, dynamic>;
  }

  Future<void> logout() async {
    await _ref.read(notificationServiceProvider).resetForLogout();
    await _storage.clearToken();
  }

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
    String? role,
  }) async {
    final response = await _dio.patch(
      '/api/users/me',
      data: {
        'firstName': firstName,
        'lastName': lastName,
        'phoneNumber': phoneNumber,
        'role': role,
      },
    );
    return UserProfile.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PaginatedListings> searchListings({
    String? query,
    String? category,
    String? district,
    double? lat,
    double? lon,
    double? distanceMeters,
    int page = 1,
    int pageSize = 20,
    String sortBy = 'newest',
  }) async {
    // If text query is provided and no coordinates are given, use the AI Semantic Search endpoint
    if (query != null && query.isNotEmpty && lat == null && lon == null) {
      final response = await _dio.get(
        '/api/ai/search',
        queryParameters: {'query': query},
      );
      final items = (response.data as List<dynamic>)
          .map((e) => Listing.fromJson(e as Map<String, dynamic>))
          .toList();
      return PaginatedListings(
        items: items,
        total: items.length,
        page: 1,
        pageSize: items.length,
      );
    }

    // Default category/feed filter and spatial proximity search
    final response = await _dio.get(
      '/api/listings/search',
      queryParameters: {
        if (query != null && query.isNotEmpty) 'query': query,
        if (category != null && category.isNotEmpty) 'category': category,
        if (district != null && district.isNotEmpty) 'district': district,
        'lat': ?lat,
        'lon': ?lon,
        'distanceMeters': ?distanceMeters,
        'page': page,
        'pageSize': pageSize,
        'sortBy': sortBy,
      },
    );
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
    final response = await _dio.get(
      '/api/wishlist',
      queryParameters: {'page': page},
    );
    return PaginatedListings.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> addToWishlist(String listingId) async {
    await _dio.post('/api/wishlist/$listingId');
  }

  Future<void> removeFromWishlist(String listingId) async {
    await _dio.delete('/api/wishlist/$listingId');
  }

  Future<List<String>> getCategories() async {
    final response = await _dio.get('/api/settings');
    final list = response.data['categories'] as List<dynamic>;
    return list.map((e) => e as String).toList();
  }

  Future<AiListingSuggestion> generateListingSuggestion({
    required String imageUrl,
    String? categoryHint,
  }) async {
    final response = await _dio.post(
      '/api/ai/generate-listing',
      data: {
        'imageUrl': imageUrl,
        if (categoryHint != null && categoryHint.isNotEmpty)
          'categoryHint': categoryHint,
      },
    );
    return AiListingSuggestion.fromJson(response.data as Map<String, dynamic>);
  }

  static String formatPrice(double amount) {
    return 'LKR ${amount.toStringAsFixed(0)}';
  }
}

class AiListingSuggestion {
  final String title;
  final String description;
  final String category;
  final double suggestedPricePerDay;
  final double suggestedSecurityDeposit;

  AiListingSuggestion({
    required this.title,
    required this.description,
    required this.category,
    required this.suggestedPricePerDay,
    required this.suggestedSecurityDeposit,
  });

  factory AiListingSuggestion.fromJson(Map<String, dynamic> json) {
    return AiListingSuggestion(
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? '',
      suggestedPricePerDay:
          (json['suggestedPricePerDay'] as num?)?.toDouble() ?? 0.0,
      suggestedSecurityDeposit:
          (json['suggestedSecurityDeposit'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
