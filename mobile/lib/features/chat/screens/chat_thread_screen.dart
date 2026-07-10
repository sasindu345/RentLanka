import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/api/listings_api.dart';
import 'package:mobile/core/api/chats_api.dart';
import 'package:mobile/shared/widgets/listing_image.dart';
import 'package:mobile/core/theme/app_spacing.dart';
import 'package:mobile/core/theme/app_radius.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:mobile/core/services/signalr_service.dart';

class ChatThreadScreen extends ConsumerStatefulWidget {
  final String conversationId;

  const ChatThreadScreen({super.key, required this.conversationId});

  @override
  ConsumerState<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends ConsumerState<ChatThreadScreen> {
  ConversationResponse? _conversation;
  List<MessageResponse> _messages = [];
  bool _loading = true;
  bool _sending = false;
  String _currentUserId = '';
  StreamSubscription? _signalRSubscription;
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  @override
  void dispose() {
    _signalRSubscription?.cancel();
    ref.read(signalRServiceProvider).leaveConversation(widget.conversationId);
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    try {
      final listingsApi = ref.read(listingsApiProvider);
      final chatsApi = ref.read(chatsApiProvider);

      final user = await listingsApi.getCurrentUser();
      final conversations = await chatsApi.getConversations();
      final conv = conversations.firstWhere((c) => c.id == widget.conversationId);
      
      final messages = await chatsApi.getMessages(widget.conversationId);

      setState(() {
        _currentUserId = user.id;
        _conversation = conv;
        _messages = messages;
        _loading = false;
      });

      _scrollToBottom();

      // Listen to real-time incoming messages via SignalR
      _signalRSubscription = ref.read(signalRServiceProvider).messageStream.listen((msgMap) {
        if (!mounted) return;
        if (msgMap['conversationId'] == widget.conversationId) {
          final msg = MessageResponse.fromJson(msgMap);
          if (!_messages.any((m) => m.id == msg.id)) {
            setState(() {
              _messages.add(msg);
            });
            _scrollToBottom();
          }
        }
      });

      // Establish websocket connection and join conversation group
      await ref.read(signalRServiceProvider).joinConversation(widget.conversationId);
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSend() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    _inputController.clear();
    setState(() => _sending = true);

    try {
      final chatsApi = ref.read(chatsApiProvider);
      final msg = await chatsApi.sendMessage(widget.conversationId, text);
      
      setState(() {
        if (!_messages.any((m) => m.id == msg.id)) {
          _messages.add(msg);
        }
      });
      
      _scrollToBottom();
    } catch (_) {
      // Restore input text on failure
      _inputController.text = text;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send message'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String _getChatPartnerName() {
    final conv = _conversation;
    if (conv == null) return 'Chat';
    if (conv.userOneId == _currentUserId) {
      return conv.userTwoName;
    }
    return conv.userOneName;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final conv = _conversation;
    if (conv == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const Center(child: Text('Conversation not found')),
      );
    }

    final partnerName = _getChatPartnerName();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(partnerName, style: const TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: Column(
        children: [
          // Listing Context Header (Airbnb style)
          if (conv.listingId != null)
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(bottom: BorderSide(color: theme.dividerColor)),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                    child: SizedBox(
                      width: 50,
                      height: 50,
                      child: ListingImage(url: conv.listingImage, width: 50),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          conv.listingTitle ?? 'Rental Item',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Context: Equipment Rental discussion',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Messages List View
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isMe = msg.senderId == _currentUserId;
                final timeStr = '${msg.createdAt.hour.toString().padLeft(2, '0')}:${msg.createdAt.minute.toString().padLeft(2, '0')}';

                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    child: Column(
                      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
                          decoration: BoxDecoration(
                            color: isMe ? theme.colorScheme.primary : theme.colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(AppRadius.input),
                              topRight: const Radius.circular(AppRadius.input),
                              bottomLeft: isMe ? const Radius.circular(AppRadius.input) : Radius.zero,
                              bottomRight: isMe ? Radius.zero : const Radius.circular(AppRadius.input),
                            ),
                            border: isMe ? null : Border.all(color: theme.colorScheme.outline.withOpacity(0.4)),
                          ),
                          child: Text(
                            msg.content,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isMe ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
                              height: 1.4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          timeStr,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom Input Row
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(top: BorderSide(color: theme.dividerColor)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6)),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: theme.colorScheme.outline),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: theme.colorScheme.primary),
                        ),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _handleSend(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  IconButton(
                    onPressed: _sending ? null : _handleSend,
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(LucideIcons.send),
                    style: IconButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
