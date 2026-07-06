import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/api/api_client.dart';
import 'package:mobile/core/api/listings_api.dart';
import 'package:mobile/core/constants.dart';
import 'package:mobile/core/models/listing.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/providers/app_mode_provider.dart';
import 'package:mobile/core/providers/theme_provider.dart';
import 'package:lucide_icons/lucide_icons.dart';

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

      if (mounted) {
        final currentAppMode = ref.read(appModeProvider);
        final backendAppMode = user.role.toLowerCase() == 'owner'
            ? UserAppMode.owner
            : UserAppMode.renter;
        if (currentAppMode != backendAppMode) {
          ref.read(appModeProvider.notifier).state = backendAppMode;
        }
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    await ref.read(listingsApiProvider).logout();
    if (mounted) context.go('/welcome');
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
        _load();
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(extractError(e))));
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Listing deleted')));
        _load();
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(extractError(e))));
      }
    }
  }

  void _showListingActions(Listing listing) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
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
                if (updated == true && mounted) _load();
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = _user;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Unable to load profile')),
      );
    }

    final appMode = ref.watch(appModeProvider);
    final themeMode = ref.watch(themeProvider);

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
                  backgroundImage: user.avatarUrl != null
                      ? CachedNetworkImageProvider(
                          resolveMediaUrl(user.avatarUrl!),
                        )
                      : null,
                  child: user.avatarUrl == null
                      ? Text(
                          user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : 'U',
                          style: const TextStyle(
                            fontSize: 24,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${user.firstName} ${user.lastName}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        user.email,
                        style: const TextStyle(color: AppTheme.muted),
                      ),
                      if (user.phoneNumber.isNotEmpty)
                        Text(
                          user.phoneNumber,
                          style: const TextStyle(
                            color: AppTheme.muted,
                            fontSize: 13,
                          ),
                        ),
                      if (user.isTrustedUser)
                        const Text(
                          'Trusted member',
                          style: TextStyle(
                            color: AppTheme.primary,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () async {
                    final updated = await context.push<bool>(
                      '/app/profile/edit',
                    );
                    if (updated == true && mounted) _load();
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Application Mode',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              child: SwitchListTile(
                title: const Text('Switch to Owner Mode'),
                subtitle: Text(
                  appMode == UserAppMode.owner
                      ? 'Showing hosting tools & listings'
                      : 'Showing renter explore & wishlist',
                ),
                value: appMode == UserAppMode.owner,
                activeColor: AppTheme.primary,
                onChanged: (val) async {
                  if (_user == null) return;
                  final newMode = val ? UserAppMode.owner : UserAppMode.renter;
                  final newRole = val ? 'Owner' : 'Renter';

                  setState(() => _loading = true);
                  try {
                    await ref
                        .read(listingsApiProvider)
                        .updateProfile(
                          firstName: _user!.firstName,
                          lastName: _user!.lastName,
                          phoneNumber: _user!.phoneNumber,
                          role: newRole,
                        );
                    ref.read(appModeProvider.notifier).state = newMode;
                    await _load();
                  } on DioException catch (e) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(extractError(e))));
                  } finally {
                    if (mounted) setState(() => _loading = false);
                  }
                },
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Theme Preference',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment<ThemeMode>(
                    value: ThemeMode.system,
                    label: Text('System'),
                    icon: Icon(LucideIcons.laptop, size: 16),
                  ),
                  ButtonSegment<ThemeMode>(
                    value: ThemeMode.light,
                    label: Text('Light'),
                    icon: Icon(LucideIcons.sun, size: 16),
                  ),
                  ButtonSegment<ThemeMode>(
                    value: ThemeMode.dark,
                    label: Text('Dark'),
                    icon: Icon(LucideIcons.moon, size: 16),
                  ),
                ],
                selected: {themeMode},
                onSelectionChanged: (Set<ThemeMode> newSelection) {
                  ref
                      .read(themeProvider.notifier)
                      .setThemeMode(newSelection.first);
                },
                showSelectedIcon: false,
                style: SegmentedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  selectedForegroundColor: AppTheme.primary,
                  selectedBackgroundColor: AppTheme.primary.withOpacity(0.08),
                  side: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Verification',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _VerificationStep(
              label: 'Email verified',
              done: user.verificationLevel >= 0,
            ),
            _VerificationStep(
              label: 'Phone verified',
              done: user.verificationLevel >= 1,
            ),
            _VerificationStep(
              label: 'NIC submitted',
              done: user.verificationLevel >= 2,
            ),
            _VerificationStep(
              label: 'Face verified',
              done: user.verificationLevel >= 3,
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () async {
                final refreshed = await context.push<bool>(
                  '/app/profile/verification',
                );
                if (refreshed == true && mounted) _load();
              },
              icon: const Icon(Icons.verified_user_outlined, size: 18),
              label: Text(
                user.verificationLevel >= 3
                    ? 'View verification'
                    : 'Complete verification',
              ),
            ),
            if (appMode == UserAppMode.owner) ...[
              const SizedBox(height: 24),
              const Text(
                'Host Tools',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: AppTheme.primary,
                  ),
                  title: const Text('Host Earnings & Payouts'),
                  subtitle: const Text(
                    'Withdraw funds, view history & balances',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    context.push('/app/profile/earnings');
                  },
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'My listings',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${_myListings.length} items',
                    style: const TextStyle(color: AppTheme.muted),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_myListings.isEmpty)
                const Text(
                  'No listings yet. Tap List tab to publish.',
                  style: TextStyle(color: AppTheme.muted),
                )
              else
                ..._myListings.map(
                  (l) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(l.title),
                      subtitle: Text(
                        '${l.category} · ${ListingsApi.formatPrice(l.pricePerDay)}/day',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Chip(
                            label: Text(
                              l.isPaused
                                  ? 'Paused'
                                  : (l.status == 'PendingApproval'
                                      ? 'Under Review'
                                      : (l.status == 'Rejected' ? 'Rejected' : 'Active')),
                              style: const TextStyle(fontSize: 11),
                            ),
                            backgroundColor: l.isPaused
                                ? Colors.orange.shade50
                                : (l.status == 'PendingApproval'
                                    ? Colors.blue.shade50
                                    : (l.status == 'Rejected' ? Colors.red.shade50 : Colors.green.shade50)),
                            side: BorderSide(
                              color: l.isPaused
                                  ? Colors.orange.shade200
                                  : (l.status == 'PendingApproval'
                                      ? Colors.blue.shade200
                                      : (l.status == 'Rejected' ? Colors.red.shade200 : Colors.green.shade200)),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.more_vert),
                            onPressed: () => _showListingActions(l),
                          ),
                        ],
                      ),
                      onTap: () => _showListingActions(l),
                    ),
                  ),
                ),
            ],
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
          Icon(
            done ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 20,
            color: done ? AppTheme.primary : AppTheme.muted,
          ),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: done ? null : AppTheme.muted)),
        ],
      ),
    );
  }
}
