using System;

namespace RentLanka.Api.Models.Entities;

public class Payout
{
    public Guid Id { get; set; }
    public Guid OwnerId { get; set; }
    public decimal Amount { get; set; }
    public string BankName { get; set; } = string.Empty;
    public string AccountNumber { get; set; } = string.Empty;
    public string AccountName { get; set; } = string.Empty;
    public PayoutStatus Status { get; set; } = PayoutStatus.Pending;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAt { get; set; }

    public User Owner { get; set; } = null!;
}
