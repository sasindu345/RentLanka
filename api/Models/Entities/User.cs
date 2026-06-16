using System;
using System.Collections.Generic;

namespace RentLanka.Api.Models.Entities;

public class User
{
    public Guid Id { get; set; }
    public string Email { get; set; } = string.Empty;
    public string PasswordHash { get; set; } = string.Empty;
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string PhoneNumber { get; set; } = string.Empty;
    public VerificationLevel VerificationLevel { get; set; } = VerificationLevel.Unverified;
    public bool IsTrustedUser { get; set; } = false;
    public string? NICNumber { get; set; }
    public string? NicDocumentUrl { get; set; }
    public string? AvatarUrl { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAt { get; set; }

    public ICollection<Listing> Listings { get; set; } = new List<Listing>();
    public ICollection<WishlistItem> WishlistItems { get; set; } = new List<WishlistItem>();
}
