import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/api/api_client.dart';
import 'package:mobile/core/api/bookings_api.dart';
import 'package:mobile/core/api/listings_api.dart';
import 'package:mobile/core/models/listing.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/shared/widgets/listing_image.dart';

class BookingRequestScreen extends ConsumerStatefulWidget {
  final String listingId;

  const BookingRequestScreen({super.key, required this.listingId});

  @override
  ConsumerState<BookingRequestScreen> createState() => _BookingRequestScreenState();
}

class _BookingRequestScreenState extends ConsumerState<BookingRequestScreen> {
  Listing? _listing;
  UserProfile? _user;
  DateTimeRange? _selectedRange;
  bool _loading = true;
  bool _submitting = false;
  bool _agreementChecked = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final listingsApi = ref.read(listingsApiProvider);
      final listing = await listingsApi.getListing(widget.listingId);
      final user = await listingsApi.getCurrentUser();
      setState(() {
        _listing = listing;
        _user = user;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load listing or user details.')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _selectDates() async {
    final now = DateTime.now();
    final firstDate = now;
    final lastDate = now.add(const Duration(days: 365));

    final picked = await showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDateRange: _selectedRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedRange = picked;
      });
    }
  }

  Future<void> _submitRequest() async {
    if (_selectedRange == null || _listing == null || _user == null) return;

    if (_user!.verificationLevel < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('KYC Verification Level 2 (NIC Approved) is required to request a booking.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await ref.read(bookingsApiProvider).createBooking(
            _listing!.id,
            _selectedRange!.start,
            _selectedRange!.end,
          );

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('Request Submitted'),
              ],
            ),
            content: const Text(
                'Your booking request has been sent to the owner for approval. You can track its status in the Activity tab.'),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  context.go('/app/activity'); // Navigate to Activity tab
                },
                child: const Text('Go to Activity'),
              ),
            ],
          ),
        );
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(extractError(e)), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showAgreementModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'RentLanka System Agreement',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Last Updated: June 2026',
                  style: TextStyle(color: AppTheme.muted, fontSize: 12),
                ),
                const Divider(),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: const [
                      Text(
                        'Welcome to RentLanka. By checking the agreement box and requesting a booking, you agree to comply with and be bound by the following terms of the peer-to-peer equipment rental marketplace:\n\n'
                        '1. Renter Responsibilities:\n'
                        'The renter agrees to use the rented equipment solely for its intended purpose and in a careful, safe manner. The renter is responsible for returning the equipment in the same condition as received (reasonable wear and tear excepted) by the end date specified in the booking.\n\n'
                        '2. Owner Responsibilities:\n'
                        'The owner guarantees that the equipment is in good working order and conforms to the description provided in the listing. The owner must handover the equipment at the agreed location and time.\n\n'
                        '3. Payments and Escrow:\n'
                        'All rental fees and security deposits are processed through RentLanka’s secure payment gateway. The rental fee and security deposit are held in escrow. The rental fee is released to the owner upon successful completion of the rental. The security deposit is returned to the renter within 24 hours of a clean return confirmation.\n\n'
                        '4. Damaged or Lost Equipment:\n'
                        'In the event of damage or loss, the owner must submit a dispute report within 24 response of return. RentLanka reserves the right to withhold the security deposit to cover repairs or replacement costs based on review of the dispute.\n\n'
                        '5. Disputes and Arbitration:\n'
                        'Any disputes arising from rental agreements will be mediated by RentLanka Admin. By signing, you agree to abide by the administrative resolution decided by the operations team.',
                        style: TextStyle(fontSize: 14, height: 1.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(45)),
                  child: const Text('Close & I Agree'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final listing = _listing;
    final user = _user;

    if (listing == null || user == null) {
      return const Scaffold(body: Center(child: Text('Error loading booking data.')));
    }

    final days = _selectedRange != null ? _selectedRange!.duration.inDays : 0;
    final rentalFee = days * listing.pricePerDay;
    final totalAmount = rentalFee + listing.securityDeposit;

    final imageUrl = listing.images.isNotEmpty ? listing.images.first : null;

    final isVerified = user.verificationLevel >= 2;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm & Book'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Listing Card Summary
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: ListingImage(url: imageUrl, width: 80, height: 80),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        listing.category.toUpperCase(),
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        listing.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${ListingsApi.formatPrice(listing.pricePerDay)} / day',
                        style: const TextStyle(color: AppTheme.muted, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),

            // Verification Check Block
            if (!isVerified) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                        SizedBox(width: 8),
                        Text(
                          'Verification Required',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'You must complete KYC Verification (Level 2 / NIC Approved) before booking items.',
                      style: TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => context.push('/app/profile/verification'),
                      icon: const Icon(Icons.verified_user_outlined, size: 16),
                      label: const Text('Complete Verification Now'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Dates Selection
            const Text(
              'Select Rental Dates',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _selectDates,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_month, color: AppTheme.primary),
                        const SizedBox(width: 12),
                        Text(
                          _selectedRange == null
                              ? 'Choose dates'
                              : '${_selectedRange!.start.day}/${_selectedRange!.start.month}/${_selectedRange!.start.year} - ${_selectedRange!.end.day}/${_selectedRange!.end.month}/${_selectedRange!.end.year}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: _selectedRange == null ? FontWeight.normal : FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.muted),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Price Details
            if (_selectedRange != null) ...[
              const Text(
                'Price Summary',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 0,
                color: Colors.grey.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${ListingsApi.formatPrice(listing.pricePerDay)} × $days days'),
                          Text(ListingsApi.formatPrice(rentalFee)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Refundable Security Deposit'),
                          Text(ListingsApi.formatPrice(listing.securityDeposit)),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total (inc. deposit)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(
                            ListingsApi.formatPrice(totalAmount),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppTheme.muted),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'The deposit will be returned immediately after a clean item return is completed.',
                      style: TextStyle(color: AppTheme.muted, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Terms & Conditions',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'I agree to the RentLanka System Agreement and Terms',
                  style: TextStyle(fontSize: 14),
                ),
                value: _agreementChecked,
                onChanged: (val) {
                  setState(() {
                    _agreementChecked = val ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: AppTheme.primary,
                subtitle: Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: _showAgreementModal,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Read System Agreement',
                      style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: FilledButton(
            onPressed: (_selectedRange == null || _submitting || !isVerified || !_agreementChecked) ? null : _submitRequest,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: AppTheme.primary,
            ),
            child: _submitting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                : const Text('Submit Booking Request'),
          ),
        ),
      ),
    );
  }
}
