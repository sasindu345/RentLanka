import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/api/listings_api.dart';
import 'package:mobile/features/profile/screens/notifications_screen.dart';

import 'package:mobile/core/constants.dart';
import 'package:mobile/core/models/listing.dart';
import 'package:mobile/shared/widgets/listing_card.dart';
import 'package:mobile/shared/widgets/shimmer_skeleton.dart';
import 'package:mobile/core/theme/app_spacing.dart';
import 'package:mobile/core/theme/app_radius.dart';
import 'package:mobile/core/theme/app_shadows.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HomeFeedScreen extends ConsumerStatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  ConsumerState<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends ConsumerState<HomeFeedScreen> {
  final _searchController = TextEditingController();
  PaginatedListings? _listings;
  UserProfile? _user;
  bool _loading = true;
  String? _selectedCategory;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Photography', 'icon': LucideIcons.camera},
    {'name': 'Tools', 'icon': LucideIcons.wrench},
    {'name': 'Camping', 'icon': LucideIcons.tent},
    {'name': 'Gaming', 'icon': LucideIcons.gamepad2},
    {'name': 'Audio', 'icon': LucideIcons.music},
    {'name': 'Outdoor', 'icon': LucideIcons.bike},
  ];

  @override
  void initState() {
    super.initState();
    _loadListings();
    _loadUser();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    try {
      final user = await ref.read(listingsApiProvider).getCurrentUser();
      if (mounted) {
        setState(() {
          _user = user;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadListings() async {
    setState(() => _loading = true);
    try {
      final data = await ref
          .read(listingsApiProvider)
          .searchListings(pageSize: 12, category: _selectedCategory);
      setState(() => _listings = data);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _search({String? customQuery}) {
    final q = customQuery ?? _searchController.text.trim();
    context.push('/app/explore/search?q=${Uri.encodeComponent(q)}');
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Card dimensions — shared across both horizontal and grid sections
    // so both render pixel-perfect identical cards.
    final double cardWidth =
        (MediaQuery.of(context).size.width - AppSpacing.md * 3) / 2;
    final double cardHeight = cardWidth / 0.82;

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
                    'Explore',
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
                onRefresh: _loadListings,
                child: CustomScrollView(
                  slivers: [
                    // 2. AI Search Input Card
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs,
                        ),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(18, 14, 10, 14),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: theme.colorScheme.outline.withOpacity(0.4),
                              width: 1.0,
                            ),
                            boxShadow: theme.brightness == Brightness.dark
                                ? AppShadows.none
                                : AppShadows.md,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                LucideIcons.search,
                                color: Color(0xFF9CA3AF),
                                size: 22,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  textInputAction: TextInputAction.send,
                                  onSubmitted: (_) => _search(),
                                  maxLines: null,
                                  keyboardType: TextInputType.multiline,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Ask RentLanka AI...',
                                    filled: false,
                                    border: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    errorBorder: InputBorder.none,
                                    disabledBorder: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                    hintStyle: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.onSurfaceVariant
                                          .withOpacity(0.6),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: () => _search(),
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4F46E5),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      LucideIcons.send,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // 4. Categories Circular List
                    SliverToBoxAdapter(
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
                            child: Text(
                              'Categories',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Plus Jakarta Sans',
                                color: theme.colorScheme.onBackground,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 92,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                              ),
                              itemCount: _categories.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 16),
                              itemBuilder: (context, index) {
                                final cat = _categories[index];
                                final isSelected =
                                    _selectedCategory == cat['name'];
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      if (_selectedCategory == cat['name']) {
                                        _selectedCategory = null;
                                      } else {
                                        _selectedCategory = cat['name'];
                                      }
                                    });
                                    _loadListings();
                                  },
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 56,
                                        height: 56,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? theme.colorScheme.primary
                                              : (theme.brightness ==
                                                        Brightness.dark
                                                    ? const Color(0xFF1E293B)
                                                    : const Color(0xFFF1F5F9)),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Icon(
                                            cat['icon'],
                                            color: isSelected
                                                ? theme.colorScheme.onPrimary
                                                : (theme.brightness ==
                                                          Brightness.dark
                                                      ? const Color(0xFF94A3B8)
                                                      : const Color(
                                                          0xFF64748B,
                                                        )),
                                            size: 22,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        cat['name'],
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: isSelected
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: isSelected
                                              ? theme.colorScheme.primary
                                              : theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 6. Recommended For You Horizontal Grid List
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.md,
                              AppSpacing.xs,
                              AppSpacing.md,
                              AppSpacing.xs,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Recommended for you',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Plus Jakarta Sans',
                                    color: theme.colorScheme.onBackground,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () =>
                                      _search(customQuery: 'Recommended'),
                                  child: const Text(
                                    'See all',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF4F46E5),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: cardHeight,
                            child: _loading
                                ? ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.md,
                                    ),
                                    itemCount: 3,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(width: AppSpacing.md),
                                    itemBuilder: (_, __) => SizedBox(
                                      width: cardWidth,
                                      child: const ListingCardSkeleton(),
                                    ),
                                  )
                                : (_listings == null ||
                                      _listings!.items.isEmpty)
                                ? const Center(child: Text('No listings yet'))
                                : ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.md,
                                    ),
                                    itemCount: _listings!.items.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(width: AppSpacing.md),
                                    itemBuilder: (context, index) {
                                      return SizedBox(
                                        width: cardWidth,
                                        child: ListingCard(
                                          listing: _listings!.items[index],
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),

                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.lg,
                          AppSpacing.md,
                          AppSpacing.xs,
                        ),
                        child: Text(
                          'Latest listings',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Plus Jakarta Sans',
                            color: theme.colorScheme.onBackground,
                          ),
                        ),
                      ),
                    ),
                    if (_loading)
                      SliverPadding(
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
                      )
                    else if (_listings == null || _listings!.items.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Text(
                            'No listings yet',
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
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
                                ListingCard(listing: _listings!.items[index]),
                            childCount: _listings!.items.length,
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
