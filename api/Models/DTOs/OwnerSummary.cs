using System;

namespace RentLanka.Api.Models.DTOs;

public record OwnerSummary(
    Guid Id,
    string FirstName,
    string LastName,
    string? AvatarUrl,
    bool IsTrustedUser,
    int VerificationLevel);
