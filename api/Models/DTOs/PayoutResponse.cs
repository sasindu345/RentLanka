using System;

namespace RentLanka.Api.Models.DTOs;

public record PayoutResponse(
    Guid Id,
    Guid OwnerId,
    string OwnerName,
    decimal Amount,
    string BankName,
    string AccountNumber,
    string AccountName,
    string Status,
    DateTime CreatedAt,
    DateTime? UpdatedAt);
