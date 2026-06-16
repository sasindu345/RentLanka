using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using RentLanka.Api.Models.DTOs;
using RentLanka.Api.Models.Requests;

namespace RentLanka.Api.Services.Interfaces;

public interface IListingService
{
    Task<ListingResponse> CreateListingAsync(Guid ownerId, CreateListingRequest request);
    Task<ListingResponse?> GetListingByIdAsync(Guid id, bool includePausedForOwner = false, Guid? ownerId = null);
    Task<PaginatedResponse<ListingResponse>> SearchListingsAsync(
        string? query,
        string? category,
        string? district,
        double? userLat,
        double? userLon,
        double? maxDistanceMeters,
        decimal? minPrice,
        decimal? maxPrice,
        int page,
        int pageSize,
        string? sortBy);
    Task<IEnumerable<ListingResponse>> GetMyListingsAsync(Guid ownerId);
    Task<(bool Succeeded, ListingResponse? Listing, string? Error)> UpdateListingAsync(Guid ownerId, Guid listingId, UpdateListingRequest request);
    Task<(bool Succeeded, string? Error)> DeleteListingAsync(Guid ownerId, Guid listingId);
    Task<(bool Succeeded, ListingResponse? Listing, string? Error)> TogglePauseAsync(Guid ownerId, Guid listingId);
}
