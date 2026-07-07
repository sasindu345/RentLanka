import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile/features/profile/screens/notifications_screen.dart';

import 'package:mobile/core/api/api_client.dart';
import 'package:mobile/core/api/file_api.dart';
import 'package:mobile/core/api/listings_api.dart';
import 'package:mobile/core/constants.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile/core/theme/app_spacing.dart';
import 'package:mobile/core/theme/app_radius.dart';
import 'package:lucide_icons/lucide_icons.dart';

class CreateListingScreen extends ConsumerStatefulWidget {
  const CreateListingScreen({super.key});

  @override
  ConsumerState<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends ConsumerState<CreateListingScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _depositController = TextEditingController();
  final _rulesController = TextEditingController();
  final _picker = ImagePicker();

  List<String> _dynamicCategories = categories;
  late String _category;
  String _district = districts.first;
  final List<String> _imageUrls = [];
  bool _loading = false;
  bool _uploadingImage = false;
  bool _generatingAi = false;
  String? _error;

  static const _maxImages = 5;

  @override
  void initState() {
    super.initState();
    _category = _dynamicCategories.first;
    _loadCategories();
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
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _depositController.dispose();
    _rulesController.dispose();
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
    if (_imageUrls.isEmpty) {
      setState(() => _error = 'Add at least one photo.');
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
        'latitude': 6.9271,
        'longitude': 79.8612,
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
        setState(() => _imageUrls.clear());
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: theme.colorScheme.primary.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.info, color: theme.colorScheme.primary, size: 20),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'Phone verification (Level 1) is required to publish listings.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            
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
            
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: (_loading || _uploadingImage) ? null : _submit,
                child: Text(_loading ? 'Publishing...' : 'Publish Listing'),
              ),
            ),
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
