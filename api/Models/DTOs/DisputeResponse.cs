using System;

namespace RentLanka.Api.Models.DTOs;

public record DisputeResponse(
    Guid Id,
    Guid BookingId,
    string ListingTitle,
    Guid CreatedById,
    string CreatedByName,
    string Reason,
    bool IsResolved,
    string? AdminDecision,
    DateTime CreatedAt,
    DateTime? ResolvedAt,
    string? ResolvedByName);
