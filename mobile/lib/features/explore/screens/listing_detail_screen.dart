import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/api/api_client.dart';
import 'package:mobile/core/api/bookings_api.dart';
import 'package:mobile/core/api/listings_api.dart';
import 'package:mobile/core/models/listing.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/shared/widgets/listing_image.dart';

class ListingDetailScreen extends ConsumerStatefulWidget {
  final String id;

  const ListingDetailScreen({super.key, required this.id});

  @override
  ConsumerState<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends ConsumerState<ListingDetailScreen> {
  Listing? _listing;
  List<AvailabilityBlockResponse> _blocks = [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final listing = await ref.read(listingsApiProvider).getListing(widget.id);
      final blocks = await ref.read(bookingsApiProvider).getListingAvailability(widget.id);
      setState(() {
        _listing = listing;
        _blocks = blocks;
      });
    } catch (_) {
      // Ignore if details load fails
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(listingsApiProvider).addToWishlist(widget.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved to wishlist')),
        );
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(extractError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final listing = _listing;
    if (listing == null) {
      return const Scaffold(body: Center(child: Text('Listing not found')));
    }

    final imageUrl = listing.images.isNotEmpty ? listing.images.first : null;

    return Scaffold(
      appBar: AppBar(title: Text(listing.title, maxLines: 1, overflow: TextOverflow.ellipsis)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 10,
              child: ListingImage(url: imageUrl, width: double.infinity),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.category.toUpperCase(),
                    style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Text(listing.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(listing.district, style: const TextStyle(color: AppTheme.muted)),
                  const SizedBox(height: 16),
                  Text(
                    '${ListingsApi.formatPrice(listing.pricePerDay)} / day',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Deposit: ${ListingsApi.formatPrice(listing.securityDeposit)}',
                    style: const TextStyle(color: AppTheme.muted),
                  ),
                  const SizedBox(height: 16),
                  Text(listing.description),
                  if (listing.rules.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text('Rental rules', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(listing.rules, style: const TextStyle(color: AppTheme.muted)),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppTheme.primary,
                        child: Text(listing.owner.firstName[0]),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${listing.owner.firstName} ${listing.owner.lastName}',
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          if (listing.owner.isTrustedUser)
                            const Text('Trusted owner', style: TextStyle(color: AppTheme.primary, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Listing Availability', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (_blocks.isEmpty)
                    const Text('Available all dates', style: TextStyle(color: Colors.green, fontSize: 14, fontWeight: FontWeight.bold))
                  else
                    ..._blocks.map((b) {
                      final startStr = '${b.startDate.day}/${b.startDate.month}/${b.startDate.year}';
                      final endStr = '${b.endDate.day}/${b.endDate.month}/${b.endDate.year}';
                      final isManual = b.type == 'Manual';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isManual ? Colors.grey.shade100 : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isManual ? Colors.grey.shade300 : Colors.red.shade100),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$startStr - $endStr',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: isManual ? Colors.black87 : Colors.red.shade900),
                            ),
                            Text(
                              isManual ? 'Blocked by Owner' : 'Booked',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isManual ? Colors.grey.shade700 : Colors.red.shade700),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconButton.outlined(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.favorite_border),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    context.push('/app/explore/listing/${listing.id}/book');
                  },
                  style: FilledButton.styleFrom(backgroundColor: AppTheme.accent),
                  child: const Text('Request to book'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
