import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/api/listings_api.dart';
import 'package:mobile/core/constants.dart';
import 'package:mobile/core/models/listing.dart';
import 'package:mobile/shared/widgets/listing_card.dart';
import 'package:mobile/core/theme/app_spacing.dart';
import 'package:mobile/core/theme/app_radius.dart';
import 'package:lucide_icons/lucide_icons.dart';

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

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'photography':
        return LucideIcons.camera;
      case 'tools':
        return LucideIcons.wrench;
      case 'camping':
        return LucideIcons.tent;
      case 'electronics':
        return LucideIcons.cpu;
      case 'sports':
        return LucideIcons.trophy;
      default:
        return LucideIcons.package;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'RentLanka',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadListings,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Find gear for your next project',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search cameras, tools...',
                              prefixIcon: Icon(
                                LucideIcons.search,
                                color: theme.colorScheme.onSurfaceVariant,
                                size: 20,
                              ),
                            ),
                            onSubmitted: (_) => _search(),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        IconButton.filled(
                          onPressed: _search,
                          icon: const Icon(LucideIcons.arrowRight, size: 20),
                          style: IconButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.button),
                            ),
                            minimumSize: const Size(52, 52),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xs)),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  itemCount: _dynamicCategories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.xs),
                  itemBuilder: (context, index) {
                    final category = _dynamicCategories[index];
                    return ActionChip(
                      avatar: Icon(
                        _getCategoryIcon(category),
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      label: Text(category),
                      onPressed: () => context.push(
                        '/app/explore/search?category=${Uri.encodeComponent(category)}',
                      ),
                      backgroundColor: theme.colorScheme.surfaceVariant,
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      labelStyle: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text(
                  'Latest listings',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            if (_loading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_listings == null || _listings!.items.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Text(
                    'No listings yet',
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.md),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.72,
                    crossAxisSpacing: AppSpacing.md,
                    mainAxisSpacing: AppSpacing.md,
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
