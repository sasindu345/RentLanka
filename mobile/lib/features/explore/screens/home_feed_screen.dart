import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/api/listings_api.dart';
import 'package:mobile/core/constants.dart';
import 'package:mobile/core/models/listing.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/shared/widgets/listing_card.dart';

class HomeFeedScreen extends ConsumerStatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  ConsumerState<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends ConsumerState<HomeFeedScreen> {
  final _searchController = TextEditingController();
  PaginatedListings? _listings;
  bool _loading = true;
  List<String> _dynamicCategories = categories;

  @override
  void initState() {
    super.initState();
    _loadListings();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final list = await ref.read(listingsApiProvider).getCategories();
      if (mounted && list.isNotEmpty) {
        setState(() {
          _dynamicCategories = list;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadListings() async {
    setState(() => _loading = true);
    try {
      final data = await ref.read(listingsApiProvider).searchListings(pageSize: 12);
      setState(() => _listings = data);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _search() {
    final q = _searchController.text.trim();
    context.push('/app/explore/search?q=${Uri.encodeComponent(q)}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RentLanka', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: _loadListings,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Search cameras, tools...',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onSubmitted: (_) => _search(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _search,
                      icon: const Icon(Icons.arrow_forward),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _dynamicCategories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final category = _dynamicCategories[index];
                    return ActionChip(
                      label: Text(category),
                      onPressed: () => context.push(
                        '/app/explore/search?category=${Uri.encodeComponent(category)}',
                      ),
                    );
                  },
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Latest listings',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            if (_loading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_listings == null || _listings!.items.isEmpty)
              const SliverFillRemaining(
                child: Center(child: Text('No listings yet', style: TextStyle(color: AppTheme.muted))),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.68,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => ListingCard(listing: _listings!.items[index]),
                    childCount: _listings!.items.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
