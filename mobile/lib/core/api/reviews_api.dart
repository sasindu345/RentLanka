import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/api/api_client.dart';

final reviewsApiProvider = Provider((ref) {
  return ReviewsApi(ref.watch(dioProvider));
});

class ReviewResponse {
  final String id;
  final String bookingId;
  final String reviewerId;
  final String reviewerName;
  final String targetUserId;
  final int rating;
  final String comment;
  final bool isRenterReview;
  final DateTime createdAt;

  ReviewResponse({
    required this.id,
    required this.bookingId,
    required this.reviewerId,
    required this.reviewerName,
    required this.targetUserId,
    required this.rating,
    required this.comment,
    required this.isRenterReview,
    required this.createdAt,
  });

  factory ReviewResponse.fromJson(Map<String, dynamic> json) {
    return ReviewResponse(
      id: json['id'] as String,
      bookingId: json['bookingId'] as String,
      reviewerId: json['reviewerId'] as String,
      reviewerName: json['reviewerName'] as String,
      targetUserId: json['targetUserId'] as String,
      rating: json['rating'] as int,
      comment: json['comment'] as String? ?? '',
      isRenterReview: json['isRenterReview'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class ReviewsApi {
  final Dio _dio;

  ReviewsApi(this._dio);

  Future<ReviewResponse> createReview(String bookingId, int rating, String comment) async {
    final response = await _dio.post('/api/reviews/bookings/$bookingId', data: {
      'rating': rating,
      'comment': comment,
    });
    return ReviewResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<ReviewResponse>> getUserReviews(String userId) async {
    final response = await _dio.get('/api/reviews/users/$userId');
    return (response.data as List<dynamic>)
        .map((e) => ReviewResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ReviewResponse>> getListingReviews(String listingId) async {
    final response = await _dio.get('/api/reviews/listings/$listingId');
    return (response.data as List<dynamic>)
        .map((e) => ReviewResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<double> getUserAverageRating(String userId) async {
    final response = await _dio.get('/api/reviews/users/$userId/average');
    return (response.data['averageRating'] as num).toDouble();
  }

  Future<double> getListingAverageRating(String listingId) async {
    final response = await _dio.get('/api/reviews/listings/$listingId/average');
    return (response.data['averageRating'] as num).toDouble();
  }
}
