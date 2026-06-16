import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/api/listings_api.dart';
import 'package:mobile/core/constants.dart';
import 'package:mobile/core/models/listing.dart';
import 'package:mobile/core/theme/app_theme.dart';

class ListingCard extends StatelessWidget {
  final Listing listing;

  const ListingCard({super.key, required this.listing});

  @override
  Widget build(BuildContext context) {
    final imageUrl = listing.images.isNotEmpty ? listing.images.first : null;

    return GestureDetector(
      onTap: () => context.push('/app/explore/listing/${listing.id}'),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: resolveMediaUrl(imageUrl),
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: Colors.grey.shade200),
                      errorWidget: (_, __, ___) => const Icon(Icons.image_not_supported),
                    )
                  : Container(
                      width: double.infinity,
                      color: Colors.grey.shade200,
                      child: const Center(child: Icon(Icons.image_outlined, color: AppTheme.muted)),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    listing.category.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                      letterSpacing: 0.5,
                      height: 1.2,
                    ),
                  ),
                  Text(
                    listing.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, height: 1.2),
                  ),
                  Text(
                    listing.district,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppTheme.muted, fontSize: 11, height: 1.2),
                  ),
                  Text(
                    '${ListingsApi.formatPrice(listing.pricePerDay)}/day',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, height: 1.2),
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
