import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_theme.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Activity'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Bookings'),
              Tab(text: 'Messages'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _PlaceholderTab(
              icon: Icons.calendar_month_outlined,
              title: 'No bookings yet',
              subtitle: 'Booking management arrives in Phase 4',
            ),
            _PlaceholderTab(
              icon: Icons.chat_bubble_outline,
              title: 'No messages yet',
              subtitle: 'In-app chat arrives in Phase 5',
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _PlaceholderTab({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: AppTheme.muted),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.muted)),
          ],
        ),
      ),
    );
  }
}
