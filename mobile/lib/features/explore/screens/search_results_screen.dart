import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/api/listings_api.dart';
import 'package:mobile/core/models/listing.dart';
import 'package:mobile/shared/widgets/listing_card.dart';
import 'package:mobile/shared/widgets/shimmer_skeleton.dart';
import 'package:mobile/shared/widgets/empty_state.dart';
import 'package:mobile/core/theme/app_spacing.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SearchResultsScreen extends ConsumerStatefulWidget {
  final String initialQuery;
  final String? category;

  const SearchResultsScreen({
    super.key,
    required this.initialQuery,
    this.category,
  });

  @override
  ConsumerState<SearchResultsScreen> createState() =>
      _SearchResultsScreenState();
}

class _SearchResultsScreenState extends ConsumerState<SearchResultsScreen> {
  PaginatedListings? _results;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _search());
  }

  Future<void> _search() async {
    setState(() => _loading = true);
    try {
      final data = await ref
          .read(listingsApiProvider)
          .searchListings(
            query: widget.initialQuery.isNotEmpty ? widget.initialQuery : null,
            category: widget.category,
            pageSize: 24,
          );
      setState(() => _results = data);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = widget.initialQuery.isEmpty
        ? (widget.category ?? 'Browse')
        : widget.initialQuery;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: _loading
          ? GridView.builder(
              padding: const EdgeInsets.all(AppSpacing.lg),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.73,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
              ),
              itemCount: 6,
              itemBuilder: (context, index) => const ListingCardSkeleton(),
            )
          : _results == null || _results!.items.isEmpty
          ? EmptyState(
              icon: LucideIcons.search,
              title: 'No results found',
              subtitle:
                  'Try adjusting your search terms or filters to find what you need.',
              actionLabel: 'Go back',
              onActionPressed: () => Navigator.maybePop(context),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(AppSpacing.lg),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.73,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
              ),
              itemCount: _results!.items.length,
              itemBuilder: (context, index) =>
                  ListingCard(listing: _results!.items[index]),
            ),
    );
  }
}
