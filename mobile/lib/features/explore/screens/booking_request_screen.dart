import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/api/api_client.dart';
import 'package:mobile/core/api/bookings_api.dart';
import 'package:mobile/core/api/listings_api.dart';
import 'package:mobile/core/models/listing.dart';
import 'package:mobile/shared/widgets/listing_image.dart';
import 'package:mobile/core/theme/app_spacing.dart';
import 'package:mobile/core/theme/app_radius.dart';
import 'package:lucide_icons/lucide_icons.dart';

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
      debugPrint('Error loading booking request details: $e');
      if (mounted) {
        String errMsg = 'Failed to load details.';
        if (e is DioException) {
          errMsg = extractError(e);
        } else {
          errMsg = e.toString();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $errMsg')),
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
        final theme = Theme.of(context);
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: theme.colorScheme.primary,
              onPrimary: theme.colorScheme.onPrimary,
              surface: theme.colorScheme.surface,
              onSurface: theme.colorScheme.onSurface,
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

    // KYC check removed for renters as per user request (only owner needs KYC verification).

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
          builder: (context) {
            final dialogTheme = Theme.of(context);
            return AlertDialog(
              title: Row(
                children: [
                  Icon(LucideIcons.checkCircle, color: dialogTheme.colorScheme.primary),
                  const SizedBox(width: AppSpacing.xs),
                  const Text('Request Sent'),
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
            );
          },
        );
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(extractError(e)),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppRadius.sheet),
          topRight: Radius.circular(AppRadius.sheet),
        ),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  // Drag handle indicator
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outline,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        Text(
                          'RentLanka System Agreement',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          '1. Rental Period & Extensions\n'
                          'The renter agrees to return the equipment on or before the specified return date. Any extension requests must be submitted through the app and approved by the owner.\n\n'
                          '2. Security Deposit Escrow\n'
                          'The security deposit will be held securely in escrow by RentLanka. Upon successful return of the equipment without damages, the deposit is refunded immediately. In the event of a dispute, the platform holds the deposit until resolution.\n\n'
                          '3. Equipment Condition & Usage\n'
                          'The renter is responsible for inspecting the item during handover. The renter agrees to use the equipment carefully and is liable for damages or losses incurred during the rental period.\n\n'
                          '4. Handover & Returns\n'
                          'Both parties must visually document the item status during handover and return. Failure to complete return validation steps may delay deposit refund releases.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close & I Agree'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(title: const Text('Confirm & Book')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final listing = _listing;
    final user = _user;

    if (listing == null || user == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(title: const Text('Confirm & Book')),
        body: const Center(child: Text('Error loading booking data.')),
      );
    }

    final days = _selectedRange != null ? _selectedRange!.duration.inDays : 0;
    final rentalFee = days * listing.pricePerDay;
    final totalAmount = rentalFee + listing.securityDeposit;
    final imageUrl = listing.images.isNotEmpty ? listing.images.first : null;
    final isVerified = true; // Bypassed: renters do not require KYC.

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Confirm & Book'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Listing card summary
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.input),
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: ListingImage(url: imageUrl, width: 80, height: 80),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        listing.category.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        listing.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${ListingsApi.formatPrice(listing.pricePerDay)} / day',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Divider(),
            ),

            // Verification Check Block
            if (!isVerified) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: theme.colorScheme.error.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(LucideIcons.alertTriangle, color: theme.colorScheme.error),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'Verification Required',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'You must complete KYC Verification (Level 2 / NIC Approved) before booking items.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    OutlinedButton.icon(
                      onPressed: () => context.push('/app/profile/verification'),
                      icon: const Icon(LucideIcons.shieldCheck, size: 16),
                      label: const Text('Complete Verification'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                        side: BorderSide(color: theme.colorScheme.error),
                        minimumSize: const Size.fromHeight(40),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],

            // Dates Selection
            Text(
              'Select Rental Dates',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            InkWell(
              onTap: _selectDates,
              borderRadius: BorderRadius.circular(AppRadius.input),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.outline),
                  borderRadius: BorderRadius.circular(AppRadius.input),
                  color: theme.colorScheme.surfaceVariant,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(LucideIcons.calendar, color: theme.colorScheme.primary),
                        const SizedBox(width: AppSpacing.md),
                        Text(
                          _selectedRange == null
                              ? 'Choose rental dates'
                              : '${_selectedRange!.start.day}/${_selectedRange!.start.month}/${_selectedRange!.start.year} - ${_selectedRange!.end.day}/${_selectedRange!.end.month}/${_selectedRange!.end.year}',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: _selectedRange == null ? FontWeight.normal : FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Icon(LucideIcons.chevronRight, size: 16, color: theme.colorScheme.onSurfaceVariant),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: AppSpacing.xl),

            // Price Details
            if (_selectedRange != null) ...[
              Text(
                'Price Summary',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${ListingsApi.formatPrice(listing.pricePerDay)} × $days days',
                            style: theme.textTheme.bodyMedium,
                          ),
                          Text(
                            ListingsApi.formatPrice(rentalFee),
                            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Refundable Security Deposit'),
                          Text(
                            ListingsApi.formatPrice(listing.securityDeposit),
                            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
                        child: Divider(),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total (inc. deposit)',
                            style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            ListingsApi.formatPrice(totalAmount),
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(LucideIcons.info, size: 14, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'The deposit will be returned immediately after a clean item return is completed.',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: AppSpacing.xl),
              
              Text(
                'Terms & Conditions',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'I agree to the RentLanka System Agreement and Terms',
                  style: theme.textTheme.bodyMedium,
                ),
                value: _agreementChecked,
                onChanged: (val) {
                  setState(() {
                    _agreementChecked = val ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: theme.colorScheme.primary,
                subtitle: Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: _showAgreementModal,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Read System Agreement',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            top: BorderSide(color: theme.dividerColor, width: 1.0),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: FilledButton(
              onPressed: (_selectedRange == null || _submitting || !isVerified || !_agreementChecked) ? null : _submitRequest,
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Submit Booking Request'),
            ),
          ),
        ),
      ),
    );
  }
}
