import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/providers/wishlist_provider.dart';
import 'package:mobile/shared/widgets/listing_card.dart';
import 'package:mobile/shared/widgets/shimmer_skeleton.dart';
import 'package:mobile/shared/widgets/empty_state.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlistState = ref.watch(wishlistProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Saved')),
      body: wishlistState.when(
        loading: () => GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.68,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: 4,
          itemBuilder: (context, index) => const ListingCardSkeleton(),
        ),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Failed to load saved items.'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.read(wishlistProvider.notifier).loadWishlist(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (items) => items.isEmpty
            ? EmptyState(
                icon: LucideIcons.heart,
                title: 'No saved items yet',
                subtitle: 'Save gear you want to rent for later and they will appear here.',
                actionLabel: 'Explore gear',
                onActionPressed: () => context.go('/app/explore'),
              )
            : RefreshIndicator(
                onRefresh: () => ref.read(wishlistProvider.notifier).loadWishlist(),
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.68,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) => ListingCard(listing: items[index]),
                ),
              ),
      ),
    );
  }
}
