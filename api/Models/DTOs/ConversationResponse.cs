using System;

namespace RentLanka.Api.Models.DTOs;

public record ConversationResponse(
    Guid Id,
    Guid UserOneId,
    string UserOneName,
    Guid UserTwoId,
    string UserTwoName,
    Guid? ListingId,
    string? ListingTitle,
    string? ListingImage,
    DateTime LastMessageAt,
    string? LastMessageContent,
    DateTime CreatedAt);
