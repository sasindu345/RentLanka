using System;

namespace RentLanka.Api.Models.Requests;

public record BookingRequest(
    Guid ListingId,
    DateTime StartDate,
    DateTime EndDate);
