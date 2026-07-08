import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/api/listings_api.dart';
import 'package:mobile/core/models/listing.dart';

class WishlistNotifier extends StateNotifier<AsyncValue<List<Listing>>> {
  final ListingsApi _api;

  WishlistNotifier(this._api) : super(const AsyncValue.loading()) {
    loadWishlist();
  }

  Future<void> loadWishlist() async {
    try {
      final data = await _api.getWishlist();
      state = AsyncValue.data(data.items);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  bool isWishlisted(String listingId) {
    return state.maybeWhen(
      data: (items) => items.any((item) => item.id == listingId),
      orElse: () => false,
    );
  }

  Future<void> toggleWishlist(Listing listing) async {
    final currentItems = state.value ?? [];
    final exists = currentItems.any((item) => item.id == listing.id);

    // Optimistic UI Update for instant buttery smooth feedback micro-animation!
    if (exists) {
      state = AsyncValue.data(currentItems.where((item) => item.id != listing.id).toList());
      try {
        await _api.removeFromWishlist(listing.id);
      } catch (e) {
        // Rollback on API failure
        state = AsyncValue.data(currentItems);
      }
    } else {
      state = AsyncValue.data([...currentItems, listing]);
      try {
        await _api.addToWishlist(listing.id);
      } catch (e) {
        // Rollback on API failure
        state = AsyncValue.data(currentItems);
      }
    }
  }
}

final wishlistProvider = StateNotifierProvider<WishlistNotifier, AsyncValue<List<Listing>>>((ref) {
  return WishlistNotifier(ref.watch(listingsApiProvider));
});
