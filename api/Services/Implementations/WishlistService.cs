using System;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using RentLanka.Api.Data;
using RentLanka.Api.Models.DTOs;
using RentLanka.Api.Models.Entities;
using RentLanka.Api.Services.Interfaces;

namespace RentLanka.Api.Services.Implementations;

public class WishlistService : IWishlistService
{
    private readonly AppDbContext _context;

    public WishlistService(AppDbContext context)
    {
        _context = context;
    }

    public async Task<PaginatedResponse<ListingResponse>> GetWishlistAsync(Guid userId, int page, int pageSize)
    {
        page = Math.Max(1, page);
        pageSize = Math.Clamp(pageSize, 1, 100);

        var query = _context.WishlistItems
            .AsNoTracking()
            .Where(w => w.UserId == userId)
            .Include(w => w.Listing)
                .ThenInclude(l => l.Owner)
            .Where(w => !w.Listing.IsDeleted)
            .OrderByDescending(w => w.CreatedAt);

        var total = await query.CountAsync();
        var items = await query
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(w => w.Listing)
            .ToListAsync();

        var responses = items
            .Where(l => !l.IsPaused)
            .Select(l => new ListingResponse(
                l.Id,
                l.OwnerId,
                new OwnerSummary(
                    l.Owner.Id,
                    l.Owner.FirstName,
                    l.Owner.LastName,
                    l.Owner.AvatarUrl,
                    l.Owner.IsTrustedUser,
                    (int)l.Owner.VerificationLevel),
                l.Title,
                l.Description,
                l.Category,
                l.PricePerDay,
                l.SecurityDeposit,
                l.Rules,
                l.Location.Y,
                l.Location.X,
                l.District,
                l.Images,
                l.IsPaused,
                l.Status.ToString(),
                l.CreatedAt,
                l.UpdatedAt))
            .ToList();

        return new PaginatedResponse<ListingResponse>(responses, total, page, pageSize);
    }

    public async Task<(bool Succeeded, string? Error)> AddToWishlistAsync(Guid userId, Guid listingId)
    {
        var listingExists = await _context.Listings
            .AnyAsync(l => l.Id == listingId && !l.IsDeleted && !l.IsPaused);

        if (!listingExists)
        {
            return (false, "Listing not found.");
        }

        var alreadySaved = await _context.WishlistItems
            .AnyAsync(w => w.UserId == userId && w.ListingId == listingId);

        if (alreadySaved)
        {
            return (true, null);
        }

        _context.WishlistItems.Add(new WishlistItem
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            ListingId = listingId,
            CreatedAt = DateTime.UtcNow
        });

        await _context.SaveChangesAsync();
        return (true, null);
    }

    public async Task<(bool Succeeded, string? Error)> RemoveFromWishlistAsync(Guid userId, Guid listingId)
    {
        var item = await _context.WishlistItems
            .FirstOrDefaultAsync(w => w.UserId == userId && w.ListingId == listingId);

        if (item == null)
        {
            return (false, "Wishlist item not found.");
        }

        _context.WishlistItems.Remove(item);
        await _context.SaveChangesAsync();
        return (true, null);
    }
}
