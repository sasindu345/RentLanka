import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/api/api_client.dart';
import 'package:mobile/core/api/bookings_api.dart';
import 'package:mobile/features/profile/screens/notifications_screen.dart';
import 'package:mobile/shared/widgets/notification_bell_button.dart';

import 'package:mobile/core/api/listings_api.dart';
import 'package:mobile/shared/widgets/listing_image.dart';
import 'package:mobile/core/providers/app_mode_provider.dart';
import 'package:mobile/core/api/reviews_api.dart';
import 'package:mobile/features/chat/screens/inbox_screen.dart';
import 'package:mobile/core/api/disputes_api.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme/app_spacing.dart';
import 'package:mobile/core/theme/app_radius.dart';
import 'package:mobile/shared/widgets/empty_state.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/core/models/listing.dart';
import 'package:mobile/core/services/agreement_service.dart';

class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key});

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<BookingResponse> _renterBookings = [];
  List<BookingResponse> _ownerBookings = [];
  List<Listing> _myListings = [];
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

      List<Listing> myListings = [];
      try {
        myListings = await ref.read(listingsApiProvider).getMyListings();
      } catch (_) {}

      final allCompletedBookings = [
        ...renter,
        ...owner,
      ].where((b) => b.status.toLowerCase() == 'completed');

      _bookingReviews.clear();
      await Future.wait(
        allCompletedBookings.map((b) async {
          try {
            final list = await reviewsApi.getBookingReviews(b.id);
            _bookingReviews[b.id] = list;
          } catch (_) {}
        }),
      );

      setState(() {
        _renterBookings = renter;
        _ownerBookings = owner;
        _myListings = myListings;
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking approved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
      _loadAll();
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(extractError(e)),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _handleReject(String id) async {
    try {
      await ref.read(bookingsApiProvider).rejectBooking(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking request rejected.')),
        );
      }
      _loadAll();
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(extractError(e)),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _handleHandover(String id) async {
    try {
      await ref.read(bookingsApiProvider).handoverBooking(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Handover confirmed! Rental is now active.'),
            backgroundColor: Colors.green,
          ),
        );
      }
      _loadAll();
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(extractError(e)),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _handleReturn(String id) async {
    try {
      await ref.read(bookingsApiProvider).returnBooking(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Return confirmed. Deposit released & booking completed!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
      _loadAll();
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(extractError(e)),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showPaymentSheet(BookingResponse booking) {
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
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      LucideIcons.shieldCheck,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Secure Escrow Payment',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Pay for booking request #${booking.id.substring(0, 8)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                const Divider(),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Rental Cost'),
                    Text(
                      ListingsApi.formatPrice(booking.totalPrice),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Refundable Security Deposit'),
                    Text(
                      ListingsApi.formatPrice(booking.securityDeposit),
                      style: const TextStyle(fontWeight: FontWeight.w600),
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
                      'Total to Authorize',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      ListingsApi.formatPrice(
                        booking.totalPrice + booking.securityDeposit,
                      ),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(AppRadius.input),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.info,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          'Your card is authorized now. The rental fee is captured at handover, and the security deposit is released after the host confirms the return.',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.primary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    try {
                      await ref
                          .read(bookingsApiProvider)
                          .payBooking(booking.id);
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
                          SnackBar(
                            content: Text(extractError(e)),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Mock Pay & Authorize'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status, ThemeData theme) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return theme.colorScheme.primary;
      case 'paid':
        return Colors.teal;
      case 'active':
        return Colors.green;
      case 'completed':
        return theme.colorScheme.onSurfaceVariant;
      case 'rejected':
      case 'disputed':
        return theme.colorScheme.error;
      default:
        return theme.colorScheme.onSurface;
    }
  }

  void _showLeaveReviewDialog(BookingResponse booking, bool isOwnerView) {
    int selectedRating = 5;
    final commentController = TextEditingController();
    bool submittingReview = false;

    showDialog(
      context: context,
      builder: (context) {
        final dialogTheme = Theme.of(context);
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Leave a Review'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Rating:'),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starValue = index + 1;
                      return IconButton(
                        icon: Icon(
                          LucideIcons.star,
                          color: starValue <= selectedRating
                              ? Colors.amber
                              : dialogTheme.colorScheme.outline,
                          size: 28,
                        ),
                        onPressed: () {
                          setDialogState(() {
                            selectedRating = starValue;
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Share your feedback...',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: submittingReview
                      ? null
                      : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: submittingReview
                      ? null
                      : () async {
                          setDialogState(() => submittingReview = true);
                          try {
                            await ref
                                .read(reviewsApiProvider)
                                .createReview(
                                  booking.id,
                                  selectedRating,
                                  commentController.text,
                                );
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Thank you! Review submitted successfully.',
                                  ),
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
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(100, 40),
                  ),
                  child: submittingReview
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
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
        final dialogTheme = Theme.of(context);
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'File a Dispute',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Provide details on why you are filing a dispute. An administrator will review your claim and make a final resolution.',
                    style: dialogTheme.textTheme.bodyMedium?.copyWith(
                      color: dialogTheme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: reasonController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Describe the issue in detail...',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: dialogTheme.colorScheme.error,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(120, 40),
                  ),
                  onPressed: submittingDispute
                      ? null
                      : () async {
                          final text = reasonController.text.trim();
                          if (text.isEmpty) return;

                          setDialogState(() => submittingDispute = true);
                          try {
                            await ref
                                .read(disputesApiProvider)
                                .fileDispute(booking.id, text);
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Dispute filed successfully. Booking is now frozen.',
                                  ),
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
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
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
    final theme = Theme.of(context);
    final startStr =
        '${booking.startDate.day}/${booking.startDate.month}/${booking.startDate.year}';
    final endStr =
        '${booking.endDate.day}/${booking.endDate.month}/${booking.endDate.year}';
    final total = booking.totalPrice + booking.securityDeposit;
    final statusColor = _getStatusColor(booking.status, theme);

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.4),
          width: 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row (Image, Title, Status)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                  child: SizedBox(
                    width: 60,
                    height: 60,
                    child: ListingImage(
                      url: booking.listingImage,
                      width: 60,
                      height: 60,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.listingTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isOwnerView
                            ? 'Renter: ${booking.renterName}'
                            : 'Owner: ${booking.ownerName}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$startStr - $endStr',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                  child: Text(
                    booking.status.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Divider(),
            ),

            // Middle Row (Price Summary)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total (inc. deposit)',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ListingsApi.formatPrice(total),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Sec. Deposit',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ListingsApi.formatPrice(booking.securityDeposit),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Action Buttons
            if (booking.status.toLowerCase() != 'pending' && booking.status.toLowerCase() != 'rejected') ...[
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: () => AgreementService.generateAndShareAgreement(booking),
                icon: const Icon(LucideIcons.fileText, size: 16),
                label: const Text('Download Rental Agreement'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 38),
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
              ),
            ],

            if (isOwnerView) ...[
              if (booking.status.toLowerCase() == 'pending') ...[
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _handleReject(booking.id),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,
                          side: BorderSide(color: theme.colorScheme.error),
                        ),
                        child: const Text('Reject'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => _handleApprove(booking.id),
                        child: const Text('Approve'),
                      ),
                    ),
                  ],
                ),
              ],
              if (booking.status.toLowerCase() == 'approved') ...[
                const SizedBox(height: AppSpacing.md),
                FilledButton.icon(
                  onPressed: () => _handleHandover(booking.id),
                  icon: const Icon(LucideIcons.check, size: 18),
                  label: const Text('Confirm Handover & Payment Received'),
                  style: FilledButton.styleFrom(backgroundColor: Colors.teal),
                ),
              ],
              if (booking.status.toLowerCase() == 'active') ...[
                const SizedBox(height: AppSpacing.md),
                FilledButton.icon(
                  onPressed: () => _handleReturn(booking.id),
                  icon: const Icon(LucideIcons.cornerDownLeft, size: 18),
                  label: const Text('Confirm Safe Return'),
                ),
              ],
              if (booking.status.toLowerCase() == 'completed') ...[
                const SizedBox(height: AppSpacing.md),
                (() {
                  final reviews = _bookingReviews[booking.id] ?? [];
                  final hasReviewed = reviews.any((r) => !r.isRenterReview);
                  if (hasReviewed) {
                    final rating = reviews
                        .firstWhere((r) => !r.isRenterReview)
                        .rating;
                    return Row(
                      children: [
                        const Icon(
                          LucideIcons.checkCircle,
                          color: Colors.green,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Review Submitted: $rating ⭐',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    );
                  }
                  return FilledButton.icon(
                    onPressed: () => _showLeaveReviewDialog(booking, true),
                    icon: const Icon(LucideIcons.star, size: 18),
                    label: const Text('Leave Renter Review'),
                  );
                }()),
              ],
            ] else ...[
              if (booking.status.toLowerCase() == 'approved') ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(LucideIcons.info, color: theme.colorScheme.primary, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Awaiting Handover & Cash Payment',
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Meet the owner to pay in cash and collect the item. The owner will confirm handover in the app.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (booking.status.toLowerCase() == 'completed') ...[
                const SizedBox(height: AppSpacing.md),
                (() {
                  final reviews = _bookingReviews[booking.id] ?? [];
                  final hasReviewed = reviews.any((r) => r.isRenterReview);
                  if (hasReviewed) {
                    final rating = reviews
                        .firstWhere((r) => r.isRenterReview)
                        .rating;
                    return Row(
                      children: [
                        const Icon(
                          LucideIcons.checkCircle,
                          color: Colors.green,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Review Submitted: $rating ⭐',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    );
                  }
                  return FilledButton.icon(
                    onPressed: () => _showLeaveReviewDialog(booking, false),
                    icon: const Icon(LucideIcons.star, size: 18),
                    label: const Text('Leave Equipment Review'),
                  );
                }()),
              ],
            ],
            if (booking.status.toLowerCase() == 'disputed') ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(AppRadius.input),
                  border: Border.all(
                    color: theme.colorScheme.error.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.alertTriangle,
                      color: theme.colorScheme.error,
                      size: 18,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        'Booking under dispute review by RentLanka Admin.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (booking.status.toLowerCase() == 'paid' ||
                booking.status.toLowerCase() == 'active' ||
                booking.status.toLowerCase() == 'completed') ...[
              const SizedBox(height: AppSpacing.xs),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _showDisputeDialog(booking),
                  icon: Icon(
                    LucideIcons.alertTriangle,
                    size: 14,
                    color: theme.colorScheme.error,
                  ),
                  label: Text(
                    'File a Dispute',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
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

  Widget _buildGearStatusCard(Listing listing, ThemeData theme) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (listing.isPaused) {
      statusColor = Colors.orange;
      statusText = 'Paused';
      statusIcon = LucideIcons.pauseCircle;
    } else {
      switch (listing.status) {
        case 'PendingApproval':
          statusColor = Colors.blue;
          statusText = 'Pending Approval';
          statusIcon = LucideIcons.clock;
          break;
        case 'Rejected':
          statusColor = Colors.red;
          statusText = 'Rejected';
          statusIcon = LucideIcons.alertTriangle;
          break;
        case 'Approved':
        default:
          statusColor = Colors.green;
          statusText = 'Approved & Live';
          statusIcon = LucideIcons.checkCircle2;
          break;
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.4),
          width: 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.button),
              child: SizedBox(
                width: 50,
                height: 50,
                child: ListingImage(url: listing.images.isNotEmpty ? listing.images.first : '', width: 50, height: 50),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${listing.category} · ${ListingsApi.formatPrice(listing.pricePerDay)}/day',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(AppRadius.button),
                border: Border.all(color: statusColor.withOpacity(0.2), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusIcon, color: statusColor, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    statusText.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appMode = ref.watch(appModeProvider);
    final activeSegment = appMode == UserAppMode.owner ? 1 : 0;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: theme.colorScheme.background,
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.xs),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Activity',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        color: theme.colorScheme.onBackground,
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                    const NotificationBellButton(),
                  ],
                ),
              ),

              // 2. Premium Sliding Segmented Control Tabs Selector
              AnimatedBuilder(
                animation: _tabController.animation!,
                builder: (context, child) {
                  final value = _tabController.animation!.value;
                  return Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    padding: const EdgeInsets.all(4),
                    height: 44,
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.dark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        final pillWidth = width / 2;
                        return Stack(
                          children: [
                            // Sliding background pill card
                            Positioned(
                              left: value * pillWidth,
                              width: pillWidth,
                              height: constraints.maxHeight,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: theme.brightness == Brightness.dark
                                      ? const Color(0xFF0F172A)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Interactive Tab Texts
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () {
                                      _tabController.animateTo(0);
                                    },
                                    child: Center(
                                      child: Text(
                                        'Bookings',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: value < 0.5 ? FontWeight.w700 : FontWeight.w500,
                                          color: value < 0.5
                                              ? (theme.brightness == Brightness.dark
                                                  ? Colors.white
                                                  : theme.colorScheme.primary)
                                              : (theme.brightness == Brightness.dark
                                                  ? const Color(0xFF94A3B8)
                                                  : const Color(0xFF64748B)),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () {
                                      _tabController.animateTo(1);
                                    },
                                    child: Center(
                                      child: Text(
                                        'Messages',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: value >= 0.5 ? FontWeight.w700 : FontWeight.w500,
                                          color: value >= 0.5
                                              ? (theme.brightness == Brightness.dark
                                                  ? Colors.white
                                                  : theme.colorScheme.primary)
                                              : (theme.brightness == Brightness.dark
                                                  ? const Color(0xFF94A3B8)
                                                  : const Color(0xFF64748B)),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.xs),

              // 3. TabBarView Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Bookings tab content
                    Column(
                      children: [
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: _loadAll,
                            child: _loading
                                ? const Center(child: CircularProgressIndicator())
                                : activeSegment == 0
                                    ? (_renterBookings.isEmpty
                                        ? EmptyState(
                                            icon: LucideIcons.calendar,
                                            title: 'No Rentals yet',
                                            subtitle: 'Find awesome gear and submit booking requests.',
                                            actionLabel: 'Explore gear',
                                            onActionPressed: () => context.go('/app/explore'),
                                          )
                                        : ListView.builder(
                                            itemCount: _renterBookings.length,
                                            itemBuilder: (context, index) {
                                              return _buildBookingCard(
                                                _renterBookings[index],
                                                false,
                                              );
                                            },
                                          ))
                                    : ListView(
                                        physics: const AlwaysScrollableScrollPhysics(),
                                        children: [
                                          // --- SECTION 1: BOOKING REQUESTS ---
                                          Padding(
                                            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xs),
                                            child: Row(
                                              children: [
                                                Icon(LucideIcons.calendar, size: 18, color: theme.colorScheme.primary),
                                                const SizedBox(width: AppSpacing.xs),
                                                Text(
                                                  'Booking Requests',
                                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                                ),
                                                const SizedBox(width: AppSpacing.xs),
                                                if (_ownerBookings.isNotEmpty)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: theme.colorScheme.primary.withOpacity(0.08),
                                                      borderRadius: BorderRadius.circular(AppRadius.button),
                                                    ),
                                                    child: Text(
                                                      '${_ownerBookings.length}',
                                                      style: theme.textTheme.labelSmall?.copyWith(
                                                        color: theme.colorScheme.primary,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          if (_ownerBookings.isEmpty)
                                            Container(
                                              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                                              decoration: BoxDecoration(
                                                color: theme.colorScheme.surface,
                                                borderRadius: BorderRadius.circular(AppRadius.card),
                                                border: Border.all(
                                                  color: theme.colorScheme.outlineVariant.withOpacity(0.4),
                                                  width: 1.0,
                                                ),
                                              ),
                                              child: Padding(
                                                padding: const EdgeInsets.all(AppSpacing.lg),
                                                child: Column(
                                                  children: [
                                                    Icon(LucideIcons.calendarClock, size: 36, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5)),
                                                    const SizedBox(height: AppSpacing.xs),
                                                    Text(
                                                      'No active requests',
                                                      style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      'Once a renter requests to book your gear, it will show up here.',
                                                      textAlign: TextAlign.center,
                                                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            )
                                          else
                                            ..._ownerBookings.map((b) => _buildBookingCard(b, true)),

                                          const SizedBox(height: AppSpacing.lg),

                                          // --- SECTION 2: YOUR LISTED EQUIPMENT ---
                                          Padding(
                                            padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.xs),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(LucideIcons.store, size: 18, color: theme.colorScheme.primary),
                                                    const SizedBox(width: AppSpacing.xs),
                                                    Text(
                                                      'Your Gear & Approval Status',
                                                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                                    ),
                                                  ],
                                                ),
                                                Text(
                                                  '${_myListings.length} items',
                                                  style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (_myListings.isEmpty)
                                            Container(
                                              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                                              decoration: BoxDecoration(
                                                color: theme.colorScheme.surface,
                                                borderRadius: BorderRadius.circular(AppRadius.card),
                                                border: Border.all(
                                                  color: theme.colorScheme.outlineVariant.withOpacity(0.4),
                                                  width: 1.0,
                                                ),
                                              ),
                                              child: Padding(
                                                padding: const EdgeInsets.all(AppSpacing.lg),
                                                child: Column(
                                                  children: [
                                                    Icon(LucideIcons.packagePlus, size: 36, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5)),
                                                    const SizedBox(height: AppSpacing.xs),
                                                    Text(
                                                      'No listings published',
                                                      style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      'List your equipment to start earning on RentLanka.',
                                                      textAlign: TextAlign.center,
                                                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                                    ),
                                                    const SizedBox(height: AppSpacing.md),
                                                    FilledButton.icon(
                                                      onPressed: () => context.go('/app/list'),
                                                      icon: const Icon(LucideIcons.plus, size: 16),
                                                      label: const Text('Publish Gear'),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            )
                                          else
                                            ..._myListings.map((l) => _buildGearStatusCard(l, theme)),
                                        ],
                                      ),
                          ),
                        ),
                      ],
                    ),

                    // Messages tab content
                    const InboxScreen(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
