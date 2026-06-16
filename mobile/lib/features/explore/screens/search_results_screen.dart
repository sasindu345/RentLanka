import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/api/listings_api.dart';
import 'package:mobile/core/models/listing.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/shared/widgets/listing_card.dart';

class SearchResultsScreen extends ConsumerStatefulWidget {
  final String initialQuery;
  final String? category;

  const SearchResultsScreen({
    super.key,
    required this.initialQuery,
    this.category,
  });

  @override
  ConsumerState<SearchResultsScreen> createState() => _SearchResultsScreenState();
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
      final data = await ref.read(listingsApiProvider).searchListings(
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
    return Scaffold(
      appBar: AppBar(title: Text(widget.initialQuery.isEmpty ? 'Browse' : widget.initialQuery)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _results == null || _results!.items.isEmpty
              ? const Center(child: Text('No results found', style: TextStyle(color: AppTheme.muted)))
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.68,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _results!.items.length,
                  itemBuilder: (context, index) => ListingCard(listing: _results!.items[index]),
                ),
    );
  }
}
