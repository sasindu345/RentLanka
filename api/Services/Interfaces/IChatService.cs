using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using RentLanka.Api.Models.DTOs;
using RentLanka.Api.Models.Requests;

namespace RentLanka.Api.Services.Interfaces;

public interface IChatService
{
    Task<ConversationResponse> GetOrCreateConversationAsync(Guid userOneId, CreateConversationRequest request);
    Task<List<ConversationResponse>> GetConversationsForUserAsync(Guid userId);
    Task<MessageResponse> SendMessageAsync(Guid conversationId, Guid senderId, SendMessageRequest request);
    Task<List<MessageResponse>> GetMessagesAsync(Guid conversationId, Guid userId, DateTime? since = null);
}
