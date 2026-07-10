import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/api/listings_api.dart';
import 'package:mobile/core/models/listing.dart';
import 'package:mobile/shared/widgets/listing_card.dart';
import 'package:mobile/shared/widgets/shimmer_skeleton.dart';
import 'package:mobile/shared/widgets/empty_state.dart';
import 'package:mobile/core/theme/app_spacing.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

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
  bool _nearMeActive = false;
  LatLng? _userLatLng;

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
            lat: _userLatLng?.latitude,
            lon: _userLatLng?.longitude,
            distanceMeters: _nearMeActive ? 20000.0 : null,
            sortBy: _nearMeActive ? 'nearest' : 'newest',
            pageSize: 24,
          );
      setState(() => _results = data);
      
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

  Future<void> _toggleNearMe(bool active) async {
    if (!active) {
      setState(() {
        _nearMeActive = false;
        _userLatLng = null;
      });
      _search();
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
      _search();
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
      body: Column(
        children: [
          // Near Me Proximity Filtering Toggle Bar
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _nearMeActive && _userLatLng != null
                      ? 'Sorting by nearest locations'
                      : 'Showing listings from all locations',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onBackground.withOpacity(0.6),
                  ),
                ),
                FilterChip(
                  showCheckmark: false,
                  avatar: Icon(
                    _nearMeActive ? LucideIcons.locateFixed : LucideIcons.locate,
                    size: 16,
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
                  ),
                  onSelected: _toggleNearMe,
                ),
              ],
            ),
          ),
          
          Expanded(
            child: _loading
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
                            ListingCard(
                              listing: _results!.items[index],
                              userLocation: _nearMeActive ? _userLatLng : null,
                            ),
                      ),
          ),
        ],
      ),
    );
  }
}
