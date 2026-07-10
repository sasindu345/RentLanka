import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/api/listings_api.dart';
import 'package:mobile/core/api/chats_api.dart';
import 'package:mobile/core/providers/app_mode_provider.dart';
import 'package:mobile/shared/widgets/listing_image.dart';
import 'package:mobile/core/theme/app_spacing.dart';
import 'package:mobile/core/theme/app_radius.dart';
import 'package:mobile/shared/widgets/empty_state.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/shared/widgets/notification_bell_button.dart';

class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  List<ConversationResponse> _chats = [];
  bool _loading = true;
  String _currentUserId = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final listingsApi = ref.read(listingsApiProvider);
      final chatsApi = ref.read(chatsApiProvider);

      final user = await listingsApi.getCurrentUser();
      final chats = await chatsApi.getConversations();

      setState(() {
        _currentUserId = user.id;
        _chats = chats;
      });
    } catch (_) {
      // Ignore load errors
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _getChatPartnerName(ConversationResponse chat) {
    if (chat.userOneId == _currentUserId) {
      return chat.userTwoName;
    }
    return chat.userOneName;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appMode = ref.watch(appModeProvider);
    final isOwner = appMode == UserAppMode.owner;

    if (_loading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Messages'),
          actions: const [
            NotificationBellButton(),
            SizedBox(width: AppSpacing.md),
          ],
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_chats.isEmpty) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Messages'),
          actions: const [
            NotificationBellButton(),
            SizedBox(width: AppSpacing.md),
          ],
        ),
        body: EmptyState(
          icon: LucideIcons.messageSquare,
          title: 'No messages yet',
          subtitle: isOwner
              ? 'Your host messages will appear here when guests contact you.'
              : 'Start a conversation by clicking "Message Host" on any equipment listing.',
          actionLabel: isOwner ? null : 'Explore equipment',
          onActionPressed: isOwner ? null : () => context.go('/app/explore'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Messages'),
        actions: const [
          NotificationBellButton(),
          SizedBox(width: AppSpacing.md),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          itemCount: _chats.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final chat = _chats[index];
            final partnerName = _getChatPartnerName(chat);
            final timeStr = '${chat.lastMessageAt.hour.toString().padLeft(2, '0')}:${chat.lastMessageAt.minute.toString().padLeft(2, '0')}';

            return ListTile(
              onTap: () => context.push('/app/messages/thread/${chat.id}').then((_) => _load()),
              leading: CircleAvatar(
                radius: 20,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.08),
                child: Text(
                  partnerName.isNotEmpty ? partnerName[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    partnerName,
                    style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    timeStr,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  chat.lastMessageContent,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              trailing: chat.listingImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: ListingImage(url: chat.listingImage, width: 48),
                      ),
                    )
                  : null,
            );
          },
        ),
      ),
    );
  }
}
