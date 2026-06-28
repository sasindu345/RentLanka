using System;

namespace RentLanka.Api.Models.Entities;

public class Booking
{
    public Guid Id { get; set; }
    public Guid ListingId { get; set; }
    public Guid RenterId { get; set; }
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public decimal TotalPrice { get; set; }
    public decimal SecurityDeposit { get; set; }
    public BookingStatus Status { get; set; } = BookingStatus.Pending;
    public bool RenterAgreementSigned { get; set; } = false;
    public bool OwnerAgreementSigned { get; set; } = false;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAt { get; set; }

    public Listing Listing { get; set; } = null!;
    public User Renter { get; set; } = null!;
}
