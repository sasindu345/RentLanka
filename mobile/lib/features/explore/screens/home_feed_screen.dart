import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/api/listings_api.dart';
import 'package:mobile/core/constants.dart';
import 'package:mobile/core/models/listing.dart';
import 'package:mobile/shared/widgets/listing_card.dart';
import 'package:mobile/shared/widgets/shimmer_skeleton.dart';
import 'package:mobile/core/theme/app_spacing.dart';
import 'package:mobile/core/theme/app_radius.dart';
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



  final List<Map<String, dynamic>> _categories = [
    {'name': 'Photography', 'icon': LucideIcons.camera, 'color': Color(0xFFEEF2FF), 'iconColor': Color(0xFF4F46E5)},
    {'name': 'Tools', 'icon': LucideIcons.wrench, 'color': Color(0xFFFDF2F8), 'iconColor': Color(0xFFDB2777)},
    {'name': 'Camping', 'icon': LucideIcons.tent, 'color': Color(0xFFF0FDF4), 'iconColor': Color(0xFF16A34A)},
    {'name': 'Gaming', 'icon': LucideIcons.gamepad2, 'color': Color(0xFFFFF7ED), 'iconColor': Color(0xFFEA580C)},
    {'name': 'Audio', 'icon': LucideIcons.music, 'color': Color(0xFFFEF2F2), 'iconColor': Color(0xFFDC2626)},
    {'name': 'Outdoor', 'icon': LucideIcons.bike, 'color': Color(0xFFECFDF5), 'iconColor': Color(0xFF059669)},
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
      final data = await ref.read(listingsApiProvider).searchListings(pageSize: 12);
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
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _loadListings,
          child: CustomScrollView(
            slivers: [
              // 1. Explore Page Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.xs),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Explore',
                        style: theme.textTheme.headlineLarge?.copyWith(
                          color: theme.colorScheme.onBackground,
                          fontWeight: FontWeight.bold,
                          fontSize: 32,
                          fontFamily: 'Plus Jakarta Sans',
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Notifications coming soon!',
                                style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
                              ),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: theme.colorScheme.secondaryContainer,
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
              ),

              // 2. AI Search Input Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(18, 14, 10, 14),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: theme.brightness == Brightness.dark ? Colors.black38 : Colors.black12,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.search, color: Color(0xFF9CA3AF), size: 22),
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
                                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
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
                      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.xs),
                      child: Text(
                        'Categories',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onBackground,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 92,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        itemCount: _categories.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 16),
                        itemBuilder: (context, index) {
                          final cat = _categories[index];
                          return GestureDetector(
                            onTap: () => context.push(
                              '/app/explore/search?category=${Uri.encodeComponent(cat['name'])}',
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: cat['color'],
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Icon(
                                      cat['icon'],
                                      color: cat['iconColor'],
                                      size: 22,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  cat['name'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: theme.colorScheme.onSurfaceVariant,
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
                      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.xs),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recommended for you',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onBackground,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _search(customQuery: 'Recommended'),
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
                      height: 260,
                      child: _loading
                          ? ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                              itemCount: 3,
                              separatorBuilder: (_, __) => const SizedBox(width: 14),
                              itemBuilder: (_, __) => const SizedBox(
                                width: 190,
                                child: ListingCardSkeleton(),
                              ),
                            )
                          : (_listings == null || _listings!.items.isEmpty)
                              ? const Center(child: Text('No listings yet'))
                              : ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                                  itemCount: _listings!.items.length,
                                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                                  itemBuilder: (context, index) {
                                    return SizedBox(
                                      width: 190,
                                      child: ListingCard(listing: _listings!.items[index]),
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.xs),
                  child: Text(
                    'Latest listings',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onBackground,
                    ),
                  ),
                ),
              ),
              if (_loading)
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
                      childAspectRatio: 0.66, // Slightly taller aspect ratio to fit text safely
                      crossAxisSpacing: AppSpacing.md,
                      mainAxisSpacing: AppSpacing.md,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => ListingCard(listing: _listings!.items[index]),
                      childCount: _listings!.items.length,
                    ),
                  ),
                ),
              
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        ),
      ),
    );
  }
}
