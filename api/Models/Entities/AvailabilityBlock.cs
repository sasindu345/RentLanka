using System;

namespace RentLanka.Api.Models.Entities;

public class AvailabilityBlock
{
    public Guid Id { get; set; }
    public Guid ListingId { get; set; }
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public AvailabilityBlockType Type { get; set; }
    public Guid? BookingId { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public Listing Listing { get; set; } = null!;
    public Booking? Booking { get; set; }
}
