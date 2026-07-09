import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/providers/wishlist_provider.dart';
import 'package:mobile/shared/widgets/listing_card.dart';
import 'package:mobile/features/profile/screens/notifications_screen.dart';

import 'package:mobile/shared/widgets/shimmer_skeleton.dart';
import 'package:mobile/shared/widgets/empty_state.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme/app_spacing.dart';

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final wishlistState = ref.watch(wishlistProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.xs,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Saved',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      color: theme.colorScheme.onBackground,
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                      fontFamily: 'Plus Jakarta Sans',
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationsScreen(),
                        ),
                      );

                    },
                    icon: Icon(
                      LucideIcons.bell,
                      color: theme.colorScheme.onBackground,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => ref.read(wishlistProvider.notifier).loadWishlist(),
                child: CustomScrollView(
                  slivers: [

              // 2. Wishlist Grid Content
              wishlistState.when(
                loading: () => SliverPadding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.77,
                          crossAxisSpacing: AppSpacing.md,
                          mainAxisSpacing: AppSpacing.md,
                        ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => const ListingCardSkeleton(),
                      childCount: 4,
                    ),
                  ),
                ),
                error: (error, _) => SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Failed to load saved items.',
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => ref
                              .read(wishlistProvider.notifier)
                              .loadWishlist(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (items) => items.isEmpty
                    ? SliverFillRemaining(
                        hasScrollBody: false,
                        child: EmptyState(
                          icon: LucideIcons.heart,
                          title: 'No saved items yet',
                          subtitle:
                              'Save gear you want to rent for later and they will appear here.',
                          actionLabel: 'Explore gear',
                          onActionPressed: () => context.go('/app/explore'),
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.77,
                                crossAxisSpacing: AppSpacing.md,
                                mainAxisSpacing: AppSpacing.md,
                              ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) =>
                                ListingCard(listing: items[index]),
                            childCount: items.length,
                          ),
                        ),
                      ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
