using System;
using System.Threading.Tasks;
using RentLanka.Api.Models.DTOs;
using RentLanka.Api.Models.Requests;

namespace RentLanka.Api.Services.Interfaces;

public interface IUserService
{
    Task<UserResponse?> GetCurrentUserAsync(Guid userId);
    Task<UserResponse?> GetPublicProfileAsync(Guid userId);
    Task<(bool Succeeded, UserResponse? User, string? Error)> UpdateUserAsync(Guid userId, UpdateUserRequest request);
}
