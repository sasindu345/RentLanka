import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/api/api_client.dart';
import 'package:mobile/features/profile/screens/notifications_screen.dart';

import 'package:mobile/core/api/listings_api.dart';
import 'package:mobile/core/constants.dart';
import 'package:mobile/core/models/listing.dart';
import 'package:mobile/core/theme/app_spacing.dart';
import 'package:mobile/core/theme/app_radius.dart';
import 'package:mobile/core/theme/app_shadows.dart';
import 'package:mobile/core/providers/app_mode_provider.dart';
import 'package:mobile/core/providers/theme_provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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

  void _showHelpCenterSheet(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Help Center & FAQs',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Plus Jakarta Sans',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Frequently Asked Questions & Support',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
              ),
              const Divider(height: 24),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildFaqTile(
                      theme,
                      'How do I rent an item?',
                      'Simply browse the Explore feed, click on an item you like, verify the specifications, and tap "Request Rental". Select your rental dates and complete the process.',
                    ),
                    _buildFaqTile(
                      theme,
                      'What is the security deposit?',
                      'Some owners require a security deposit before handing over high-value gear. The deposit is fully refunded once the item is returned in its original condition.',
                    ),
                    _buildFaqTile(
                      theme,
                      'How do I list my own items?',
                      'Go to the bottom navigation bar and switch to "Owner Mode". Tap the "List" tab to upload images, set a price per day, and publish your item.',
                    ),
                    _buildFaqTile(
                      theme,
                      'How does verification work?',
                      'To protect the community, we require email, phone, NIC, and face recognition verification. You can complete this under Account Settings > Identity Verification.',
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.primary.withOpacity(0.15),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Still need help?',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Our support team is available 24/7.',
                            style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Support email: support@rentlanka.lk')),
                                  );
                                },
                                icon: const Icon(Icons.email_outlined, size: 16),
                                label: const Text('Email Us'),
                              ),
                              OutlinedButton.icon(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Hotline: +94 11 234 5678')),
                                  );
                                },
                                icon: const Icon(Icons.phone_outlined, size: 16),
                                label: const Text('Call Us'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFaqTile(ThemeData theme, String question, String answer) {
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          answer,
          style: TextStyle(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.4,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  void _showAboutDialog(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(LucideIcons.info, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            const Text(
              'About RentLanka',
              style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'RentLanka is Sri Lanka\'s premier peer-to-peer equipment and gear rental marketplace. Rent cameras, tools, camping gear, and more safely and easily.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 16),
            Text(
              'Version 1.0.0 (Build 102)',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
            ),
            const Divider(height: 24),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Terms of Service', style: TextStyle(fontSize: 13)),
              trailing: const Icon(Icons.open_in_new, size: 16),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Opening Terms of Service...')),
                );
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Privacy Policy', style: TextStyle(fontSize: 13)),
              trailing: const Icon(Icons.open_in_new, size: 16),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Opening Privacy Policy...')),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
    final currentThemeMode = ref.watch(themeProvider);

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
                    'Profile',
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
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.only(
                    left: AppSpacing.md,
                    right: AppSpacing.md,
                    bottom: AppSpacing.md,
                  ),
                  children: [
              SizedBox(height: AppSpacing.lg),

              // 2. Profile Details Row
              Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: theme.colorScheme.primary,
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
                          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                        ),
                        if (user.phoneNumber.isNotEmpty)
                          Text(
                            user.phoneNumber,
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 13,
                            ),
                          ),
                        if (user.isTrustedUser)
                          Text(
                            'Trusted member',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.edit3),
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
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.4),
                  width: 1.0,
                ),
                boxShadow: theme.brightness == Brightness.dark ? AppShadows.none : AppShadows.sm,
              ),
              child: SwitchListTile(
                title: const Text('Switch to Owner Mode'),
                subtitle: Text(
                  appMode == UserAppMode.owner
                      ? 'Showing hosting tools & listings'
                      : 'Showing renter explore & wishlist',
                ),
                value: appMode == UserAppMode.owner,
                activeColor: theme.colorScheme.primary,
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
                    // Navigate to owner dashboard when switching to owner mode
                    if (newMode == UserAppMode.owner && mounted) {
                      context.go('/app/owner');
                    }
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
              'Account Settings',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.4),
                  width: 1.0,
                ),
                boxShadow: theme.brightness == Brightness.dark ? AppShadows.none : AppShadows.sm,
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      LucideIcons.user,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    title: const Text('Personal Information'),
                    subtitle: const Text('Update name, email, and phone'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final updated = await context.push<bool>('/app/profile/edit');
                      if (updated == true && mounted) _load();
                    },
                  ),
                  Divider(
                    height: 1,
                    color: theme.colorScheme.outline.withOpacity(0.2),
                    indent: 56,
                  ),
                  ListTile(
                    leading: Icon(
                      LucideIcons.shieldCheck,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    title: const Text('Identity Verification'),
                    subtitle: Text(
                      user.verificationLevel >= 3
                          ? 'Fully Verified (Face)'
                          : (user.verificationLevel >= 2
                              ? 'NIC Submitted'
                              : 'Basic (Email Only)'),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (user.verificationLevel >= 3)
                          Icon(Icons.verified, color: theme.colorScheme.primary, size: 20)
                        else
                          const Icon(Icons.chevron_right),
                      ],
                    ),
                    onTap: () async {
                      final refreshed = await context.push<bool>('/app/profile/verification');
                      if (refreshed == true && mounted) _load();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Theme Preference',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
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
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: _ThemeOptionTile(
                        label: 'Light',
                        icon: LucideIcons.sun,
                        isActive: currentThemeMode == ThemeMode.light,
                        onTap: () => ref.read(themeProvider.notifier).setThemeMode(ThemeMode.light),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ThemeOptionTile(
                        label: 'Dark',
                        icon: LucideIcons.moon,
                        isActive: currentThemeMode == ThemeMode.dark,
                        onTap: () => ref.read(themeProvider.notifier).setThemeMode(ThemeMode.dark),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ThemeOptionTile(
                        label: 'System',
                        icon: LucideIcons.smartphone,
                        isActive: currentThemeMode == ThemeMode.system,
                        onTap: () => ref.read(themeProvider.notifier).setThemeMode(ThemeMode.system),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Support & Information',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.4),
                  width: 1.0,
                ),
                boxShadow: theme.brightness == Brightness.dark ? AppShadows.none : AppShadows.sm,
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      LucideIcons.helpCircle,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    title: const Text('Help Center & FAQs'),
                    subtitle: const Text('Guides on renting, listings, & deposits'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showHelpCenterSheet(context),
                  ),
                  Divider(
                    height: 1,
                    color: theme.colorScheme.outline.withOpacity(0.2),
                    indent: 56,
                  ),
                  ListTile(
                    leading: Icon(
                      LucideIcons.info,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    title: const Text('About RentLanka'),
                    subtitle: const Text('Version, Terms & Privacy Policy'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showAboutDialog(context),
                  ),
                ],
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
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.4),
                    width: 1.0,
                  ),
                  boxShadow: theme.brightness == Brightness.dark ? AppShadows.none : AppShadows.sm,
                ),
                child: ListTile(
                  leading: Icon(
                    Icons.account_balance_wallet_outlined,
                    color: theme.colorScheme.primary,
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
            ],
            const SizedBox(height: 16),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: _logout,
                icon: Icon(
                  LucideIcons.logOut,
                  color: theme.colorScheme.error,
                  size: 18,
                ),
                label: Text(
                  'Log Out',
                  style: TextStyle(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: theme.colorScheme.error.withOpacity(0.4),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.card),
                  ),
                  backgroundColor: theme.colorScheme.error.withOpacity(0.04),
                ),
              ),
            ),
            const SizedBox(height: 24),
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

class _VerificationStep extends StatelessWidget {
  final String label;
  final bool done;

  const _VerificationStep({required this.label, required this.done});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            done ? LucideIcons.checkCircle2 : LucideIcons.circle,
            size: 20,
            color: done ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: done ? theme.colorScheme.onBackground : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeOptionTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _ThemeOptionTile({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isActive 
              ? theme.colorScheme.primary.withOpacity(0.08) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive 
                ? theme.colorScheme.primary.withOpacity(0.3) 
                : theme.colorScheme.outline.withOpacity(0.15),
            width: isActive ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive 
                  ? theme.colorScheme.primary 
                  : theme.colorScheme.onSurfaceVariant,
              size: 20,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive 
                    ? theme.colorScheme.primary 
                    : theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
