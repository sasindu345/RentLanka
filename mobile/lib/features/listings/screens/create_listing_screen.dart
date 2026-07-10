import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile/shared/widgets/notification_bell_button.dart';
import 'package:go_router/go_router.dart';

import 'package:mobile/core/api/api_client.dart';
import 'package:mobile/core/api/file_api.dart';
import 'package:mobile/core/api/listings_api.dart';
import 'package:mobile/core/constants.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile/core/theme/app_spacing.dart';
import 'package:mobile/core/theme/app_radius.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/shared/widgets/location_picker_screen.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobile/core/models/listing.dart';
import 'package:mobile/core/theme/app_shadows.dart';

class CreateListingScreen extends ConsumerStatefulWidget {
  final String? initialTab;
  const CreateListingScreen({super.key, this.initialTab});

  @override
  ConsumerState<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends ConsumerState<CreateListingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _depositController = TextEditingController();
  final _rulesController = TextEditingController();
  final _addressController = TextEditingController();
  final _picker = ImagePicker();

  List<String> _dynamicCategories = categories;
  late String _category;
  String _district = districts.first;
  double _latitude = 6.9271;
  double _longitude = 79.8612;
  final List<String> _imageUrls = [];
  bool _loading = false;
  bool _uploadingImage = false;
  bool _generatingAi = false;
  String? _error;

  static const _maxImages = 5;

  List<Listing> _myListings = [];
  bool _myListingsLoading = false;
  UserProfile? _user;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab == 'my_listings' || widget.initialTab == 'listings' ? 1 : 0,
    );
    _category = _dynamicCategories.first;
    _loadCategories();
    _loadMyListings();
  }

  Future<void> _loadMyListings() async {
    if (!mounted) return;
    setState(() => _myListingsLoading = true);
    try {
      final api = ref.read(listingsApiProvider);
      final user = await api.getCurrentUser();
      final listings = await api.getMyListings();
      if (mounted) {
        setState(() {
          _user = user;
          _myListings = listings;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _myListingsLoading = false);
      }
    }
  }

  Future<void> _togglePause(Listing listing) async {
    try {
      await ref.read(listingsApiProvider).togglePauseListing(listing.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              listing.isPaused ? 'Listing resumed' : 'Listing paused',
            ),
          ),
        );
        _loadMyListings();
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(extractError(e))),
        );
      }
    }
  }

  Future<void> _confirmDelete(Listing listing) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete listing?'),
        content: Text('Remove "${listing.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref.read(listingsApiProvider).deleteListing(listing.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Listing deleted')),
        );
        _loadMyListings();
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(extractError(e))),
        );
      }
    }
  }

  void _showListingActions(Listing listing) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit listing'),
              onTap: () async {
                Navigator.pop(context);
                final updated = await context.push<bool>(
                  '/app/profile/listing/${listing.id}/edit',
                );
                if (updated == true && mounted) _loadMyListings();
              },
            ),
            ListTile(
              leading: Icon(
                listing.isPaused
                    ? Icons.play_arrow_outlined
                    : Icons.pause_outlined,
              ),
              title: Text(
                listing.isPaused ? 'Resume listing' : 'Pause listing',
              ),
              onTap: () {
                Navigator.pop(context);
                _togglePause(listing);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text(
                'Delete listing',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(listing);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadCategories() async {
    try {
      final list = await ref.read(listingsApiProvider).getCategories();
      if (mounted && list.isNotEmpty) {
        setState(() {
          _dynamicCategories = list;
          if (!list.contains(_category)) {
            _category = list.first;
          }
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _depositController.dispose();
    _rulesController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_imageUrls.length >= _maxImages) {
      setState(() => _error = 'Maximum $_maxImages photos per listing.');
      return;
    }

    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1920,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() {
      _uploadingImage = true;
      _error = null;
    });

    try {
      final url = await ref.read(fileApiProvider).uploadListingImage(picked.path);
      setState(() => _imageUrls.add(url));
    } on DioException catch (e) {
      setState(() => _error = extractError(e));
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  Future<void> _showImageSourcePicker() async {
    final theme = Theme.of(context);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppRadius.sheet),
          topRight: Radius.circular(AppRadius.sheet),
        ),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(LucideIcons.image, color: theme.colorScheme.primary),
                title: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Icon(LucideIcons.camera, color: theme.colorScheme.primary),
                title: const Text('Take a photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final isVerified = _user == null || _user!.verificationLevel >= 3;
    if (!isVerified) {
      setState(() => _error = 'Identity (NIC) and face verification are required to publish.');
      return;
    }
    if (_imageUrls.isEmpty) {
      setState(() => _error = 'Add at least one photo.');
      return;
    }
    if (_addressController.text.trim().isEmpty) {
      setState(() => _error = 'Please provide a pickup address.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(listingsApiProvider).createListing({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _category,
        'pricePerDay': double.parse(_priceController.text),
        'securityDeposit': double.parse(_depositController.text),
        'rules': _rulesController.text.trim(),
        'latitude': _latitude,
        'longitude': _longitude,
        'address': _addressController.text.trim(),
        'district': _district,
        'images': _imageUrls,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Listing published!')),
        );
        _titleController.clear();
        _descriptionController.clear();
        _priceController.clear();
        _depositController.clear();
        _rulesController.clear();
        _addressController.clear();
        setState(() {
          _imageUrls.clear();
          _latitude = 6.9271;
          _longitude = 79.8612;
        });
        _loadMyListings();
        _tabController.animateTo(1);
      }
    } on DioException catch (e) {
      setState(() => _error = extractError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _generateAiDetails() async {
    if (_imageUrls.isEmpty) return;

    setState(() {
      _generatingAi = true;
      _error = null;
    });

    try {
      final suggestion = await ref.read(listingsApiProvider).generateListingSuggestion(
        imageUrl: _imageUrls.first,
        categoryHint: _category,
      );

      setState(() {
        _titleController.text = suggestion.title;
        _descriptionController.text = suggestion.description;
        
        final matchedCat = _dynamicCategories.firstWhere(
          (c) => c.toLowerCase() == suggestion.category.toLowerCase(),
          orElse: () => _category,
        );
        _category = matchedCat;

        _priceController.text = suggestion.suggestedPricePerDay.toStringAsFixed(0);
        _depositController.text = suggestion.suggestedSecurityDeposit.toStringAsFixed(0);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✨ Listing details generated with AI!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } on DioException catch (e) {
      setState(() => _error = extractError(e));
    } finally {
      if (mounted) {
        setState(() => _generatingAi = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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
                    'List an Item',
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
            // 2. Sliding Segmented Control Tabs
            AnimatedBuilder(
              animation: _tabController.animation!,
              builder: (context, child) {
                final value = _tabController.animation!.value;
                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  padding: const EdgeInsets.all(4),
                  height: 44,
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.dark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final pillWidth = width / 2;
                      return Stack(
                        children: [
                          Positioned(
                            left: value * pillWidth,
                            width: pillWidth,
                            height: constraints.maxHeight,
                            child: Container(
                              decoration: BoxDecoration(
                                color: theme.brightness == Brightness.dark
                                    ? const Color(0xFF0F172A)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () => _tabController.animateTo(0),
                                  child: Center(
                                    child: Text(
                                      'List Item',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: value < 0.5 ? FontWeight.w700 : FontWeight.w500,
                                        color: value < 0.5
                                            ? (theme.brightness == Brightness.dark
                                                ? Colors.white
                                                : theme.colorScheme.primary)
                                            : (theme.brightness == Brightness.dark
                                                ? const Color(0xFF94A3B8)
                                                : const Color(0xFF64748B)),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () => _tabController.animateTo(1),
                                  child: Center(
                                    child: Text(
                                      'My Listings',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: value >= 0.5 ? FontWeight.w700 : FontWeight.w500,
                                        color: value >= 0.5
                                            ? (theme.brightness == Brightness.dark
                                                ? Colors.white
                                                : theme.colorScheme.primary)
                                            : (theme.brightness == Brightness.dark
                                                ? const Color(0xFF94A3B8)
                                                : const Color(0xFF64748B)),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.xs),

            // Tab View Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
            if (_user != null && _user!.verificationLevel < 3) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: theme.colorScheme.error.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(LucideIcons.alertTriangle, color: theme.colorScheme.error, size: 20),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'Verification Required',
                          style: TextStyle(
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Identity (NIC) and face verification are required to publish listings on RentLanka.',
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          context.push('/app/profile/verification').then((_) => _loadMyListings());
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.error,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(LucideIcons.shieldCheck, size: 16),
                        label: const Text('Complete Verification Now'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            
            Text(
              'Photos',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              'Stored on the dev server (api/wwwroot/uploads).',
              style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.md),
            
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ..._imageUrls.asMap().entries.map((entry) {
                    final index = entry.key;
                    final url = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.input),
                            child: CachedNetworkImage(
                              imageUrl: resolveMediaUrl(url),
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                width: 100,
                                height: 100,
                                color: theme.colorScheme.surfaceVariant,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => setState(() => _imageUrls.removeAt(index)),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(LucideIcons.x, size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  if (_imageUrls.length < _maxImages)
                    InkWell(
                      onTap: _uploadingImage ? null : _showImageSourcePicker,
                      borderRadius: BorderRadius.circular(AppRadius.input),
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          border: Border.all(color: theme.colorScheme.outline, style: BorderStyle.solid),
                          borderRadius: BorderRadius.circular(AppRadius.input),
                          color: theme.colorScheme.surfaceVariant,
                        ),
                        child: _uploadingImage
                            ? const Center(child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ))
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(LucideIcons.camera, color: theme.colorScheme.primary),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Add Photo',
                                    style: theme.textTheme.labelMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                ],
              ),
            ),
            
            if (_imageUrls.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _generatingAi ? null : _generateAiDetails,
                  icon: _generatingAi
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(LucideIcons.sparkles, color: theme.colorScheme.primary, size: 16),
                  label: Text(
                    _generatingAi ? 'Generating details...' : 'AI Listing Assist (Autofill)',
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: theme.colorScheme.primary),
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: AppSpacing.lg),
            
            // Title
            Text('Title', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(
              controller: _titleController,
              maxLength: 32,
              decoration: const InputDecoration(hintText: 'e.g. Sony FX3 Cinema Camera'),
            ),
            const SizedBox(height: AppSpacing.md),
            
            // Description
            Text('Description', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(hintText: 'Describe the gear condition, inclusions...'),
            ),
            const SizedBox(height: AppSpacing.md),
            
            // Category
            Text('Category', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _category,
              items: _dynamicCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: AppSpacing.md),
            
            // District
            Text('District', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _district,
              items: districts.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
              onChanged: (v) => setState(() => _district = v!),
            ),
            const SizedBox(height: AppSpacing.md),

            // Pickup Address
            Text('Pickup Address', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(hintText: 'e.g. 123 Galle Road, Colombo 03'),
            ),
            const SizedBox(height: AppSpacing.md),

            // Map Location Pin
            Text('Map Location Pin', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            InkWell(
              onTap: () async {
                final result = await Navigator.push<LatLng>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LocationPickerScreen(
                      initialLocation: LatLng(_latitude, _longitude),
                    ),
                  ),
                );
                if (result != null) {
                  setState(() {
                    _latitude = result.latitude;
                    _longitude = result.longitude;
                  });
                }
              },
              borderRadius: BorderRadius.circular(AppRadius.input),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.outline),
                  borderRadius: BorderRadius.circular(AppRadius.input),
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.map, color: theme.colorScheme.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select Location on Map',
                            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Coords: ${_latitude.toStringAsFixed(5)}, ${_longitude.toStringAsFixed(5)}',
                            style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    Icon(LucideIcons.chevronRight, color: theme.colorScheme.onSurfaceVariant),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            
            // Price Per Day
            Text('Price per day (LKR)', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'e.g. 5000'),
            ),
            const SizedBox(height: AppSpacing.md),
            
            // Security Deposit
            Text('Security Deposit (LKR)', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(
              controller: _depositController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'e.g. 15000'),
            ),
            const SizedBox(height: AppSpacing.md),
            
            // Rental Rules
            Text('Rental Rules', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(
              controller: _rulesController,
              decoration: const InputDecoration(hintText: 'e.g. Renter must bring NIC copies'),
            ),
            
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                _error!,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
              ),
            ],
            
            const SizedBox(height: AppSpacing.xl),
            
            Builder(
              builder: (context) {
                final isVerified = _user == null || _user!.verificationLevel >= 3;
                return SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: (_loading || _uploadingImage || !isVerified) ? null : _submit,
                    child: Text(_loading ? 'Publishing...' : (isVerified ? 'Publish Listing' : 'Verification Required')),
                  ),
                );
              }
            ),
                  ],
                ),
              ),
              _buildMyListingsTab(theme),
            ],
          ),
        ),
      ],
    ),
  ),
);
  }

  Widget _buildMyListingsTab(ThemeData theme) {
    if (_myListingsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_myListings.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadMyListings,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.packageOpen,
                size: 64,
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No listings published yet',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create your first listing to start renting out your equipment on RentLanka.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => _tabController.animateTo(0),
                icon: const Icon(LucideIcons.plus, size: 16),
                label: const Text('Publish Gear'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMyListings,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: _myListings.length,
        itemBuilder: (context, index) {
          final l = _myListings[index];
          final hasImage = l.images.isNotEmpty;
          final statusColor = l.isPaused
              ? Colors.orange
              : (l.status == 'PendingApproval'
                  ? Colors.blue
                  : (l.status == 'Rejected' ? theme.colorScheme.error : Colors.green));

          final statusText = l.isPaused
              ? 'Paused'
              : (l.status == 'PendingApproval'
                  ? 'Under Review'
                  : (l.status == 'Rejected' ? 'Rejected' : 'Active'));

          return Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.4),
                width: 1.0,
              ),
              boxShadow: theme.brightness == Brightness.dark ? AppShadows.none : AppShadows.sm,
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 80,
                      height: 80,
                      child: hasImage
                          ? CachedNetworkImage(
                              imageUrl: l.images.first,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: theme.colorScheme.surfaceVariant,
                                child: const Center(
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: theme.colorScheme.surfaceVariant,
                                child: const Icon(LucideIcons.imageOff, size: 24),
                              ),
                            )
                          : Container(
                              color: theme.colorScheme.surfaceVariant,
                              child: const Icon(LucideIcons.image, size: 24),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${l.category} · ${ListingsApi.formatPrice(l.pricePerDay)}/day',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: statusColor.withOpacity(0.2),
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            statusText.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => _showListingActions(l),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
