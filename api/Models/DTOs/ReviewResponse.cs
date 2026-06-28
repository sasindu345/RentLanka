using System;

namespace RentLanka.Api.Models.DTOs;

public record ReviewResponse(
    Guid Id,
    Guid BookingId,
    Guid ReviewerId,
    string ReviewerName,
    Guid TargetUserId,
    int Rating,
    string Comment,
    bool IsRenterReview,
    DateTime CreatedAt);
