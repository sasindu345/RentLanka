using System;

namespace RentLanka.Api.Models.DTOs;

public record BookingResponse(
    Guid Id,
    Guid ListingId,
    string ListingTitle,
    string? ListingImage,
    Guid RenterId,
    string RenterName,
    Guid OwnerId,
    string OwnerName,
    DateTime StartDate,
    DateTime EndDate,
    decimal TotalPrice,
    decimal SecurityDeposit,
    string Status,
    bool RenterAgreementSigned,
    bool OwnerAgreementSigned,
    string? RenterNic,
    string? OwnerNic,
    DateTime CreatedAt,
    DateTime? UpdatedAt);
