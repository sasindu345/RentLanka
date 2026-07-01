using System;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using RentLanka.Api.Data;
using RentLanka.Api.Models.DTOs;
using RentLanka.Api.Models.Entities;
using RentLanka.Api.Models.Requests;
using RentLanka.Api.Services.Interfaces;

namespace RentLanka.Api.Services.Implementations;

public class UserService : IUserService
{
    private readonly AppDbContext _context;

    public UserService(AppDbContext context)
    {
        _context = context;
    }

    public async Task<UserResponse?> GetCurrentUserAsync(Guid userId)
    {
        var user = await _context.Users.AsNoTracking().FirstOrDefaultAsync(u => u.Id == userId);
        return user == null ? null : MapToResponse(user);
    }

    public async Task<UserResponse?> GetPublicProfileAsync(Guid userId)
    {
        var user = await _context.Users.AsNoTracking().FirstOrDefaultAsync(u => u.Id == userId);
        return user == null ? null : MapToResponse(user);
    }

    public async Task<(bool Succeeded, UserResponse? User, string? Error)> UpdateUserAsync(Guid userId, UpdateUserRequest request)
    {
        var user = await _context.Users.FirstOrDefaultAsync(u => u.Id == userId);
        if (user == null)
        {
            return (false, null, "User not found.");
        }

        if (!string.IsNullOrWhiteSpace(request.FirstName))
        {
            user.FirstName = request.FirstName.Trim();
        }

        if (!string.IsNullOrWhiteSpace(request.LastName))
        {
            user.LastName = request.LastName.Trim();
        }

        if (!string.IsNullOrWhiteSpace(request.PhoneNumber))
        {
            user.PhoneNumber = request.PhoneNumber.Trim();
        }

        if (!string.IsNullOrWhiteSpace(request.Role))
        {
            var roleTrimmed = request.Role.Trim();
            if (roleTrimmed != "Renter" && roleTrimmed != "Owner")
            {
                return (false, null, "Invalid role. Role must be either Renter or Owner.");
            }
            user.Role = roleTrimmed;
        }

        user.UpdatedAt = DateTime.UtcNow;
        await _context.SaveChangesAsync();

        return (true, MapToResponse(user), null);
    }

    private static UserResponse MapToResponse(User user)
    {
        return new UserResponse(
            user.Id,
            user.Email,
            user.FirstName,
            user.LastName,
            user.PhoneNumber,
            (int)user.VerificationLevel,
            user.IsTrustedUser,
            user.AvatarUrl,
            user.CreatedAt,
            user.Role,
            user.IsBanned,
            user.NICNumber,
            user.NicDocumentUrl);
    }
}
