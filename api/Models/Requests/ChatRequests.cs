using System;

namespace RentLanka.Api.Models.Requests;

public record CreateConversationRequest(Guid ListingId);

public record SendMessageRequest(string Content);
