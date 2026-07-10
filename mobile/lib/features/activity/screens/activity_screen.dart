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

    showDialog<void>(
      context: context,
      builder: (context) {
        final dialogTheme = Theme.of(context);
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              title: const Text('File a Dispute'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Explain the damage or issue clearly. Our administrators will review the dispute details.',
                    style: dialogTheme.textTheme.bodyMedium?.copyWith(
                      color: dialogTheme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: reasonController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Describe the issue...',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
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
                                  content: Text('Dispute filed successfully.'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                              _loadAll();
                            }
                          } catch (_) {
                          } finally {
                            setDialogState(() => submittingDispute = false);
                          }
                        },
                  child: submittingDispute
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Submit'),
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
    final startStr = '${booking.startDate.day}/${booking.startDate.month}/${booking.startDate.year}';
    final endStr = '${booking.endDate.day}/${booking.endDate.month}/${booking.endDate.year}';
    final total = booking.totalPrice + booking.securityDeposit;
    final statusColor = _getStatusColor(booking.status, theme);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: (theme.colorScheme.outlineVariant ?? theme.dividerColor).withOpacity(0.4)),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.button),
                child: SizedBox(
                  width: 60,
                  height: 60,
                  child: ListingImage(url: booking.listingImage, width: 60, height: 60),
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
                      style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isOwnerView ? 'Renter: ${booking.renterName}' : 'Owner: ${booking.ownerName}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$startStr - $endStr',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(AppRadius.button),
                  border: Border.all(color: statusColor.withOpacity(0.2), width: 1.0),
                ),
                child: Text(
                  booking.status.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Cash Due', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 2),
                  Text(ListingsApi.formatPrice(total), style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          if (isOwnerView) ...[
            if (booking.status.toLowerCase() == 'pending') ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: () => _handleReject(booking.id), child: const Text('Reject'))),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: FilledButton(onPressed: () => _handleApprove(booking.id), child: const Text('Approve'))),
                ],
              ),
            ],
            if (booking.status.toLowerCase() == 'approved') ...[
              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                onPressed: () => _handleHandover(booking.id),
                icon: const Icon(LucideIcons.check),
                label: const Text('Confirm Handover'),
              ),
            ],
            if (booking.status.toLowerCase() == 'active') ...[
              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                onPressed: () => _handleReturn(booking.id),
                icon: const Icon(LucideIcons.cornerDownLeft),
                label: const Text('Confirm Return'),
              ),
            ],
            if (booking.status.toLowerCase() == 'completed') ...[
              const SizedBox(height: AppSpacing.md),
              (() {
                final reviews = _bookingReviews[booking.id] ?? [];
                final hasReviewed = reviews.any((r) => !r.isRenterReview);
                if (hasReviewed) {
                  return const Text('Review Submitted', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold));
                }
                return FilledButton.icon(
                  onPressed: () => _showLeaveReviewDialog(booking, true),
                  icon: const Icon(LucideIcons.star),
                  label: const Text('Leave Gear Review'),
                );
              }()),
            ],
          ] else ...[
            if (booking.status.toLowerCase() == 'completed') ...[
              const SizedBox(height: AppSpacing.md),
              (() {
                final reviews = _bookingReviews[booking.id] ?? [];
                final hasReviewed = reviews.any((r) => r.isRenterReview);
                if (hasReviewed) {
                  return const Text('Review Submitted', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold));
                }
                return FilledButton.icon(
                  onPressed: () => _showLeaveReviewDialog(booking, false),
                  icon: const Icon(LucideIcons.star),
                  label: const Text('Leave Renter Review'),
                );
              }()),
            ],
          ],
          if (booking.status.toLowerCase() == 'active') ...[
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: () => _showDisputeDialog(booking),
              icon: const Icon(LucideIcons.alertTriangle, size: 16),
              label: const Text('File Dispute / Report Issue'),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
                side: BorderSide(color: theme.colorScheme.error.withOpacity(0.5)),
                minimumSize: const Size(double.infinity, 36),
              ),
            ),
          ],
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appMode = ref.watch(appModeProvider);
    final isOwner = appMode == UserAppMode.owner;

    return Scaffold(
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
                    'Bookings',
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
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadAll,
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : isOwner
                        ? (_ownerBookings.isEmpty
                            ? EmptyState(
                                icon: LucideIcons.calendarClock,
                                title: 'No active requests',
                                subtitle: 'Once a renter requests to book your gear, it will show up here.',
                              )
                            : ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: _ownerBookings.length,
                                itemBuilder: (context, index) => _buildBookingCard(_ownerBookings[index], true),
                              ))
                        : (_renterBookings.isEmpty
                            ? EmptyState(
                                icon: LucideIcons.calendar,
                                title: 'No Rentals yet',
                                subtitle: 'Find awesome gear and submit booking requests.',
                                actionLabel: 'Explore gear',
                                onActionPressed: () => context.go('/app/explore'),
                              )
                            : ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: _renterBookings.length,
                                itemBuilder: (context, index) => _buildBookingCard(_renterBookings[index], false),
                              )),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
