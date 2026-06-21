using System;

namespace RentLanka.Api.Models.DTOs;

public record AvailabilityBlockResponse(
    Guid Id,
    Guid ListingId,
    DateTime StartDate,
    DateTime EndDate,
    string Type,
    Guid? BookingId);
