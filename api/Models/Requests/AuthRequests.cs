namespace RentLanka.Api.Models.Requests;

public record RegisterRequest(
    string Email, 
    string Password, 
    string FirstName, 
    string LastName, 
    string PhoneNumber,
    string Role);

public record LoginRequest(
    string Email, 
    string Password);

public record RefreshRequest(
    string Token,
    string RefreshToken);
