import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/api/listings_api.dart';
import 'package:mobile/core/models/listing.dart';
import 'package:mobile/core/theme/app_theme.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  UserProfile? _user;
  List<Listing> _myListings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final api = ref.read(listingsApiProvider);
      final user = await api.getCurrentUser();
      final listings = await api.getMyListings();
      setState(() {
        _user = user;
        _myListings = listings;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    await ref.read(listingsApiProvider).logout();
    if (mounted) context.go('/welcome');
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppTheme.primary,
                  child: Text(user.firstName[0], style: const TextStyle(fontSize: 24, color: Colors.white)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${user.firstName} ${user.lastName}',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text(user.email, style: const TextStyle(color: AppTheme.muted)),
                      if (user.isTrustedUser)
                        const Text('Trusted member', style: TextStyle(color: AppTheme.primary, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Verification', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _VerificationStep(label: 'Email verified', done: user.verificationLevel >= 0),
            _VerificationStep(label: 'Phone verified', done: user.verificationLevel >= 1),
            _VerificationStep(label: 'NIC submitted', done: user.verificationLevel >= 2),
            _VerificationStep(label: 'Face verified', done: user.verificationLevel >= 3),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('My listings', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('${_myListings.length} items', style: const TextStyle(color: AppTheme.muted)),
              ],
            ),
            const SizedBox(height: 8),
            if (_myListings.isEmpty)
              const Text('No listings yet. Tap List tab to publish.', style: TextStyle(color: AppTheme.muted))
            else
              ..._myListings.map((l) => ListTile(
                    title: Text(l.title),
                    subtitle: Text('${l.category} · ${ListingsApi.formatPrice(l.pricePerDay)}/day'),
                    trailing: l.isPaused
                        ? const Chip(label: Text('Paused', style: TextStyle(fontSize: 11)))
                        : const Chip(label: Text('Active', style: TextStyle(fontSize: 11))),
                  )),
          ],
        ),
      ),
    );
  }
}

class _VerificationStep extends StatelessWidget {
  final String label;
  final bool done;

  const _VerificationStep({required this.label, required this.done});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(done ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 20, color: done ? AppTheme.primary : AppTheme.muted),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: done ? null : AppTheme.muted)),
        ],
      ),
    );
  }
}
