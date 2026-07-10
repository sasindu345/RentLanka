import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/core/api/bookings_api.dart';
import 'package:mobile/shared/widgets/notification_bell_button.dart';

import 'package:mobile/core/api/listings_api.dart';
import 'package:mobile/core/constants.dart';
import 'package:mobile/core/models/listing.dart';
import 'package:mobile/core/theme/app_radius.dart';
import 'package:mobile/core/theme/app_shadows.dart';
import 'package:mobile/core/theme/app_spacing.dart';

class OwnerDashboardScreen extends ConsumerStatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  ConsumerState<OwnerDashboardScreen> createState() =>
      _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends ConsumerState<OwnerDashboardScreen> {
  UserProfile? _user;
  List<Listing> _listings = [];
  List<BookingResponse> _bookings = [];
  EarningsResponse? _earnings;
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
      final bookingsApi = ref.read(bookingsApiProvider);
      final user = await api.getCurrentUser();
      final listings = await api.getMyListings();
      List<BookingResponse> bookings = [];
      EarningsResponse? earnings;
      try {
        bookings = await bookingsApi.getOwnerBookings();
      } catch (_) {}
      try {
        earnings = await bookingsApi.getMyEarnings();
      } catch (_) {}
      if (mounted) {
        setState(() {
          _user = user;
          _listings = listings;
          _bookings = bookings;
          _earnings = earnings;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    // In dark mode use neutral white instead of blue for all accents
    final accentColor = isDark ? theme.colorScheme.onSurface : primary;

    final pendingBookings = _bookings.where((b) {
      final s = b.status.toLowerCase();
      return s == 'pendingreview' || s == 'pending_review' || s == 'pending';
    }).toList();
    final activeListings =
        _listings.where((l) => !l.isPaused && l.status == 'Approved').length;
    final pendingApprovalCount =
        _listings.where((l) => l.status == 'PendingApproval').length;

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.xs),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Host Dashboard',
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 28,
                          fontFamily: 'Plus Jakarta Sans',
                          color: theme.colorScheme.onBackground,
                        ),
                      ),
                      if (_user != null)
                        Text(
                          'Welcome back, ${_user!.firstName}',
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                  const NotificationBellButton(),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : CustomScrollView(
                        slivers: [

                    // ── Verification Banner ──────────────────────────
                    if (_user != null && _user!.verificationLevel < 3)
                      SliverToBoxAdapter(
                        child: _VerificationBanner(
                          level: _user!.verificationLevel,
                          onTap: () => context.push('/app/profile/verification'),
                          primary: accentColor,
                        ),
                      ),

                    // ── Stats Row ──────────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
                        child: Row(
                          children: [
                            _StatCard(
                              icon: LucideIcons.layoutList,
                              label: 'listings',
                              value: '$activeListings',
                              primary: accentColor,
                              isDark: isDark,
                            ),
                            const SizedBox(width: 10),
                            _StatCard(
                              icon: LucideIcons.clipboardList,
                              label: 'requests',
                              value: '${pendingBookings.length}',
                              primary: accentColor,
                              isDark: isDark,
                            ),
                            const SizedBox(width: 10),
                            _StatCard(
                              icon: LucideIcons.banknote,
                              label: 'earned',
                              value: _earnings != null
                                  ? ListingsApi.formatPrice(_earnings!.totalEarned)
                                  : 'LKR 0',
                              primary: accentColor,
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 28)),

                    // ── Booking Requests ───────────────────────────
                    SliverToBoxAdapter(
                      child: _SectionHeader(
                        title: 'Booking Requests',
                        count: pendingBookings.length,
                        actionLabel: pendingBookings.isNotEmpty ? 'View All' : null,
                        onAction: () => context.go('/app/activity'),
                        primary: accentColor,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: pendingBookings.isEmpty
                          ? _EmptyState(
                              icon: LucideIcons.calendarCheck,
                              message: 'No pending requests',
                              sub: 'New booking requests will appear here',
                              primary: accentColor,
                              isDark: isDark,
                            )
                          : Column(
                              children: pendingBookings
                                  .take(3)
                                  .map((b) => _BookingRequestTile(
                                        booking: b,
                                        primary: accentColor,
                                        isDark: isDark,
                                        onApprove: () async {
                                          await ref
                                              .read(bookingsApiProvider)
                                              .approveBooking(b.id);
                                          _load();
                                        },
                                        onReject: () async {
                                          await ref
                                              .read(bookingsApiProvider)
                                              .rejectBooking(b.id);
                                          _load();
                                        },
                                      ))
                                  .toList(),
                            ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 28)),

                    SliverToBoxAdapter(
                      child: _SectionHeader(
                        title: 'My Listings',
                        count: _listings.length,
                        actionLabel: 'See more',
                        onAction: () => context.go('/app/list?tab=my_listings'),
                        badge: pendingApprovalCount > 0
                            ? '$pendingApprovalCount under review'
                            : null,
                        primary: accentColor,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _listings.isEmpty
                          ? _EmptyState(
                              icon: LucideIcons.packageOpen,
                              message: 'No listings yet',
                              sub: 'Tap the List tab to publish your first item',
                              actionLabel: '+ Create Listing',
                              onAction: () => context.go('/app/list'),
                              primary: accentColor,
                              isDark: isDark,
                            )
                          : Column(
                              children: _listings
                                  .map((l) => _ListingRow(
                                        listing: l,
                                        primary: accentColor,
                                        isDark: isDark,
                                        onEdit: () async {
                                          final updated = await context.push<bool>(
                                              '/app/profile/listing/${l.id}/edit');
                                          if (updated == true && mounted) _load();
                                        },
                                      ))
                                  .toList(),
                            ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 28)),

                    // ── Earnings ────────────────────────────────────
                    SliverToBoxAdapter(
                      child: _SectionHeader(
                        title: 'Earnings',
                        actionLabel: 'View Details',
                        onAction: () => context.push('/app/profile/earnings'),
                        primary: accentColor,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _EarningsCard(
                        earnings: _earnings,
                        primary: primary,
                        isDark: isDark,
                        onTap: () => context.push('/app/profile/earnings'),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 28)),

                    // ── Quick Actions ───────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Quick Actions',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Plus Jakarta Sans',
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _QuickAction(
                                  icon: LucideIcons.plusCircle,
                                  label: 'New Listing',
                                  primary: accentColor,
                                  isDark: isDark,
                                  onTap: () => context.go('/app/list'),
                                ),
                                const SizedBox(width: 10),
                                _QuickAction(
                                  icon: LucideIcons.banknote,
                                  label: 'Earnings',
                                  primary: accentColor,
                                  isDark: isDark,
                                  onTap: () => context.push('/app/profile/earnings'),
                                ),
                                const SizedBox(width: 10),
                                _QuickAction(
                                  icon: LucideIcons.calendar,
                                  label: 'Activity',
                                  primary: accentColor,
                                  isDark: isDark,
                                  onTap: () => context.go('/app/activity'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
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



// ─── Section Header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final int? count;
  final String? actionLabel;
  final String? badge;
  final VoidCallback? onAction;
  final Color primary;

  const _SectionHeader({
    required this.title,
    this.count,
    this.actionLabel,
    this.badge,
    this.onAction,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
      child: Row(
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontFamily: 'Plus Jakarta Sans',
            ),
          ),
          if (count != null && count! > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: primary,
                ),
              ),
            ),
          ],
          if (badge != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                badge!,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: primary,
                ),
              ),
            ),
          ],
          const Spacer(),
          if (actionLabel != null && onAction != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                actionLabel!,
                style: TextStyle(
                  color: primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color primary;
  final bool isDark;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.primary,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.25)),
          boxShadow: isDark ? AppShadows.none : AppShadows.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 17, color: primary),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
                fontFamily: 'Plus Jakarta Sans',
              ),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String sub;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color primary;
  final bool isDark;

  const _EmptyState({
    required this.icon,
    required this.message,
    required this.sub,
    this.actionLabel,
    this.onAction,
    required this.primary,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.25)),
          boxShadow: isDark ? AppShadows.none : AppShadows.sm,
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5)),
            const SizedBox(height: 10),
            Text(
              message,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              sub,
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onAction,
                  child: Text(actionLabel!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Listing Row (vertical list item) ────────────────────────────────────────

class _ListingRow extends StatelessWidget {
  final Listing listing;
  final Color primary;
  final bool isDark;
  final VoidCallback onEdit;

  const _ListingRow({
    required this.listing,
    required this.primary,
    required this.isDark,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Status
    String statusLabel;
    Color statusBg;
    Color statusFg;
    if (listing.isPaused) {
      statusLabel = 'Paused';
      statusBg = theme.colorScheme.onSurfaceVariant.withOpacity(0.08);
      statusFg = theme.colorScheme.onSurfaceVariant;
    } else if (listing.status == 'PendingApproval') {
      statusLabel = 'Under Review';
      statusBg = primary.withOpacity(0.08);
      statusFg = primary;
    } else if (listing.status == 'Rejected') {
      statusLabel = 'Rejected';
      statusBg = theme.colorScheme.error.withOpacity(0.08);
      statusFg = theme.colorScheme.error;
    } else {
      statusLabel = 'Active';
      statusBg = primary.withOpacity(0.08);
      statusFg = primary;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.25)),
          boxShadow: isDark ? AppShadows.none : AppShadows.sm,
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: SizedBox(
                width: 80,
                height: 80,
                child: listing.images.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: resolveMediaUrl(listing.images.first),
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          color: theme.colorScheme.surfaceVariant,
                          child: Icon(LucideIcons.image,
                              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4)),
                        ),
                      )
                    : Container(
                        color: theme.colorScheme.surfaceVariant,
                        child: Icon(LucideIcons.image,
                            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4)),
                      ),
              ),
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${listing.category} · ${ListingsApi.formatPrice(listing.pricePerDay)}/day',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusFg,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Edit button
            IconButton(
              icon: Icon(LucideIcons.pencil,
                  size: 16, color: theme.colorScheme.onSurfaceVariant),
              onPressed: onEdit,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Booking Request Tile ─────────────────────────────────────────────────────

class _BookingRequestTile extends StatelessWidget {
  final BookingResponse booking;
  final Color primary;
  final bool isDark;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _BookingRequestTile({
    required this.booking,
    required this.primary,
    required this.isDark,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = booking.endDate.difference(booking.startDate).inDays;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.25)),
          boxShadow: isDark ? AppShadows.none : AppShadows.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: primary.withOpacity(0.08),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: booking.listingImage != null
                      ? CachedNetworkImage(
                          imageUrl: resolveMediaUrl(booking.listingImage!),
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Icon(LucideIcons.package,
                              size: 18, color: primary.withOpacity(0.6)),
                        )
                      : Icon(LucideIcons.package, size: 18,
                          color: primary.withOpacity(0.6)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.listingTitle,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'by ${booking.renterName}',
                        style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    'Pending',
                    style: TextStyle(
                        color: primary, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(LucideIcons.calendar,
                    size: 12, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  '${_fmtDate(booking.startDate)} – ${_fmtDate(booking.endDate)} · $days day${days != 1 ? 's' : ''}',
                  style: TextStyle(
                      fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                ),
                const Spacer(),
                Text(
                  ListingsApi.formatPrice(booking.totalPrice),
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13, color: primary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.onSurfaceVariant,
                      side: BorderSide(
                          color: theme.colorScheme.outline.withOpacity(0.4)),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text('Decline', style: TextStyle(fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: onApprove,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text('Approve', style: TextStyle(fontSize: 13)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) => '${d.day} ${_months[d.month - 1]}';

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
}

// ─── Earnings Card ────────────────────────────────────────────────────────────

class _EarningsCard extends StatelessWidget {
  final EarningsResponse? earnings;
  final Color primary;
  final bool isDark;
  final VoidCallback onTap;

  const _EarningsCard({
    required this.earnings,
    required this.primary,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Light: Soft professional highlighted background with branding color accents
    // Dark: Surface card matching the theme
    final cardBg = isDark ? theme.colorScheme.surface : theme.colorScheme.primary.withOpacity(0.06);
    final labelColor = ((theme.colorScheme.onSurfaceVariant as Color?) ?? theme.colorScheme.onSurface).withOpacity(0.8);
    final valueColor = theme.colorScheme.onSurface;
    final iconColor = theme.colorScheme.primary;
    final dividerColor = ((theme.colorScheme.outlineVariant as Color?) ?? theme.dividerColor).withOpacity(0.6);

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: isDark
                  ? ((theme.colorScheme.outline as Color?) ?? theme.dividerColor).withOpacity(0.25)
                  : theme.colorScheme.primary.withOpacity(0.2),
              width: isDark ? 1.0 : 1.2,
            ),
            boxShadow: isDark
                ? AppShadows.none
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.trendingUp, color: iconColor, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Your Earnings',
                    style: TextStyle(
                      color: iconColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  Icon(LucideIcons.chevronRight, color: iconColor, size: 16),
                ],
              ),
              const SizedBox(height: 16),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Earned',
                            style: TextStyle(color: labelColor, fontSize: 11),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            earnings != null
                                ? ListingsApi.formatPrice(earnings!.totalEarned)
                                : 'LKR 0',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Plus Jakarta Sans',
                              color: valueColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    VerticalDivider(
                      color: dividerColor,
                      thickness: 1,
                      width: 32,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Available',
                            style: TextStyle(color: labelColor, fontSize: 11),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            earnings != null
                                ? ListingsApi.formatPrice(earnings!.availableBalance)
                                : 'LKR 0',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Plus Jakarta Sans',
                              color: valueColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Quick Action ─────────────────────────────────────────────────────────────

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color primary;
  final bool isDark;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.primary,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: theme.colorScheme.outline.withOpacity(0.25)),
            boxShadow: isDark ? AppShadows.none : AppShadows.sm,
          ),
          child: Column(
            children: [
              Icon(icon, color: primary, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Verification Banner ──────────────────────────────────────────────────────

class _VerificationBanner extends StatelessWidget {
  final int level;
  final VoidCallback onTap;
  final Color primary;

  const _VerificationBanner({
    required this.level,
    required this.onTap,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nextStep = level < 2
        ? 'Complete NIC verification to publish listings'
        : 'Complete Face verification to unlock full hosting';

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: primary.withOpacity(0.06),
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: primary.withOpacity(0.20)),
          ),
          child: Row(
            children: [
              Icon(LucideIcons.info, color: primary, size: 16),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  nextStep,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(LucideIcons.chevronRight, color: primary, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}
