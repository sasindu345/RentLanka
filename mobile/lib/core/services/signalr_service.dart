import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:mobile/core/constants.dart';
import 'package:mobile/core/api/api_client.dart';
import 'package:mobile/core/providers/notification_provider.dart';

final signalRServiceProvider = Provider<SignalRService>((ref) {
  final service = SignalRService(ref);
  ref.onDispose(() {
    service.disconnect();
  });
  return service;
});

class SignalRService {
  final Ref _ref;
  HubConnection? _hubConnection;
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  String? _activeConversationId;

  SignalRService(this._ref);

  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  Future<void> connect() async {
    if (_hubConnection != null && _hubConnection!.state == HubConnectionState.Connected) {
      return;
    }

    try {
      final storage = _ref.read(tokenStorageProvider);
      final token = await storage.getToken();
      if (token == null || token.isEmpty) {
        developer.log("SignalR: Cannot connect because token is missing or empty.");
        return;
      }

      final url = apiBaseUrl.endsWith('/')
          ? '${apiBaseUrl}hubs/chat'
          : '$apiBaseUrl/hubs/chat';

      _hubConnection = HubConnectionBuilder()
          .withUrl(
            url,
            options: HttpConnectionOptions(
              accessTokenFactory: () async => token,
            ),
          )
          .build();

      _hubConnection!.onclose(({error}) {
        developer.log("SignalR: Connection closed. $error");
      });

      _hubConnection!.on("ReceiveMessage", _onReceiveMessage);

      await _hubConnection!.start();
      developer.log("SignalR: Connection started successfully.");
    } catch (e) {
      developer.log("SignalR: Failed to connect", error: e);
    }
  }

  void _onReceiveMessage(List<dynamic>? arguments) {
    if (arguments != null && arguments.isNotEmpty) {
      try {
        final message = arguments.first as Map<String, dynamic>;
        _messageController.add(message);

        // Notify client user if they are currently elsewhere in the app
        final conversationId = message['conversationId'] as String;
        if (conversationId != _activeConversationId) {
          final senderName = message['senderName'] as String;
          final content = message['content'] as String;
          unawaited(
            _ref.read(notificationListProvider.notifier).addNotification(
              'New Message from $senderName',
              content,
            ),
          );
        }
      } catch (e) {
        developer.log("SignalR: Error parsing received message arguments", error: e);
      }
    }
  }

  Future<void> joinConversation(String conversationId) async {
    _activeConversationId = conversationId;
    await connect();
    if (_hubConnection != null && _hubConnection!.state == HubConnectionState.Connected) {
      try {
        await _hubConnection!.invoke("JoinConversation", args: [conversationId]);
        developer.log("SignalR: Joined conversation group: $conversationId");
      } catch (e) {
        developer.log("SignalR: Failed to join conversation group", error: e);
      }
    }
  }

  Future<void> leaveConversation(String conversationId) async {
    if (_activeConversationId == conversationId) {
      _activeConversationId = null;
    }
    if (_hubConnection != null && _hubConnection!.state == HubConnectionState.Connected) {
      try {
        await _hubConnection!.invoke("LeaveConversation", args: [conversationId]);
        developer.log("SignalR: Left conversation group: $conversationId");
      } catch (e) {
        developer.log("SignalR: Failed to leave conversation group", error: e);
      }
    }
  }

  Future<void> disconnect() async {
    if (_hubConnection != null) {
      await _hubConnection!.stop();
      _hubConnection = null;
      developer.log("SignalR: Disconnected.");
    }
  }
}
