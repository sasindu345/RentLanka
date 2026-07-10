import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/api/listings_api.dart';
import 'package:mobile/shared/widgets/notification_bell_button.dart';

import 'package:mobile/core/models/listing.dart';
import 'package:mobile/shared/widgets/listing_card.dart';
import 'package:mobile/shared/widgets/shimmer_skeleton.dart';
import 'package:mobile/core/theme/app_spacing.dart';
import 'package:mobile/core/theme/app_shadows.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class HomeFeedScreen extends ConsumerStatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  ConsumerState<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends ConsumerState<HomeFeedScreen> {
  final _searchController = TextEditingController();
  PaginatedListings? _listings;
  bool _loading = true;
  String? _selectedCategory;
  bool _nearMeActive = false;
  LatLng? _userLatLng;

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
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadListings() async {
    setState(() => _loading = true);
    try {
      final data = await ref
          .read(listingsApiProvider)
          .searchListings(
            pageSize: 12,
            category: _selectedCategory,
            lat: _nearMeActive ? _userLatLng?.latitude : null,
            lon: _nearMeActive ? _userLatLng?.longitude : null,
            distanceMeters: _nearMeActive ? 20000.0 : null,
            sortBy: _nearMeActive ? 'nearest' : 'newest',
          );
      setState(() => _listings = data);
      
      if (_nearMeActive && mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Found ${data.total} items within 20 km of your location'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleNearMe(bool selected) async {
    if (!selected) {
      setState(() {
        _nearMeActive = false;
        _userLatLng = null;
      });
      _loadListings();
      return;
    }

    setState(() => _loading = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location services are disabled in system settings.')),
          );
        }
        setState(() {
          _nearMeActive = false;
          _loading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permissions are denied.')),
            );
          }
          setState(() {
            _nearMeActive = false;
            _loading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are permanently denied. Please enable them in settings.')),
          );
        }
        setState(() {
          _nearMeActive = false;
          _loading = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _nearMeActive = true;
        _userLatLng = LatLng(position.latitude, position.longitude);
      });
      _loadListings();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not determine current position: $e')),
        );
      }
      setState(() {
        _nearMeActive = false;
        _loading = false;
      });
    }
  }

  void _search({String? customQuery}) {
    final q = customQuery ?? _searchController.text.trim();
    context.push('/app/explore/search?q=${Uri.encodeComponent(q)}');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double cardWidth =
        (MediaQuery.of(context).size.width - AppSpacing.md * 3) / 2;
    final double cardHeight = cardWidth / 0.78;

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
                  const NotificationBellButton(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
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
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _search(),
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        style: TextStyle(
                          fontSize: 14,
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
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurfaceVariant
                                .withOpacity(0.6),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => _search(),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4F46E5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Icon(
                            LucideIcons.send,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadListings,
                child: CustomScrollView(
                  slivers: [
                    SliverPersistentHeader(
                      floating: true,
                      delegate: _CategoriesSliverDelegate(
                        height: 148,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.md,
                                AppSpacing.sm,
                                AppSpacing.md,
                                AppSpacing.xs,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Categories',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'Plus Jakarta Sans',
                                      color: theme.colorScheme.onBackground,
                                    ),
                                  ),
                                  FilterChip(
                                    showCheckmark: false,
                                    avatar: Icon(
                                      _nearMeActive ? LucideIcons.locateFixed : LucideIcons.locate,
                                      size: 14,
                                      color: _nearMeActive
                                          ? theme.colorScheme.onPrimary
                                          : theme.colorScheme.primary,
                                    ),
                                    label: const Text('Near Me'),
                                    selected: _nearMeActive,
                                    selectedColor: theme.colorScheme.primary,
                                    labelStyle: TextStyle(
                                      color: _nearMeActive
                                          ? theme.colorScheme.onPrimary
                                          : theme.colorScheme.onSurface,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                                    onSelected: _toggleNearMe,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              height: 80,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: 0.0,
                                ),
                                itemCount: _categories.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 12),
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
                                          width: 46,
                                          height: 46,
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
                                              size: 18,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          cat['name'],
                                          style: TextStyle(
                                            fontSize: 11,
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
                    ),
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
                                          userLocation: _nearMeActive ? _userLatLng : null,
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
                                ListingCard(
                                  listing: _listings!.items[index],
                                  userLocation: _nearMeActive ? _userLatLng : null,
                                ),
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

class _CategoriesSliverDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _CategoriesSliverDelegate({required this.child, required this.height});

  @override
  double get minExtent => 0;

  @override
  double get maxExtent => height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final double visibleHeight = height - shrinkOffset;
    final double percent = (visibleHeight / height).clamp(0.0, 1.0);

    return Container(
      color: Theme.of(context).colorScheme.background,
      height: visibleHeight,
      child: ClipRect(
        child: OverflowBox(
          minHeight: height,
          maxHeight: height,
          alignment: Alignment.topCenter,
          child: Opacity(
            opacity: percent,
            child: child,
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_CategoriesSliverDelegate oldDelegate) {
    return child != oldDelegate.child || height != oldDelegate.height;
  }
}
