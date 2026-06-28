import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/api/api_client.dart';

final disputesApiProvider = Provider((ref) {
  return DisputesApi(ref.watch(dioProvider));
});

class DisputeResponse {
  final String id;
  final String bookingId;
  final String listingTitle;
  final String createdById;
  final String createdByName;
  final String reason;
  final bool isResolved;
  final String? adminDecision;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? resolvedByName;

  DisputeResponse({
    required this.id,
    required this.bookingId,
    required this.listingTitle,
    required this.createdById,
    required this.createdByName,
    required this.reason,
    required this.isResolved,
    this.adminDecision,
    required this.createdAt,
    this.resolvedAt,
    this.resolvedByName,
  });

  factory DisputeResponse.fromJson(Map<String, dynamic> json) {
    return DisputeResponse(
      id: json['id'] as String,
      bookingId: json['bookingId'] as String,
      listingTitle: json['listingTitle'] as String,
      createdById: json['createdById'] as String,
      createdByName: json['createdByName'] as String,
      reason: json['reason'] as String,
      isResolved: json['isResolved'] as bool,
      adminDecision: json['adminDecision'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      resolvedAt: json['resolvedAt'] != null ? DateTime.parse(json['resolvedAt'] as String) : null,
      resolvedByName: json['resolvedByName'] as String?,
    );
  }
}

class DisputesApi {
  final Dio _dio;

  DisputesApi(this._dio);

  Future<DisputeResponse> fileDispute(String bookingId, String reason) async {
    final response = await _dio.post('/api/disputes', data: {
      'bookingId': bookingId,
      'reason': reason,
    });
    return DisputeResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<DisputeResponse>> getMyDisputes() async {
    final response = await _dio.get('/api/disputes/mine');
    return (response.data as List<dynamic>)
        .map((e) => DisputeResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
