import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/api/listings_api.dart';
import 'package:mobile/core/models/listing.dart';
import 'package:mobile/shared/widgets/listing_image.dart';
import 'package:mobile/core/theme/app_spacing.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ListingCard extends StatelessWidget {
  final Listing listing;

  const ListingCard({super.key, required this.listing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imageUrl = listing.images.isNotEmpty ? listing.images.first : null;

    return GestureDetector(
      onTap: () => context.push('/app/explore/listing/${listing.id}'),
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ListingImage(
                      url: imageUrl,
                      width: double.infinity,
                    ),
                  ),
                  Positioned(
                    top: AppSpacing.xs,
                    right: AppSpacing.xs,
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface.withOpacity(0.85),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          LucideIcons.heart,
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        onPressed: () {
                          // Wishlist functionality handled in detail/wishlist screen
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    listing.category.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    listing.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    listing.district,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${ListingsApi.formatPrice(listing.pricePerDay)}/day',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
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
