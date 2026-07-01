namespace RentLanka.Api.Models.Requests;

public record UpdateUserRequest(
    string? FirstName,
    string? LastName,
    string? PhoneNumber,
    string? Role);
