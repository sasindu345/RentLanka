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
import 'package:mobile/core/models/listing.dart';
import 'package:mobile/core/theme/app_theme.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _picker = ImagePicker();

  UserProfile? _user;
  String? _avatarUrl;
  bool _loading = true;
  bool _saving = false;
  bool _uploadingAvatar = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final user = await ref.read(listingsApiProvider).getCurrentUser();
      if (!mounted) return;
      setState(() {
        _user = user;
        _avatarUrl = user.avatarUrl;
        _firstNameController.text = user.firstName;
        _lastNameController.text = user.lastName;
        _phoneController.text = user.phoneNumber;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickAvatar(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 512,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() {
      _uploadingAvatar = true;
      _error = null;
    });

    try {
      final url = await ref.read(fileApiProvider).uploadAvatar(picked.path);
      if (mounted) {
        setState(() => _avatarUrl = url);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avatar updated')),
        );
      }
    } on DioException catch (e) {
      if (mounted) setState(() => _error = extractError(e));
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  Future<void> _showAvatarPicker() async {
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
                _pickAvatar(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(context);
                _pickAvatar(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await ref.read(listingsApiProvider).updateProfile(
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            phoneNumber: _phoneController.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated')),
        );
        context.pop(true);
      }
    } on DioException catch (e) {
      if (mounted) setState(() => _error = extractError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = _user;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Unable to load profile')));
    }

    final avatarUrl = _avatarUrl;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: AppTheme.primary,
                  backgroundImage: avatarUrl != null
                      ? CachedNetworkImageProvider(resolveMediaUrl(avatarUrl))
                      : null,
                  child: avatarUrl == null
                      ? Text(
                          _firstNameController.text.isNotEmpty
                              ? _firstNameController.text[0].toUpperCase()
                              : '?',
                          style: const TextStyle(fontSize: 32, color: Colors.white),
                        )
                      : null,
                ),
                if (_uploadingAvatar)
                  const Positioned.fill(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: IconButton.filled(
                    onPressed: _uploadingAvatar ? null : _showAvatarPicker,
                    icon: const Icon(Icons.camera_alt, size: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Avatar stored locally on dev server',
              style: TextStyle(fontSize: 12, color: AppTheme.muted),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _firstNameController,
              decoration: const InputDecoration(labelText: 'First name'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _lastNameController,
              decoration: const InputDecoration(labelText: 'Last name'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone number'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Email',
                helperText: 'Email cannot be changed here',
              ),
              child: Text(user.email, style: const TextStyle(fontSize: 16)),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: (_saving || _uploadingAvatar) ? null : _save,
                child: Text(_saving ? 'Saving...' : 'Save profile'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
