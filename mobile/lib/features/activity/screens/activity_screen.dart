import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/api/api_client.dart';
import 'package:mobile/core/api/bookings_api.dart';
import 'package:mobile/core/api/listings_api.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/shared/widgets/listing_image.dart';
import 'package:mobile/core/providers/app_mode_provider.dart';
import 'package:mobile/core/api/reviews_api.dart';
import 'package:mobile/features/chat/screens/inbox_screen.dart';
import 'package:mobile/core/api/disputes_api.dart';

class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key});

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _bookingSegmentIndex = 0; // 0 = Rentals, 1 = Hostings
  List<BookingResponse> _renterBookings = [];
  List<BookingResponse> _ownerBookings = [];
  bool _loading = true;
  final Map<String, List<ReviewResponse>> _bookingReviews = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      final api = ref.read(bookingsApiProvider);
      final reviewsApi = ref.read(reviewsApiProvider);
      final renter = await api.getRenterBookings();
      final owner = await api.getOwnerBookings();

      final allCompletedBookings = [...renter, ...owner]
          .where((b) => b.status.toLowerCase() == 'completed');

      _bookingReviews.clear();
      await Future.wait(allCompletedBookings.map((b) async {
        try {
          final list = await reviewsApi.getBookingReviews(b.id);
          _bookingReviews[b.id] = list;
        } catch (_) {}
      }));

      setState(() {
        _renterBookings = renter;
        _ownerBookings = owner;
      });
    } catch (_) {
      // Ignore load errors silently or show snackbar
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleApprove(String id) async {
    try {
      await ref.read(bookingsApiProvider).approveBooking(id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking approved successfully!'), backgroundColor: Colors.green),
      );
      _loadAll();
    } on DioException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(extractError(e)), backgroundColor: Colors.redAccent),
      );
    }
  }

  Future<void> _handleReject(String id) async {
    try {
      await ref.read(bookingsApiProvider).rejectBooking(id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking request rejected.')),
      );
      _loadAll();
    } on DioException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(extractError(e)), backgroundColor: Colors.redAccent),
      );
    }
  }

  Future<void> _handleHandover(String id) async {
    try {
      await ref.read(bookingsApiProvider).handoverBooking(id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Handover confirmed! Rental is now active.'), backgroundColor: Colors.green),
      );
      _loadAll();
    } on DioException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(extractError(e)), backgroundColor: Colors.redAccent),
      );
    }
  }

  Future<void> _handleReturn(String id) async {
    try {
      await ref.read(bookingsApiProvider).returnBooking(id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Return confirmed. Deposit released & booking completed!'), backgroundColor: Colors.green),
      );
      _loadAll();
    } on DioException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(extractError(e)), backgroundColor: Colors.redAccent),
      );
    }
  }

  void _showPaymentSheet(BookingResponse booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.shield_outlined, color: AppTheme.primary, size: 28),
                    SizedBox(width: 8),
                    Text(
                      'Secure Escrow Payment',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Pay for booking request #${booking.id.substring(0, 8)}',
                  style: const TextStyle(color: AppTheme.muted),
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Rental Cost'),
                    Text(ListingsApi.formatPrice(booking.totalPrice)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Refundable Security Deposit'),
                    Text(ListingsApi.formatPrice(booking.securityDeposit)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total to Authorize',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      ListingsApi.formatPrice(booking.totalPrice + booking.securityDeposit),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Your card is authorized now. The rental fee is captured at handover, and the security deposit is released after the host confirms the return.',
                          style: TextStyle(fontSize: 12, color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    try {
                      await ref.read(bookingsApiProvider).payBooking(booking.id);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Payment authorized successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        _loadAll();
                      }
                    } on DioException catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(extractError(e)), backgroundColor: Colors.redAccent),
                        );
                      }
                    }
                  },
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    backgroundColor: AppTheme.primary,
                  ),
                  child: const Text('Mock Pay & Authorize'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.blue;
      case 'paid':
        return Colors.teal;
      case 'active':
        return Colors.green;
      case 'completed':
        return Colors.grey;
      case 'rejected':
        return Colors.red;
      case 'disputed':
        return Colors.deepOrange;
      default:
        return Colors.black;
    }
  }

  void _showLeaveReviewDialog(BookingResponse booking, bool isOwnerView) {
    int selectedRating = 5;
    final commentController = TextEditingController();
    bool submittingReview = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Leave a Review'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Rating:'),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starValue = index + 1;
                      return IconButton(
                        icon: Icon(
                          starValue <= selectedRating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 32,
                        ),
                        onPressed: () {
                          setDialogState(() {
                            selectedRating = starValue;
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Share your feedback...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: submittingReview ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: submittingReview
                      ? null
                      : () async {
                          setDialogState(() => submittingReview = true);
                          try {
                            await ref.read(reviewsApiProvider).createReview(
                                  booking.id,
                                  selectedRating,
                                  commentController.text,
                                );
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Thank you! Review submitted successfully.'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                            _loadAll();
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Failed to submit review.'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          } finally {
                            setDialogState(() => submittingReview = false);
                          }
                        },
                  child: submittingReview
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDisputeDialog(BookingResponse booking) {
    final reasonController = TextEditingController();
    bool submittingDispute = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('File a Dispute', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Provide details on why you are filing a dispute. An administrator will review your claim and make a final resolution.',
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: reasonController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Describe the issue in detail...',
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.redAccent),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
                  onPressed: submittingDispute
                      ? null
                      : () async {
                          final text = reasonController.text.trim();
                          if (text.isEmpty) return;

                          setDialogState(() => submittingDispute = true);
                          try {
                            await ref.read(disputesApiProvider).fileDispute(booking.id, text);
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Dispute filed successfully. Booking is now frozen.'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                              _loadAll();
                            }
                          } catch (_) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Failed to file dispute.'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          } finally {
                            setDialogState(() => submittingDispute = false);
                          }
                        },
                  child: submittingDispute
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Submit Dispute'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildBookingCard(BookingResponse booking, bool isOwnerView) {
    final startStr = '${booking.startDate.day}/${booking.startDate.month}/${booking.startDate.year}';
    final endStr = '${booking.endDate.day}/${booking.endDate.month}/${booking.endDate.year}';
    final total = booking.totalPrice + booking.securityDeposit;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row (Image, Title, Status)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 60,
                    height: 60,
                    child: ListingImage(url: booking.listingImage, width: 60, height: 60),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.listingTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isOwnerView ? 'Renter: ${booking.renterName}' : 'Owner: ${booking.ownerName}',
                        style: const TextStyle(color: AppTheme.muted, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$startStr - $endStr',
                        style: const TextStyle(color: AppTheme.muted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(booking.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    booking.status,
                    style: TextStyle(
                      color: _getStatusColor(booking.status),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Middle Row (Price Summary)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total (inc. deposit)', style: TextStyle(color: AppTheme.muted, fontSize: 11)),
                    Text(
                      ListingsApi.formatPrice(total),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primary),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Sec. Deposit', style: TextStyle(color: AppTheme.muted, fontSize: 11)),
                    Text(
                      ListingsApi.formatPrice(booking.securityDeposit),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),

            // Action Buttons
            if (isOwnerView) ...[
              if (booking.status.toLowerCase() == 'pending') ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _handleReject(booking.id),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(color: Colors.redAccent),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Reject'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => _handleApprove(booking.id),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Approve'),
                      ),
                    ),
                  ],
                ),
              ],
              if (booking.status.toLowerCase() == 'active') ...[
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => _handleReturn(booking.id),
                  icon: const Icon(Icons.keyboard_return),
                  label: const Text('Confirm Safe Return'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(40),
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
              if (booking.status.toLowerCase() == 'completed') ...[
                const SizedBox(height: 16),
                (() {
                  final reviews = _bookingReviews[booking.id] ?? [];
                  final hasReviewed = reviews.any((r) => !r.isRenterReview);
                  if (hasReviewed) {
                    final rating = reviews.firstWhere((r) => !r.isRenterReview).rating;
                    return Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 16),
                        const SizedBox(width: 6),
                        Text('Review Submitted: $rating ⭐', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    );
                  }
                  return FilledButton.icon(
                    onPressed: () => _showLeaveReviewDialog(booking, true),
                    icon: const Icon(Icons.rate_review_outlined),
                    label: const Text('Leave Renter Review'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(40),
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }()),
              ],
            ] else ...[
              if (booking.status.toLowerCase() == 'approved') ...[
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => _showPaymentSheet(booking),
                  icon: const Icon(Icons.payment),
                  label: const Text('Pay Now'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(40),
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
              if (booking.status.toLowerCase() == 'paid') ...[
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => _handleHandover(booking.id),
                  icon: const Icon(Icons.handshake_outlined),
                  label: const Text('Confirm Handover Received'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(40),
                    backgroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
              if (booking.status.toLowerCase() == 'completed') ...[
                const SizedBox(height: 16),
                (() {
                  final reviews = _bookingReviews[booking.id] ?? [];
                  final hasReviewed = reviews.any((r) => r.isRenterReview);
                  if (hasReviewed) {
                    final rating = reviews.firstWhere((r) => r.isRenterReview).rating;
                    return Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 16),
                        const SizedBox(width: 6),
                        Text('Review Submitted: $rating ⭐', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    );
                  }
                  return FilledButton.icon(
                    onPressed: () => _showLeaveReviewDialog(booking, false),
                    icon: const Icon(Icons.rate_review_outlined),
                    label: const Text('Leave Equipment Review'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(40),
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }()),
              ],
            ],
            if (booking.status.toLowerCase() == 'disputed') ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.deepOrange, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Booking under dispute review by RentLanka Admin.',
                        style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (booking.status.toLowerCase() == 'paid' || 
                       booking.status.toLowerCase() == 'active' || 
                       booking.status.toLowerCase() == 'completed') ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _showDisputeDialog(booking),
                  icon: const Icon(Icons.warning_amber_rounded, size: 16, color: Colors.redAccent),
                  label: const Text('File a Dispute', style: TextStyle(color: Colors.redAccent, fontSize: 13)),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appMode = ref.watch(appModeProvider);
    final activeSegment = appMode == UserAppMode.owner ? 1 : 0;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Activity'),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Bookings'),
              Tab(text: 'Messages'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            // Bookings tab content
            Column(
              children: [
                // Bookings list
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadAll,
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : activeSegment == 0
                            ? (_renterBookings.isEmpty
                                ? const _EmptyState(
                                    icon: Icons.calendar_today_outlined,
                                    title: 'No Rentals yet',
                                    subtitle: 'Find awesome gear and submit booking requests.',
                                  )
                                : ListView.builder(
                                    itemCount: _renterBookings.length,
                                    itemBuilder: (context, index) {
                                      return _buildBookingCard(_renterBookings[index], false);
                                    },
                                  ))
                            : (_ownerBookings.isEmpty
                                ? const _EmptyState(
                                    icon: Icons.storefront_outlined,
                                    title: 'No Hostings yet',
                                    subtitle: 'Create listings and wait for bookings requests to arrive.',
                                  )
                                : ListView.builder(
                                    itemCount: _ownerBookings.length,
                                    itemBuilder: (context, index) {
                                      return _buildBookingCard(_ownerBookings[index], true);
                                    },
                                  )),
                  ),
                ),
              ],
            ),

            // Messages tab content
            const InboxScreen(),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: AppTheme.muted),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.muted)),
          ],
        ),
      ),
    );
  }
}
