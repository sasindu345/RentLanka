using System;
using System.Collections.Generic;

namespace RentLanka.Api.Models.DTOs;

public record ListingResponse(
    Guid Id,
    Guid OwnerId,
    string Title,
    string Description,
    string Category,
    decimal PricePerDay,
    decimal SecurityDeposit,
    string Rules,
    double Latitude,
    double Longitude,
    string District,
    List<string> Images,
    bool IsPaused,
    DateTime CreatedAt,
    DateTime? UpdatedAt);
