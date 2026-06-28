using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using RentLanka.Api.Models.DTOs;

namespace RentLanka.Api.Services.Interfaces;

public interface IAdminService
{
    Task<PaginatedResponse<UserResponse>> GetUsersAsync(string? query, int page, int pageSize);
    Task<UserResponse?> GetUserByIdAsync(Guid userId);
    Task<bool> ToggleUserBanAsync(Guid userId);
    Task<bool> OverrideUserVerificationAsync(Guid userId, int level, bool isTrusted);
    Task<PaginatedResponse<ListingResponse>> GetListingsAsync(string? query, bool? isPaused, bool? isDeleted, int page, int pageSize);
    Task<bool> ToggleListingPauseAsync(Guid listingId);
    Task<bool> DeleteListingAsync(Guid listingId);
    Task<bool> ApproveListingAsync(Guid listingId);
    Task<bool> RejectListingAsync(Guid listingId);
    Task<IEnumerable<UserResponse>> GetKycQueueAsync();
    Task<bool> ApproveKycAsync(Guid userId);
    Task<bool> RejectKycAsync(Guid userId);
    Task<AdminDashboardStats> GetDashboardStatsAsync();
}
