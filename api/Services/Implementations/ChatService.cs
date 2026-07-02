using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using RentLanka.Api.Data;
using RentLanka.Api.Models.DTOs;
using RentLanka.Api.Models.Entities;
using RentLanka.Api.Models.Requests;
using RentLanka.Api.Services.Interfaces;
using Microsoft.AspNetCore.SignalR;
using RentLanka.Api.Hubs;

namespace RentLanka.Api.Services.Implementations;

public class ChatService : IChatService
{
    private readonly AppDbContext _context;
    private readonly INotificationService _notificationService;
    private readonly IHubContext<ChatHub> _hubContext;

    public ChatService(AppDbContext context, INotificationService notificationService, IHubContext<ChatHub> hubContext)
    {
        _context = context;
        _notificationService = notificationService;
        _hubContext = hubContext;
    }

    public async Task<ConversationResponse> GetOrCreateConversationAsync(Guid userOneId, CreateConversationRequest request)
    {
        var listing = await _context.Listings
            .Include(l => l.Owner)
            .FirstOrDefaultAsync(l => l.Id == request.ListingId);

        if (listing == null)
        {
            throw new KeyNotFoundException("Listing context not found.");
        }

        var userTwoId = listing.OwnerId;

        if (userOneId == userTwoId)
        {
            throw new InvalidOperationException("You cannot start a conversation with yourself.");
        }

        Guid sortedUserOneId = userOneId;
        Guid sortedUserTwoId = userTwoId;
        if (userOneId.CompareTo(userTwoId) > 0)
        {
            sortedUserOneId = userTwoId;
            sortedUserTwoId = userOneId;
        }

        var conversation = await _context.Conversations
            .Include(c => c.UserOne)
            .Include(c => c.UserTwo)
            .Include(c => c.Listing)
            .FirstOrDefaultAsync(c => c.UserOneId == sortedUserOneId && c.UserTwoId == sortedUserTwoId && c.ListingId == request.ListingId);

        if (conversation == null)
        {
            conversation = new Conversation
            {
                Id = Guid.NewGuid(),
                UserOneId = sortedUserOneId,
                UserTwoId = sortedUserTwoId,
                ListingId = request.ListingId,
                LastMessageAt = DateTime.UtcNow,
                LastMessageContent = "Conversation started"
            };

            _context.Conversations.Add(conversation);
            await _context.SaveChangesAsync();

            conversation = await _context.Conversations
                .Include(c => c.UserOne)
                .Include(c => c.UserTwo)
                .Include(c => c.Listing)
                .FirstAsync(c => c.Id == conversation.Id);
        }

        return MapToResponse(conversation);
    }

    public async Task<List<ConversationResponse>> GetConversationsForUserAsync(Guid userId)
    {
        var list = await _context.Conversations
            .AsNoTracking()
            .Where(c => c.UserOneId == userId || c.UserTwoId == userId)
            .Include(c => c.UserOne)
            .Include(c => c.UserTwo)
            .Include(c => c.Listing)
            .OrderByDescending(c => c.LastMessageAt)
            .ToListAsync();

        return list.Select(MapToResponse).ToList();
    }

    public async Task<MessageResponse> SendMessageAsync(Guid conversationId, Guid senderId, SendMessageRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Content))
        {
            throw new ArgumentException("Message content cannot be empty.");
        }

        var conversation = await _context.Conversations
            .FirstOrDefaultAsync(c => c.Id == conversationId);

        if (conversation == null)
        {
            throw new KeyNotFoundException("Conversation not found.");
        }

        if (conversation.UserOneId != senderId && conversation.UserTwoId != senderId)
        {
            throw new UnauthorizedAccessException("You are not a participant in this conversation.");
        }

        var sender = await _context.Users.FindAsync(senderId);
        if (sender == null)
        {
            throw new KeyNotFoundException("Sender not found.");
        }

        var message = new Message
        {
            Id = Guid.NewGuid(),
            ConversationId = conversationId,
            SenderId = senderId,
            Content = request.Content.Trim(),
            IsRead = false,
            CreatedAt = DateTime.UtcNow
        };

        _context.Messages.Add(message);

        conversation.LastMessageAt = message.CreatedAt;
        conversation.LastMessageContent = message.Content.Length > 100 
            ? message.Content.Substring(0, 97) + "..." 
            : message.Content;

        await _context.SaveChangesAsync();

        var messageResponse = new MessageResponse(
            message.Id,
            message.ConversationId,
            message.SenderId,
            $"{sender.FirstName} {sender.LastName}",
            message.Content,
            message.IsRead,
            message.CreatedAt
        );

        // Broadcast real-time message via SignalR ChatHub
        _ = Task.Run(async () =>
        {
            try
            {
                await _hubContext.Clients.Group(conversationId.ToString())
                    .SendAsync("ReceiveMessage", messageResponse);
            }
            catch { }
        });

        // Notify recipient of new message
        var recipientId = conversation.UserOneId == senderId ? conversation.UserTwoId : conversation.UserOneId;
        _ = Task.Run(async () =>
        {
            try
            {
                await _notificationService.SendNotificationToUserAsync(
                    recipientId,
                    $"New Message from {sender.FirstName}",
                    message.Content,
                    new Dictionary<string, string>
                    {
                        { "conversationId", conversationId.ToString() },
                        { "senderId", senderId.ToString() },
                        { "type", "chat_message" }
                    });
            }
            catch { }
        });

        return messageResponse;
    }

    public async Task<List<MessageResponse>> GetMessagesAsync(Guid conversationId, Guid userId, DateTime? since = null)
    {
        var conversation = await _context.Conversations
            .AsNoTracking()
            .FirstOrDefaultAsync(c => c.Id == conversationId);

        if (conversation == null)
        {
            throw new KeyNotFoundException("Conversation not found.");
        }

        if (conversation.UserOneId != userId && conversation.UserTwoId != userId)
        {
            throw new UnauthorizedAccessException("You are not a participant in this conversation.");
        }

        var query = _context.Messages
            .Include(m => m.Sender)
            .Where(m => m.ConversationId == conversationId);

        if (since.HasValue)
        {
            query = query.Where(m => m.CreatedAt > since.Value);
        }

        var messages = await query
            .OrderBy(m => m.CreatedAt)
            .ToListAsync();

        var unread = messages.Where(m => m.SenderId != userId && !m.IsRead).ToList();
        if (unread.Any())
        {
            var unreadIds = unread.Select(m => m.Id).ToList();
            var dbUnread = await _context.Messages
                .Where(m => unreadIds.Contains(m.Id))
                .ToListAsync();

            foreach (var m in dbUnread)
            {
                m.IsRead = true;
            }
            await _context.SaveChangesAsync();
            
            foreach (var m in unread)
            {
                m.IsRead = true;
            }
        }

        return messages.Select(m => new MessageResponse(
            m.Id,
            m.ConversationId,
            m.SenderId,
            $"{m.Sender.FirstName} {m.Sender.LastName}",
            m.Content,
            m.IsRead,
            m.CreatedAt
        )).ToList();
    }

    private static ConversationResponse MapToResponse(Conversation c)
    {
        var listingImage = c.Listing?.Images != null && c.Listing.Images.Count > 0 
            ? c.Listing.Images[0] 
            : null;

        return new ConversationResponse(
            c.Id,
            c.UserOneId,
            $"{c.UserOne.FirstName} {c.UserOne.LastName}",
            c.UserTwoId,
            $"{c.UserTwo.FirstName} {c.UserTwo.LastName}",
            c.ListingId,
            c.Listing?.Title,
            listingImage,
            c.LastMessageAt,
            c.LastMessageContent,
            c.CreatedAt
        );
    }
}
