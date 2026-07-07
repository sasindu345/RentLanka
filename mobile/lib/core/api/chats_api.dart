import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/api/api_client.dart';
import 'package:mobile/core/services/encryption_service.dart';

final chatsApiProvider = Provider((ref) {
  return ChatsApi(ref.watch(dioProvider));
});

class ConversationResponse {
  final String id;
  final String userOneId;
  final String userOneName;
  final String userTwoId;
  final String userTwoName;
  final String? listingId;
  final String? listingTitle;
  final String? listingImage;
  final DateTime lastMessageAt;
  final String lastMessageContent;
  final DateTime createdAt;

  ConversationResponse({
    required this.id,
    required this.userOneId,
    required this.userOneName,
    required this.userTwoId,
    required this.userTwoName,
    this.listingId,
    this.listingTitle,
    this.listingImage,
    required this.lastMessageAt,
    required this.lastMessageContent,
    required this.createdAt,
  });

  factory ConversationResponse.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    final lastMsg = json['lastMessageContent'] as String? ?? '';
    final decryptedLastMsg = EncryptionService.decryptMessage(lastMsg, id);

    return ConversationResponse(
      id: id,
      userOneId: json['userOneId'] as String,
      userOneName: json['userOneName'] as String,
      userTwoId: json['userTwoId'] as String,
      userTwoName: json['userTwoName'] as String,
      listingId: json['listingId'] as String?,
      listingTitle: json['listingTitle'] as String?,
      listingImage: json['listingImage'] as String?,
      lastMessageAt: DateTime.parse(json['lastMessageAt'] as String),
      lastMessageContent: decryptedLastMsg,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class MessageResponse {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String content;
  final bool isRead;
  final DateTime createdAt;

  MessageResponse({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.isRead,
    required this.createdAt,
  });

  factory MessageResponse.fromJson(Map<String, dynamic> json) {
    final conversationId = json['conversationId'] as String;
    final encryptedContent = json['content'] as String;
    final decryptedContent = EncryptionService.decryptMessage(encryptedContent, conversationId);

    return MessageResponse(
      id: json['id'] as String,
      conversationId: conversationId,
      senderId: json['senderId'] as String,
      senderName: json['senderName'] as String,
      content: decryptedContent,
      isRead: json['isRead'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class ChatsApi {
  final Dio _dio;

  ChatsApi(this._dio);

  Future<ConversationResponse> getOrCreateConversation(String listingId) async {
    final response = await _dio.post('/api/chats', data: {
      'listingId': listingId,
    });
    return ConversationResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<ConversationResponse>> getConversations() async {
    final response = await _dio.get('/api/chats');
    return (response.data as List<dynamic>)
        .map((e) => ConversationResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<MessageResponse> sendMessage(String conversationId, String content) async {
    final encryptedContent = EncryptionService.encryptMessage(content, conversationId);
    final response = await _dio.post('/api/chats/$conversationId/messages', data: {
      'content': encryptedContent,
    });
    return MessageResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<MessageResponse>> getMessages(String conversationId, {DateTime? since}) async {
    final Map<String, dynamic> queryParameters = {};
    if (since != null) {
      queryParameters['since'] = since.toUtc().toIso8601String();
    }
    
    final response = await _dio.get(
      '/api/chats/$conversationId/messages',
      queryParameters: queryParameters,
    );
    return (response.data as List<dynamic>)
        .map((e) => MessageResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
