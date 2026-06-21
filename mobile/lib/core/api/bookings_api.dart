import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/api/api_client.dart';

final bookingsApiProvider = Provider((ref) {
  return BookingsApi(ref.watch(dioProvider));
});

class BookingsApi {
  final Dio _dio;

  BookingsApi(this._dio);

  // --- Bookings Endpoints ---

  Future<BookingResponse> createBooking(String listingId, DateTime start, DateTime end) async {
    final response = await _dio.post('/api/bookings', data: {
      'listingId': listingId,
      'startDate': start.toIso8601String(),
      'endDate': end.toIso8601String(),
    });
    return BookingResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<BookingResponse> getBookingById(String id) async {
    final response = await _dio.get('/api/bookings/$id');
    return BookingResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<BookingResponse>> getRenterBookings() async {
    final response = await _dio.get('/api/bookings/renter');
    return (response.data as List<dynamic>)
        .map((e) => BookingResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<BookingResponse>> getOwnerBookings() async {
    final response = await _dio.get('/api/bookings/owner');
    return (response.data as List<dynamic>)
        .map((e) => BookingResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> approveBooking(String id) async {
    await _dio.patch('/api/bookings/$id/approve');
  }

  Future<void> rejectBooking(String id) async {
    await _dio.patch('/api/bookings/$id/reject');
  }

  Future<void> payBooking(String id) async {
    await _dio.patch('/api/bookings/$id/pay');
  }

  Future<void> handoverBooking(String id) async {
    await _dio.patch('/api/bookings/$id/handover');
  }

  Future<void> returnBooking(String id) async {
    await _dio.patch('/api/bookings/$id/return');
  }

  // --- Availability / Calendar Endpoints ---

  Future<List<AvailabilityBlockResponse>> getListingAvailability(String listingId) async {
    final response = await _dio.get('/api/listings/$listingId/availability');
    return (response.data as List<dynamic>)
        .map((e) => AvailabilityBlockResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> createManualBlock(String listingId, DateTime start, DateTime end) async {
    await _dio.post('/api/listings/$listingId/availability/block', data: {
      'startDate': start.toIso8601String(),
      'endDate': end.toIso8601String(),
    });
  }

  Future<void> deleteManualBlock(String listingId, String blockId) async {
    await _dio.delete('/api/listings/$listingId/availability/block/$blockId');
  }

  // --- Earnings & Payout Endpoints ---

  Future<EarningsResponse> getMyEarnings() async {
    final response = await _dio.get('/api/users/me/earnings');
    return EarningsResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> requestPayout({
    required double amount,
    required String bankName,
    required String accountNumber,
    required String accountName,
  }) async {
    await _dio.post('/api/users/me/payouts', data: {
      'amount': amount,
      'bankName': bankName,
      'accountNumber': accountNumber,
      'accountName': accountName,
    });
  }
}

// --- Booking Models ---

class BookingResponse {
  final String id;
  final String listingId;
  final String listingTitle;
  final String? listingImage;
  final String renterId;
  final String renterName;
  final String ownerId;
  final String ownerName;
  final DateTime startDate;
  final DateTime endDate;
  final double totalPrice;
  final double securityDeposit;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  BookingResponse({
    required this.id,
    required this.listingId,
    required this.listingTitle,
    this.listingImage,
    required this.renterId,
    required this.renterName,
    required this.ownerId,
    required this.ownerName,
    required this.startDate,
    required this.endDate,
    required this.totalPrice,
    required this.securityDeposit,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  factory BookingResponse.fromJson(Map<String, dynamic> json) {
    return BookingResponse(
      id: json['id'] as String,
      listingId: json['listingId'] as String,
      listingTitle: json['listingTitle'] as String,
      listingImage: json['listingImage'] as String?,
      renterId: json['renterId'] as String,
      renterName: json['renterName'] as String,
      ownerId: json['ownerId'] as String,
      ownerName: json['ownerName'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      totalPrice: (json['totalPrice'] as num).toDouble(),
      securityDeposit: (json['securityDeposit'] as num).toDouble(),
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
    );
  }
}

class AvailabilityBlockResponse {
  final String id;
  final String listingId;
  final DateTime startDate;
  final DateTime endDate;
  final String type;
  final String? bookingId;

  AvailabilityBlockResponse({
    required this.id,
    required this.listingId,
    required this.startDate,
    required this.endDate,
    required this.type,
    this.bookingId,
  });

  factory AvailabilityBlockResponse.fromJson(Map<String, dynamic> json) {
    return AvailabilityBlockResponse(
      id: json['id'] as String,
      listingId: json['listingId'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      type: json['type'] as String,
      bookingId: json['bookingId'] as String?,
    );
  }
}

class PayoutResponse {
  final String id;
  final String ownerId;
  final String ownerName;
  final double amount;
  final String bankName;
  final String accountNumber;
  final String accountName;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  PayoutResponse({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.amount,
    required this.bankName,
    required this.accountNumber,
    required this.accountName,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  factory PayoutResponse.fromJson(Map<String, dynamic> json) {
    return PayoutResponse(
      id: json['id'] as String,
      ownerId: json['ownerId'] as String,
      ownerName: json['ownerName'] as String,
      amount: (json['amount'] as num).toDouble(),
      bankName: json['bankName'] as String,
      accountNumber: json['accountNumber'] as String,
      accountName: json['accountName'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
    );
  }
}

class EarningsResponse {
  final double availableBalance;
  final double totalEarned;
  final double escrowedBalance;
  final List<PayoutResponse> payouts;

  EarningsResponse({
    required this.availableBalance,
    required this.totalEarned,
    required this.escrowedBalance,
    required this.payouts,
  });

  factory EarningsResponse.fromJson(Map<String, dynamic> json) {
    return EarningsResponse(
      availableBalance: (json['availableBalance'] as num).toDouble(),
      totalEarned: (json['totalEarned'] as num).toDouble(),
      escrowedBalance: (json['escrowedBalance'] as num).toDouble(),
      payouts: (json['payouts'] as List<dynamic>? ?? [])
          .map((e) => PayoutResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
