using System;
using System.Collections.Generic;

namespace RentLanka.Api.Models.DTOs;

public record ListingResponse(
    Guid Id,
    Guid OwnerId,
    OwnerSummary Owner,
    string Title,
    string Description,
    string Category,
    decimal PricePerDay,
    decimal SecurityDeposit,
    string Rules,
    double Latitude,
    double Longitude,
    string Address,
    string District,
    List<string> Images,
    bool IsPaused,
    string Status,
    DateTime CreatedAt,
    DateTime? UpdatedAt);
