import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/api/listings_api.dart';
import 'package:mobile/core/models/listing.dart';
import 'package:mobile/shared/widgets/listing_image.dart';
import 'package:mobile/core/theme/app_spacing.dart';
import 'package:mobile/core/theme/app_radius.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile/core/constants.dart';
import 'package:mobile/core/theme/app_shadows.dart';
import 'package:mobile/core/providers/wishlist_provider.dart';

class ListingCard extends ConsumerWidget {
  final Listing listing;

  const ListingCard({super.key, required this.listing});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final imageUrl = listing.images.isNotEmpty ? listing.images.first : null;

    // Stable generated rating and distance based on title hash for authentic mockup feel
    final int hash = listing.title.hashCode;
    final double rating = 4.5 + (hash.abs() % 5) * 0.1;
    final int reviewsCount = 10 + (hash.abs() % 45);
    final double distance = 1.0 + (hash.abs() % 40) * 0.1;

    final isSaved = ref
        .watch(wishlistProvider)
        .maybeWhen(
          data: (items) => items.any((item) => item.id == listing.id),
          orElse: () => false,
        );

    return GestureDetector(
      onTap: () => context.push('/app/explore/listing/${listing.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.4),
            width: 1.0,
          ),
          boxShadow: theme.brightness == Brightness.dark
              ? AppShadows.none
              : AppShadows.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top aspect ratio image stack
            AspectRatio(
              aspectRatio: 16 / 10,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.card - 1),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ListingImage(url: imageUrl, fit: BoxFit.cover),
                    ),

                    // Available Today Badge (bottom-left)
                    Positioned(
                      bottom: AppSpacing.xs,
                      left: AppSpacing.xs,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.brightness == Brightness.dark
                              ? const Color(0xFF0F172A)
                              : const Color(0xFFE8FDF0),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: theme.brightness == Brightness.dark
                                ? const Color(0xFF22C55E).withOpacity(0.4)
                                : const Color(0xFFDCFCE7),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.zap,
                              size: 10,
                              color: theme.brightness == Brightness.dark
                                  ? const Color(0xFF4ADE80)
                                  : const Color(0xFF22C55E),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Available Today',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: theme.brightness == Brightness.dark
                                    ? const Color(0xFF4ADE80)
                                    : const Color(0xFF22C55E),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Favorite Heart Button (top-right)
                    Positioned(
                      top: AppSpacing.xs,
                      right: AppSpacing.xs,
                      child: GestureDetector(
                        onTap: () => ref
                            .read(wishlistProvider.notifier)
                            .toggleWishlist(listing),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface.withOpacity(0.9),
                            shape: BoxShape.circle,
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              isSaved ? Icons.favorite : LucideIcons.heart,
                              size: 16,
                              color: isSaved
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Card details
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  SizedBox(
                    height: 36,
                    child: Text(
                      listing.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                        fontSize: 14,
                        height: 1.2,
                      ),
                    ),
                  ),

                  // Location and Distance
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.mapPin,
                        size: 10,
                        color: Color(0xFF9CA3AF),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${listing.district} • ${distance.toStringAsFixed(1)} km',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Rating
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        size: 12,
                        color: Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${rating.toStringAsFixed(1)} ($reviewsCount)',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),

                  // Price display
                  RichText(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: ListingsApi.formatPrice(listing.pricePerDay),
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const TextSpan(
                          text: ' / day',
                          style: TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 11,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ],
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
}
