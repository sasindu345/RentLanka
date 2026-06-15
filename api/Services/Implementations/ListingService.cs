using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using NetTopologySuite;
using NetTopologySuite.Geometries;
using RentLanka.Api.Data;
using RentLanka.Api.Models.DTOs;
using RentLanka.Api.Models.Entities;
using RentLanka.Api.Models.Requests;
using RentLanka.Api.Services.Interfaces;

namespace RentLanka.Api.Services.Implementations;

public class ListingService : IListingService
{
    private readonly AppDbContext _context;

    public ListingService(AppDbContext context)
    {
        _context = context;
    }

    public async Task<ListingResponse> CreateListingAsync(Guid ownerId, CreateListingRequest request)
    {
        var geometryFactory = NtsGeometryServices.Instance.CreateGeometryFactory(srid: 4326);
        var location = geometryFactory.CreatePoint(new Coordinate(request.Longitude, request.Latitude));

        var listing = new Listing
        {
            Id = Guid.NewGuid(),
            OwnerId = ownerId,
            Title = request.Title,
            Description = request.Description,
            Category = request.Category,
            PricePerDay = request.PricePerDay,
            SecurityDeposit = request.SecurityDeposit,
            Rules = request.Rules,
            Location = location,
            District = request.District,
            Images = request.Images ?? new List<string>(),
            IsPaused = false,
            CreatedAt = DateTime.UtcNow
        };

        _context.Listings.Add(listing);
        await _context.SaveChangesAsync();

        return MapToResponse(listing);
    }

    public async Task<ListingResponse?> GetListingByIdAsync(Guid id)
    {
        var listing = await _context.Listings.FindAsync(id);
        return listing == null ? null : MapToResponse(listing);
    }

    public async Task<IEnumerable<ListingResponse>> SearchListingsAsync(
        string? query,
        string? category,
        string? district,
        double? userLat,
        double? userLon,
        double? maxDistanceMeters)
    {
        var dbQuery = _context.Listings.AsQueryable();

        // 1. Basic Filters
        if (!string.IsNullOrWhiteSpace(category))
        {
            dbQuery = dbQuery.Where(l => l.Category.ToLower() == category.ToLower());
        }

        if (!string.IsNullOrWhiteSpace(district))
        {
            dbQuery = dbQuery.Where(l => l.District.ToLower() == district.ToLower());
        }

        if (!string.IsNullOrWhiteSpace(query))
        {
            var searchPattern = $"%{query.ToLower()}%";
            dbQuery = dbQuery.Where(l => EF.Functions.Like(l.Title.ToLower(), searchPattern) ||
                                         EF.Functions.Like(l.Description.ToLower(), searchPattern));
        }

        // 2. Spatial Distance Filter (if provided)
        if (userLat.HasValue && userLon.HasValue && maxDistanceMeters.HasValue)
        {
            var geometryFactory = NtsGeometryServices.Instance.CreateGeometryFactory(srid: 4326);
            var userLocation = geometryFactory.CreatePoint(new Coordinate(userLon.Value, userLat.Value));

            // EF Core translates Point.Distance to ST_Distance. On geography, ST_Distance returns meters.
            dbQuery = dbQuery.Where(l => l.Location.Distance(userLocation) <= maxDistanceMeters.Value);
        }

        var listings = await dbQuery.ToListAsync();
        return listings.Select(MapToResponse);
    }

    private static ListingResponse MapToResponse(Listing listing)
    {
        return new ListingResponse(
            listing.Id,
            listing.OwnerId,
            listing.Title,
            listing.Description,
            listing.Category,
            listing.PricePerDay,
            listing.SecurityDeposit,
            listing.Rules,
            listing.Location.Y, // Latitude (Y)
            listing.Location.X, // Longitude (X)
            listing.District,
            listing.Images,
            listing.IsPaused,
            listing.CreatedAt,
            listing.UpdatedAt
        );
    }
}
