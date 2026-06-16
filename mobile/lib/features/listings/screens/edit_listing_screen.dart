import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile/core/api/api_client.dart';
import 'package:mobile/core/api/file_api.dart';
import 'package:mobile/core/api/listings_api.dart';
import 'package:mobile/core/constants.dart';
import 'package:mobile/core/theme/app_theme.dart';

class EditListingScreen extends ConsumerStatefulWidget {
  final String listingId;

  const EditListingScreen({super.key, required this.listingId});

  @override
  ConsumerState<EditListingScreen> createState() => _EditListingScreenState();
}

class _EditListingScreenState extends ConsumerState<EditListingScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _depositController = TextEditingController();
  final _rulesController = TextEditingController();
  final _picker = ImagePicker();

  String _category = categories.first;
  String _district = districts.first;
  double _latitude = 6.9271;
  double _longitude = 79.8612;
  List<String> _imageUrls = [];

  bool _loading = true;
  bool _saving = false;
  bool _uploadingImage = false;
  String? _error;

  static const _maxImages = 5;

  @override
  void initState() {
    super.initState();
    _loadListing();
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

  Future<void> _loadListing() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final listing = await ref.read(listingsApiProvider).getListing(widget.listingId);
      if (!mounted) return;
      setState(() {
        _titleController.text = listing.title;
        _descriptionController.text = listing.description;
        _priceController.text = listing.pricePerDay.toStringAsFixed(0);
        _depositController.text = listing.securityDeposit.toStringAsFixed(0);
        _rulesController.text = listing.rules;
        _category = listing.category;
        _district = listing.district;
        _latitude = listing.latitude;
        _longitude = listing.longitude;
        _imageUrls = List<String>.from(listing.images);
      });
    } on DioException catch (e) {
      if (mounted) setState(() => _error = extractError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_imageUrls.isEmpty) {
      setState(() => _error = 'Add at least one photo.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await ref.read(listingsApiProvider).updateListing(widget.listingId, {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _category,
        'pricePerDay': double.parse(_priceController.text),
        'securityDeposit': double.parse(_depositController.text),
        'rules': _rulesController.text.trim(),
        'latitude': _latitude,
        'longitude': _longitude,
        'district': _district,
        'images': _imageUrls,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Listing updated!')),
        );
        context.pop(true);
      }
    } on DioException catch (e) {
      setState(() => _error = extractError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Edit listing')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Photos', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ..._imageUrls.asMap().entries.map((entry) {
                    final index = entry.key;
                    final url = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: resolveMediaUrl(url),
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                width: 100,
                                height: 100,
                                color: Colors.grey.shade200,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => setState(() => _imageUrls.removeAt(index)),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, size: 16, color: Colors.white),
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
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          borderRadius: BorderRadius.circular(8),
                          color: AppTheme.card,
                        ),
                        child: _uploadingImage
                            ? const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo_outlined, color: AppTheme.primary),
                                  SizedBox(height: 4),
                                  Text('Add', style: TextStyle(fontSize: 12, color: AppTheme.muted)),
                                ],
                              ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Title')),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 4,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _district,
              decoration: const InputDecoration(labelText: 'District'),
              items: districts.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
              onChanged: (v) => setState(() => _district = v!),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: 'Price per day (LKR)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _depositController,
              decoration: const InputDecoration(labelText: 'Security deposit (LKR)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(controller: _rulesController, decoration: const InputDecoration(labelText: 'Rental rules')),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: (_saving || _uploadingImage) ? null : _save,
                style: FilledButton.styleFrom(backgroundColor: AppTheme.accent),
                child: Text(_saving ? 'Saving...' : 'Save changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
