using System;
using System.Collections.Generic;

namespace RentLanka.Api.Models.Entities;

public class Conversation
{
    public Guid Id { get; set; }
    public Guid UserOneId { get; set; }
    public Guid UserTwoId { get; set; }
    public Guid? ListingId { get; set; }
    public DateTime LastMessageAt { get; set; } = DateTime.UtcNow;
    public string? LastMessageContent { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public User UserOne { get; set; } = null!;
    public User UserTwo { get; set; } = null!;
    public Listing? Listing { get; set; }
    public ICollection<Message> Messages { get; set; } = new List<Message>();
}
