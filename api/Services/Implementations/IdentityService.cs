using System;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;
using RentLanka.Api.Data;
using RentLanka.Api.Models.Entities;
using RentLanka.Api.Services.Interfaces;
using BC = BCrypt.Net.BCrypt;

namespace RentLanka.Api.Services.Implementations;

public class IdentityService : IIdentityService
{
    private readonly AppDbContext _context;
    private readonly IConfiguration _configuration;

    public IdentityService(AppDbContext context, IConfiguration configuration)
    {
        _context = context;
        _configuration = configuration;
    }

    public async Task<(bool Succeeded, Guid UserId, string? Error)> CreateUserAsync(
        string email, 
        string password, 
        string firstName, 
        string lastName, 
        string phoneNumber,
        string role)
    {
        if (role != "Renter" && role != "Owner")
        {
            return (false, Guid.Empty, "Invalid role. You must register as either Renter or Owner.");
        }

        var existingUser = await _context.Users.AnyAsync(u => u.Email == email);
        if (existingUser)
        {
            return (false, Guid.Empty, "A user with this email already exists.");
        }

        var passwordHash = BC.HashPassword(password);

        var user = new User
        {
            Id = Guid.NewGuid(),
            Email = email,
            PasswordHash = passwordHash,
            FirstName = firstName,
            LastName = lastName,
            PhoneNumber = phoneNumber,
            Role = role,
            VerificationLevel = VerificationLevel.Unverified,
            CreatedAt = DateTime.UtcNow
        };

        _context.Users.Add(user);
        await _context.SaveChangesAsync();

        return (true, user.Id, null);
    }

    public async Task<(bool Succeeded, string? Token, string? RefreshToken, string? Error)> LoginAsync(string email, string password)
    {
        var user = await _context.Users.FirstOrDefaultAsync(u => u.Email == email);
        if (user == null || !BC.Verify(password, user.PasswordHash))
        {
            return (false, null, null, "Invalid email or password.");
        }

        if (user.IsBanned)
        {
            return (false, null, null, "Your account has been banned.");
        }

        var token = GenerateJwtToken(user);
        var refreshToken = GenerateRandomTokenString();
        
        user.RefreshTokenHash = HashToken(refreshToken);
        user.RefreshTokenExpiry = DateTime.UtcNow.AddDays(30);
        
        await _context.SaveChangesAsync();

        return (true, token, refreshToken, null);
    }

    public async Task<(bool Succeeded, string? Token, string? RefreshToken, string? Error)> RefreshTokenAsync(string expiredToken, string refreshToken)
    {
        var principal = GetPrincipalFromExpiredToken(expiredToken);
        if (principal == null)
        {
            return (false, null, null, "Invalid access token.");
        }

        var userIdClaim = principal.FindFirst(JwtRegisteredClaimNames.Sub) ?? principal.FindFirst(ClaimTypes.NameIdentifier);
        if (userIdClaim == null || !Guid.TryParse(userIdClaim.Value, out var userId))
        {
            return (false, null, null, "Invalid user claim context.");
        }

        var user = await _context.Users.FirstOrDefaultAsync(u => u.Id == userId);
        if (user == null || user.IsBanned)
        {
            return (false, null, null, "User not found or banned.");
        }

        var incomingHash = HashToken(refreshToken);
        if (user.RefreshTokenHash != incomingHash || user.RefreshTokenExpiry == null || user.RefreshTokenExpiry <= DateTime.UtcNow)
        {
            return (false, null, null, "Invalid or expired refresh token.");
        }

        // Rotate tokens: generate new Access Token and new Refresh Token, revoke old one
        var newToken = GenerateJwtToken(user);
        var newRefreshToken = GenerateRandomTokenString();

        user.RefreshTokenHash = HashToken(newRefreshToken);
        user.RefreshTokenExpiry = DateTime.UtcNow.AddDays(30);
        user.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        return (true, newToken, newRefreshToken, null);
    }

    private string GenerateJwtToken(User user)
    {
        var secret = _configuration["JwtSettings:Secret"];
        if (string.IsNullOrEmpty(secret))
        {
            var isDevelopment = string.Equals(Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT"), "Development", StringComparison.OrdinalIgnoreCase);
            if (isDevelopment)
            {
                secret = "super_secret_key_rentlanka_1234567890_long_enough";
            }
            else
            {
                throw new InvalidOperationException("CRITICAL: JwtSettings:Secret is not configured for token generation.");
            }
        }
        var issuer = _configuration["JwtSettings:Issuer"] ?? "RentLanka";

        var audience = _configuration["JwtSettings:Audience"] ?? "RentLankaUsers";
        var expiryInMinutes = double.Parse(_configuration["JwtSettings:ExpiryInMinutes"] ?? "1440"); // 1 day

        var tokenHandler = new JwtSecurityTokenHandler();
        var key = Encoding.UTF8.GetBytes(secret);

        var tokenDescriptor = new SecurityTokenDescriptor
        {
            Subject = new ClaimsIdentity(new[]
            {
                new Claim(JwtRegisteredClaimNames.Sub, user.Id.ToString()),
                new Claim(JwtRegisteredClaimNames.Email, user.Email),
                new Claim("firstName", user.FirstName),
                new Claim("lastName", user.LastName),
                new Claim("verificationLevel", ((int)user.VerificationLevel).ToString()),
                new Claim(ClaimTypes.Role, user.Role),
                new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
            }),
            Expires = DateTime.UtcNow.AddMinutes(expiryInMinutes),
            Issuer = issuer,
            Audience = audience,
            SigningCredentials = new SigningCredentials(new SymmetricSecurityKey(key), SecurityAlgorithms.HmacSha256)
        };

        var token = tokenHandler.CreateToken(tokenDescriptor);
        return tokenHandler.WriteToken(token);
    }

    private ClaimsPrincipal? GetPrincipalFromExpiredToken(string token)
    {
        var secret = _configuration["JwtSettings:Secret"] ?? "super_secret_key_rentlanka_1234567890_long_enough";
        var key = Encoding.UTF8.GetBytes(secret);

        var tokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = new SymmetricSecurityKey(key),
            ValidateIssuer = true,
            ValidIssuer = _configuration["JwtSettings:Issuer"] ?? "RentLanka",
            ValidateAudience = true,
            ValidAudience = _configuration["JwtSettings:Audience"] ?? "RentLankaUsers",
            ValidateLifetime = false // Keep false to allow validating expired tokens
        };

        var tokenHandler = new JwtSecurityTokenHandler();
        try
        {
            var principal = tokenHandler.ValidateToken(token, tokenValidationParameters, out var securityToken);
            if (securityToken is not JwtSecurityToken jwtSecurityToken || 
                !jwtSecurityToken.Header.Alg.Equals(SecurityAlgorithms.HmacSha256, StringComparison.OrdinalIgnoreCase))
            {
                return null;
            }

            return principal;
        }
        catch
        {
            return null;
        }
    }

    private string GenerateRandomTokenString()
    {
        var randomNumber = new byte[64];
        using var rng = System.Security.Cryptography.RandomNumberGenerator.Create();
        rng.GetBytes(randomNumber);
        return Convert.ToBase64String(randomNumber);
    }

    private string HashToken(string token)
    {
        using var sha256 = System.Security.Cryptography.SHA256.Create();
        var hashedBytes = sha256.ComputeHash(Encoding.UTF8.GetBytes(token));
        return Convert.ToBase64String(hashedBytes);
    }
}
