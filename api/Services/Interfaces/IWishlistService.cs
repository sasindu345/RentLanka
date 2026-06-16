using System;
using System.Threading.Tasks;
using RentLanka.Api.Models.DTOs;

namespace RentLanka.Api.Services.Interfaces;

public interface IWishlistService
{
    Task<PaginatedResponse<ListingResponse>> GetWishlistAsync(Guid userId, int page, int pageSize);
    Task<(bool Succeeded, string? Error)> AddToWishlistAsync(Guid userId, Guid listingId);
    Task<(bool Succeeded, string? Error)> RemoveFromWishlistAsync(Guid userId, Guid listingId);
}
