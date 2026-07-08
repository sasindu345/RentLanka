using System;
using System.Threading.Tasks;

namespace RentLanka.Api.Services.Interfaces;

public interface IIdentityService
{
    Task<(bool Succeeded, Guid UserId, string? Error)> CreateUserAsync(
        string email, 
        string password, 
        string firstName, 
        string lastName, 
        string phoneNumber,
        string role);

    Task<(bool Succeeded, string? Token, string? RefreshToken, string? Error)> LoginAsync(
        string email, 
        string password);

    Task<(bool Succeeded, string? Token, string? RefreshToken, string? Error)> RefreshTokenAsync(
        string expiredToken, 
        string refreshToken);

    Task<(bool Succeeded, string? Token, string? RefreshToken, string? Role, string? Error)> SocialLoginOrRegisterAsync(
        string? idToken,
        string? fallbackEmail,
        string? fallbackFirstName,
        string? fallbackLastName,
        string? role);
}
