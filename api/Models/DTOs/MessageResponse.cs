using System;

namespace RentLanka.Api.Models.DTOs;

public record MessageResponse(
    Guid Id,
    Guid ConversationId,
    Guid SenderId,
    string SenderName,
    string Content,
    bool IsRead,
    DateTime CreatedAt);
