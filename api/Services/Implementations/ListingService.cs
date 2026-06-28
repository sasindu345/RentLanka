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
        await EnsureOwnerCanListAsync(ownerId);

        var listing = BuildListing(ownerId, request);
        _context.Listings.Add(listing);
        await _context.SaveChangesAsync();

        return await MapToResponseAsync(listing.Id);
    }

    public async Task<ListingResponse?> GetListingByIdAsync(Guid id, bool includePausedForOwner = false, Guid? ownerId = null)
    {
        var listing = await _context.Listings
            .Include(l => l.Owner)
            .FirstOrDefaultAsync(l => l.Id == id && !l.IsDeleted);

        if (listing == null)
        {
            return null;
        }

        if ((listing.IsPaused || listing.Status != ListingStatus.Approved) && listing.OwnerId != ownerId)
        {
            return null;
        }

        return MapToResponse(listing);
    }

    public async Task<PaginatedResponse<ListingResponse>> SearchListingsAsync(
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
        string? sortBy)
    {
        page = Math.Max(1, page);
        pageSize = Math.Clamp(pageSize, 1, 100);

        var dbQuery = _context.Listings
            .Include(l => l.Owner)
            .Where(l => !l.IsDeleted && !l.IsPaused && l.Status == ListingStatus.Approved)
            .AsQueryable();

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
            dbQuery = dbQuery.Where(l =>
                EF.Functions.Like(l.Title.ToLower(), searchPattern) ||
                EF.Functions.Like(l.Description.ToLower(), searchPattern));
        }

        if (minPrice.HasValue)
        {
            dbQuery = dbQuery.Where(l => l.PricePerDay >= minPrice.Value);
        }

        if (maxPrice.HasValue)
        {
            dbQuery = dbQuery.Where(l => l.PricePerDay <= maxPrice.Value);
        }

        if (userLat.HasValue && userLon.HasValue && maxDistanceMeters.HasValue)
        {
            var geometryFactory = NtsGeometryServices.Instance.CreateGeometryFactory(srid: 4326);
            var userLocation = geometryFactory.CreatePoint(new Coordinate(userLon.Value, userLat.Value));
            dbQuery = dbQuery.Where(l => l.Location.Distance(userLocation) <= maxDistanceMeters.Value);
        }

        dbQuery = sortBy?.ToLower() switch
        {
            "price_asc" => dbQuery.OrderBy(l => l.PricePerDay),
            "price_desc" => dbQuery.OrderByDescending(l => l.PricePerDay),
            "oldest" => dbQuery.OrderBy(l => l.CreatedAt),
            _ => dbQuery.OrderByDescending(l => l.CreatedAt)
        };

        var total = await dbQuery.CountAsync();
        var listings = await dbQuery
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return new PaginatedResponse<ListingResponse>(
            listings.Select(MapToResponse).ToList(),
            total,
            page,
            pageSize);
    }

    public async Task<IEnumerable<ListingResponse>> GetMyListingsAsync(Guid ownerId)
    {
        var listings = await _context.Listings
            .Include(l => l.Owner)
            .Where(l => l.OwnerId == ownerId && !l.IsDeleted)
            .OrderByDescending(l => l.CreatedAt)
            .ToListAsync();

        return listings.Select(MapToResponse);
    }

    public async Task<(bool Succeeded, ListingResponse? Listing, string? Error)> UpdateListingAsync(
        Guid ownerId,
        Guid listingId,
        UpdateListingRequest request)
    {
        var listing = await _context.Listings
            .Include(l => l.Owner)
            .FirstOrDefaultAsync(l => l.Id == listingId && !l.IsDeleted);

        if (listing == null)
        {
            return (false, null, "Listing not found.");
        }

        if (listing.OwnerId != ownerId)
        {
            return (false, null, "You do not have permission to update this listing.");
        }

        ApplyListingDetails(listing, request);
        listing.UpdatedAt = DateTime.UtcNow;
        await _context.SaveChangesAsync();

        return (true, MapToResponse(listing), null);
    }

    public async Task<(bool Succeeded, string? Error)> DeleteListingAsync(Guid ownerId, Guid listingId)
    {
        var listing = await _context.Listings.FirstOrDefaultAsync(l => l.Id == listingId && !l.IsDeleted);
        if (listing == null)
        {
            return (false, "Listing not found.");
        }

        if (listing.OwnerId != ownerId)
        {
            return (false, "You do not have permission to delete this listing.");
        }

        listing.IsDeleted = true;
        listing.UpdatedAt = DateTime.UtcNow;
        await _context.SaveChangesAsync();

        return (true, null);
    }

    public async Task<(bool Succeeded, ListingResponse? Listing, string? Error)> TogglePauseAsync(Guid ownerId, Guid listingId)
    {
        var listing = await _context.Listings
            .Include(l => l.Owner)
            .FirstOrDefaultAsync(l => l.Id == listingId && !l.IsDeleted);

        if (listing == null)
        {
            return (false, null, "Listing not found.");
        }

        if (listing.OwnerId != ownerId)
        {
            return (false, null, "You do not have permission to update this listing.");
        }

        listing.IsPaused = !listing.IsPaused;
        listing.UpdatedAt = DateTime.UtcNow;
        await _context.SaveChangesAsync();

        return (true, MapToResponse(listing), null);
    }

    private async Task EnsureOwnerCanListAsync(Guid ownerId)
    {
        var user = await _context.Users.AsNoTracking().FirstOrDefaultAsync(u => u.Id == ownerId);
        if (user == null)
        {
            throw new UnauthorizedAccessException("User not found.");
        }

        if (user.VerificationLevel < VerificationLevel.Level1)
        {
            throw new InvalidOperationException("Phone verification (Level 1) is required to create listings.");
        }
    }

    private static Listing BuildListing(Guid ownerId, CreateListingRequest request)
    {
        var geometryFactory = NtsGeometryServices.Instance.CreateGeometryFactory(srid: 4326);
        var location = geometryFactory.CreatePoint(new Coordinate(request.Longitude, request.Latitude));

        return new Listing
        {
            Id = Guid.NewGuid(),
            OwnerId = ownerId,
            Title = request.Title.Trim(),
            Description = request.Description.Trim(),
            Category = request.Category.Trim(),
            PricePerDay = request.PricePerDay,
            SecurityDeposit = request.SecurityDeposit,
            Rules = request.Rules.Trim(),
            Location = location,
            District = request.District.Trim(),
            Images = request.Images ?? new List<string>(),
            IsPaused = false,
            IsDeleted = false,
            Status = ListingStatus.PendingApproval,
            CreatedAt = DateTime.UtcNow
        };
    }

    private static void ApplyListingDetails(Listing listing, UpdateListingRequest request)
    {
        var geometryFactory = NtsGeometryServices.Instance.CreateGeometryFactory(srid: 4326);
        listing.Title = request.Title.Trim();
        listing.Description = request.Description.Trim();
        listing.Category = request.Category.Trim();
        listing.PricePerDay = request.PricePerDay;
        listing.SecurityDeposit = request.SecurityDeposit;
        listing.Rules = request.Rules.Trim();
        listing.Location = geometryFactory.CreatePoint(new Coordinate(request.Longitude, request.Latitude));
        listing.District = request.District.Trim();
        listing.Images = request.Images ?? new List<string>();
    }

    private async Task<ListingResponse> MapToResponseAsync(Guid listingId)
    {
        var listing = await _context.Listings
            .Include(l => l.Owner)
            .FirstAsync(l => l.Id == listingId);

        return MapToResponse(listing);
    }

    private static ListingResponse MapToResponse(Listing listing)
    {
        return new ListingResponse(
            listing.Id,
            listing.OwnerId,
            new OwnerSummary(
                listing.Owner.Id,
                listing.Owner.FirstName,
                listing.Owner.LastName,
                listing.Owner.AvatarUrl,
                listing.Owner.IsTrustedUser,
                (int)listing.Owner.VerificationLevel),
            listing.Title,
            listing.Description,
            listing.Category,
            listing.PricePerDay,
            listing.SecurityDeposit,
            listing.Rules,
            listing.Location.Y,
            listing.Location.X,
            listing.District,
            listing.Images,
            listing.IsPaused,
            listing.Status.ToString(),
            listing.CreatedAt,
            listing.UpdatedAt);
    }
}
