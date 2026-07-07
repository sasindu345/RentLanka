import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/api/api_client.dart';
import 'package:mobile/core/api/bookings_api.dart';
import 'package:mobile/core/api/listings_api.dart';
import 'package:mobile/core/models/listing.dart';
import 'package:mobile/shared/widgets/listing_image.dart';
import 'package:mobile/core/api/reviews_api.dart';
import 'package:mobile/core/api/chats_api.dart';
import 'package:mobile/core/theme/app_spacing.dart';
import 'package:mobile/core/theme/app_radius.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/core/providers/wishlist_provider.dart';

class ListingDetailScreen extends ConsumerStatefulWidget {
  final String id;

  const ListingDetailScreen({super.key, required this.id});

  @override
  ConsumerState<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends ConsumerState<ListingDetailScreen> {
  Listing? _listing;
  List<AvailabilityBlockResponse> _blocks = [];
  List<ReviewResponse> _reviews = [];
  double _averageRating = 0.0;
  bool _loading = true;
  bool _messaging = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final listing = await ref.read(listingsApiProvider).getListing(widget.id);
      final blocks = await ref.read(bookingsApiProvider).getListingAvailability(widget.id);
      final reviewsApi = ref.read(reviewsApiProvider);
      
      final reviews = await reviewsApi.getListingReviews(widget.id);
      final averageRating = await reviewsApi.getListingAverageRating(widget.id);

      setState(() {
        _listing = listing;
        _blocks = blocks;
        _reviews = reviews;
        _averageRating = averageRating;
      });
    } catch (_) {
      // Ignore if details load fails
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }



  Future<void> _startMessage() async {
    setState(() => _messaging = true);
    try {
      final chat = await ref.read(chatsApiProvider).getOrCreateConversation(widget.id);
      if (mounted) {
        context.push('/app/activity/messages/thread/${chat.id}');
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to initiate conversation.')),
        );
      }
    } finally {
      if (mounted) setState(() => _messaging = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSaved = ref.watch(wishlistProvider).maybeWhen(
          data: (items) => items.any((item) => item.id.toString() == widget.id),
          orElse: () => false,
        );

    if (_loading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final listing = _listing;
    if (listing == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(),
        body: const Center(child: Text('Listing not found')),
      );
    }

    final imageUrl = listing.images.isNotEmpty ? listing.images.first : null;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          listing.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 10,
              child: ListingImage(url: imageUrl, width: double.infinity),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category tag
                  Text(
                    listing.category.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  
                  // Title
                  Text(
                    listing.title,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  
                  // Rating & Location row
                  Row(
                    children: [
                      const Icon(LucideIcons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        _averageRating > 0 ? _averageRating.toStringAsFixed(1) : 'New',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '· ${_reviews.length} ${_reviews.length == 1 ? 'review' : 'reviews'}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Icon(
                        LucideIcons.mapPin,
                        color: theme.colorScheme.onSurfaceVariant,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        listing.district,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    child: Divider(),
                  ),
                  
                  // Price block
                  Text(
                    '${ListingsApi.formatPrice(listing.pricePerDay)} / day',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Security deposit: ${ListingsApi.formatPrice(listing.securityDeposit)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    child: Divider(),
                  ),
                  
                  // Description
                  Text(
                    'Description',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    listing.description,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      height: 1.5,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  
                  if (listing.rules.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                      child: Divider(),
                    ),
                    Text(
                      'Rental rules',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      listing.rules,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    child: Divider(),
                  ),
                  
                  // Owner
                  Text(
                    'Listed by',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(color: theme.colorScheme.outline),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: theme.colorScheme.primary,
                          child: Text(
                            listing.owner.firstName.isNotEmpty ? listing.owner.firstName[0].toUpperCase() : 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${listing.owner.firstName} ${listing.owner.lastName}',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (listing.owner.isTrustedUser) ...[
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(
                                      LucideIcons.checkCircle,
                                      color: theme.colorScheme.primary,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Trusted owner',
                                      style: theme.textTheme.labelLarge?.copyWith(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    child: Divider(),
                  ),
                  
                  // Listing Availability
                  Text(
                    'Listing Availability',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (_blocks.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(AppRadius.input),
                      ),
                      child: Row(
                        children: [
                          Icon(LucideIcons.check, color: theme.colorScheme.primary, size: 20),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            'Available all dates',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._blocks.map((b) {
                      final startStr = '${b.startDate.day}/${b.startDate.month}/${b.startDate.year}';
                      final endStr = '${b.endDate.day}/${b.endDate.month}/${b.endDate.year}';
                      final isManual = b.type == 'Manual';
                      final cardBg = isManual
                          ? theme.colorScheme.surfaceVariant
                          : theme.colorScheme.error.withOpacity(0.08);
                      final textColor = isManual
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.error;

                      return Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(AppRadius.input),
                          border: Border.all(
                            color: isManual ? theme.colorScheme.outline : theme.colorScheme.error.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(LucideIcons.calendar, color: textColor, size: 16),
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  '$startStr - $endStr',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              isManual ? 'Blocked by Owner' : 'Booked',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    child: Divider(),
                  ),
                  
                  // Reviews
                  Text(
                    'Customer Reviews',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (_reviews.isEmpty)
                    Text(
                      'No reviews for this equipment yet.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    )
                  else
                    ..._reviews.map((r) => Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(AppRadius.card),
                            border: Border.all(color: theme.colorScheme.outline),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    r.reviewerName,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Row(
                                    children: List.generate(5, (index) => Icon(
                                      LucideIcons.star,
                                      color: index < r.rating ? Colors.amber : theme.colorScheme.outline,
                                      size: 14,
                                    )),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              if (r.comment.isNotEmpty)
                                Text(
                                  r.comment,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    height: 1.4,
                                  ),
                                ),
                              const SizedBox(height: 6),
                              Text(
                                '${r.createdAt.day}/${r.createdAt.month}/${r.createdAt.year}',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        )),
                ],
              ),
            ),
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
            child: Row(
              children: [
                IconButton.outlined(
                  onPressed: _listing == null
                      ? null
                      : () => ref.read(wishlistProvider.notifier).toggleWishlist(_listing!),
                  icon: Icon(
                    isSaved ? Icons.favorite : LucideIcons.heart,
                    color: isSaved ? theme.colorScheme.primary : null,
                  ),
                  style: IconButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                    side: BorderSide(color: theme.colorScheme.outline),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                IconButton.outlined(
                  onPressed: _messaging ? null : _startMessage,
                  icon: _messaging
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(LucideIcons.messageSquare),
                  style: IconButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                    side: BorderSide(color: theme.colorScheme.outline),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      context.push('/app/explore/listing/${listing.id}/book');
                    },
                    child: const Text('Request to book'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
