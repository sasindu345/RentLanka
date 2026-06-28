using System;

namespace RentLanka.Api.Models.Entities;

public class Dispute
{
    public Guid Id { get; set; }
    
    public Guid BookingId { get; set; }
    public Booking Booking { get; set; } = null!;
    
    public Guid CreatedById { get; set; }
    public User CreatedBy { get; set; } = null!;
    
    public string Reason { get; set; } = string.Empty;
    public bool IsResolved { get; set; }
    public string? AdminDecision { get; set; }
    
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? ResolvedAt { get; set; }
    
    public Guid? ResolvedById { get; set; }
    public User? ResolvedBy { get; set; }
}
