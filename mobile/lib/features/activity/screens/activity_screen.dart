import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/api/api_client.dart';
import 'package:mobile/core/api/bookings_api.dart';
import 'package:mobile/core/api/listings_api.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/shared/widgets/listing_image.dart';

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
      final renter = await api.getRenterBookings();
      final owner = await api.getOwnerBookings();
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
      default:
        return Colors.black;
    }
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
        side: Border.all(color: Colors.grey.shade100),
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
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                // Segment Selection
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 0, label: Text('Rentals'), icon: Icon(Icons.shopping_bag_outlined)),
                      ButtonSegment(value: 1, label: Text('Hostings'), icon: Icon(Icons.business_center_outlined)),
                    ],
                    selected: {_bookingSegmentIndex},
                    onSelectionChanged: (set) {
                      setState(() {
                        _bookingSegmentIndex = set.first;
                      });
                    },
                  ),
                ),

                // Bookings list
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadAll,
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : _bookingSegmentIndex == 0
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
            const _EmptyState(
              icon: Icons.chat_bubble_outline,
              title: 'No messages yet',
              subtitle: 'In-app chat arrives in Phase 5.',
            ),
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
