using System;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;
using RentLanka.Application.Common.Interfaces;
using RentLanka.Domain.Entities;
using BC = BCrypt.Net.BCrypt;

namespace RentLanka.Infrastructure.Identity;

public class IdentityService : IIdentityService
{
    private readonly IApplicationDbContext _context;
    private readonly IConfiguration _configuration;

    public IdentityService(IApplicationDbContext context, IConfiguration configuration)
    {
        _context = context;
        _configuration = configuration;
    }

    public async Task<(bool Succeeded, Guid UserId, string? Error)> CreateUserAsync(
        string email, 
        string password, 
        string firstName, 
        string lastName, 
        string phoneNumber)
    {
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
            CreatedAt = DateTime.UtcNow
        };

        _context.Users.Add(user);
        await _context.SaveChangesAsync(CancellationToken.None);

        return (true, user.Id, null);
    }

    public async Task<(bool Succeeded, string? Token, string? Error)> LoginAsync(string email, string password)
    {
        var user = await _context.Users.FirstOrDefaultAsync(u => u.Email == email);
        if (user == null || !BC.Verify(password, user.PasswordHash))
        {
            return (false, null, "Invalid email or password.");
        }

        var token = GenerateJwtToken(user);
        return (true, token, null);
    }

    private string GenerateJwtToken(User user)
    {
        var secret = _configuration["JwtSettings:Secret"] ?? "super_secret_key_rentlanka_1234567890_long_enough";
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
                new Claim("verificationLevel", ((int)user.VerificationLevel).ToString())
            }),
            Expires = DateTime.UtcNow.AddMinutes(expiryInMinutes),
            Issuer = issuer,
            Audience = audience,
            SigningCredentials = new SigningCredentials(new SymmetricSecurityKey(key), SecurityAlgorithms.HmacSha256Signature)
        };

        var token = tokenHandler.CreateToken(tokenDescriptor);
        return tokenHandler.WriteToken(token);
    }
}
