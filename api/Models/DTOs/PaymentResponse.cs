using System;

namespace RentLanka.Api.Models.DTOs;

public record PaymentResponse(
    Guid Id,
    Guid BookingId,
    string ListingTitle,
    string RenterName,
    decimal Amount,
    string Status,
    string TransactionReference,
    DateTime CreatedAt);
