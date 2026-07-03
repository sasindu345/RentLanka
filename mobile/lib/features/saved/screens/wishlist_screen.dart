import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/api/listings_api.dart';
import 'package:mobile/core/models/listing.dart';
import 'package:mobile/shared/widgets/listing_card.dart';
import 'package:mobile/shared/widgets/shimmer_skeleton.dart';
import 'package:mobile/shared/widgets/empty_state.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';

class WishlistScreen extends ConsumerStatefulWidget {
  const WishlistScreen({super.key});

  @override
  ConsumerState<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends ConsumerState<WishlistScreen> {
  bool _loading = true;
  List<Listing> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ref.read(listingsApiProvider).getWishlist();
      setState(() => _items = data.items);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved')),
      body: _loading
          ? GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.72,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: 4,
              itemBuilder: (context, index) => const ListingCardSkeleton(),
            )
          : _items.isEmpty
              ? EmptyState(
                  icon: LucideIcons.heart,
                  title: 'No saved items yet',
                  subtitle: 'Save gear you want to rent for later and they will appear here.',
                  actionLabel: 'Explore gear',
                  onActionPressed: () => context.go('/app/explore'),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.72,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _items.length,
                    itemBuilder: (context, index) => ListingCard(listing: _items[index]),
                  ),
                ),
    );
  }
}

