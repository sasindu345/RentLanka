using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using RentLanka.Api.Models.DTOs;
using RentLanka.Api.Models.Requests;

namespace RentLanka.Api.Services.Interfaces;

public interface IListingService
{
    Task<ListingResponse> CreateListingAsync(Guid ownerId, CreateListingRequest request);
    Task<ListingResponse?> GetListingByIdAsync(Guid id);
    Task<IEnumerable<ListingResponse>> SearchListingsAsync(
        string? query, 
        string? category, 
        string? district, 
        double? userLat, 
        double? userLon, 
        double? maxDistanceMeters);
}
