using System;

namespace RentLanka.Api.Models.Entities;

public class Review
{
    public Guid Id { get; set; }
    public Guid BookingId { get; set; }
    public Guid ReviewerId { get; set; }
    public Guid TargetUserId { get; set; }
    public int Rating { get; set; }
    public string Comment { get; set; } = string.Empty;
    public bool IsRenterReview { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public Booking Booking { get; set; } = null!;
    public User Reviewer { get; set; } = null!;
    public User TargetUser { get; set; } = null!;
}
