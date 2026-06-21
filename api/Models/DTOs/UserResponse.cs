using System;

namespace RentLanka.Api.Models.DTOs;

public record UserResponse(
    Guid Id,
    string Email,
    string FirstName,
    string LastName,
    string PhoneNumber,
    int VerificationLevel,
    bool IsTrustedUser,
    string? AvatarUrl,
    DateTime CreatedAt,
    string Role,
    bool IsBanned,
    string? NicNumber,
    string? NicDocumentUrl);
