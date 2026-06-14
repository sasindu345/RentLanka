namespace RentLanka.Api.Models.Requests;

public record RegisterRequest(
    string Email, 
    string Password, 
    string FirstName, 
    string LastName, 
    string PhoneNumber);

public record LoginRequest(
    string Email, 
    string Password);
