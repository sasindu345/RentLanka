using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using RentLanka.Api.Data;
using RentLanka.Api.Models.DTOs;
using RentLanka.Api.Models.Entities;
using RentLanka.Api.Services.Interfaces;

namespace RentLanka.Api.Services.Implementations;

public class AdminService : IAdminService
{
    private readonly AppDbContext _context;
    private readonly INotificationService _notificationService;

    public AdminService(AppDbContext context, INotificationService notificationService)
    {
        _context = context;
        _notificationService = notificationService;
    }

    public async Task<PaginatedResponse<UserResponse>> GetUsersAsync(string? query, int page, int pageSize)
    {
        page = Math.Max(1, page);
        pageSize = Math.Clamp(pageSize, 1, 100);

        var dbQuery = _context.Users.AsNoTracking().AsQueryable();

        if (!string.IsNullOrWhiteSpace(query))
        {
            var search = $"%{query.ToLower()}%";
            dbQuery = dbQuery.Where(u =>
                EF.Functions.Like(u.FirstName.ToLower(), search) ||
                EF.Functions.Like(u.LastName.ToLower(), search) ||
                EF.Functions.Like(u.Email.ToLower(), search));
        }

        var total = await dbQuery.CountAsync();
        var users = await dbQuery
            .OrderByDescending(u => u.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return new PaginatedResponse<UserResponse>(
            users.Select(MapUserToResponse).ToList(),
            total,
            page,
            pageSize);
    }

    public async Task<UserResponse?> GetUserByIdAsync(Guid userId)
    {
        var user = await _context.Users.AsNoTracking().FirstOrDefaultAsync(u => u.Id == userId);
        return user == null ? null : MapUserToResponse(user);
    }

    public async Task<bool> ToggleUserBanAsync(Guid userId)
    {
        var user = await _context.Users.FirstOrDefaultAsync(u => u.Id == userId);
        if (user == null || user.Role == "Admin")
        {
            return false;
        }

        user.IsBanned = !user.IsBanned;
        user.UpdatedAt = DateTime.UtcNow;
        await _context.SaveChangesAsync();
        return true;
    }

    public async Task<bool> OverrideUserVerificationAsync(Guid userId, int level, bool isTrusted)
    {
        var user = await _context.Users.FirstOrDefaultAsync(u => u.Id == userId);
        if (user == null)
        {
            return false;
        }

        user.VerificationLevel = (VerificationLevel)level;
        user.IsTrustedUser = isTrusted;
        user.UpdatedAt = DateTime.UtcNow;
        await _context.SaveChangesAsync();
        return true;
    }

    public async Task<PaginatedResponse<ListingResponse>> GetListingsAsync(string? query, bool? isPaused, bool? isDeleted, string? status, int page, int pageSize)
    {
        page = Math.Max(1, page);
        pageSize = Math.Clamp(pageSize, 1, 100);

        var dbQuery = _context.Listings
            .Include(l => l.Owner)
            .AsNoTracking()
            .AsQueryable();

        if (isPaused.HasValue)
        {
            dbQuery = dbQuery.Where(l => l.IsPaused == isPaused.Value);
        }

        if (isDeleted.HasValue)
        {
            dbQuery = dbQuery.Where(l => l.IsDeleted == isDeleted.Value);
        }

        if (!string.IsNullOrWhiteSpace(status) && Enum.TryParse<ListingStatus>(status, true, out var parsedStatus))
        {
            dbQuery = dbQuery.Where(l => l.Status == parsedStatus);
        }

        if (!string.IsNullOrWhiteSpace(query))
        {
            var search = $"%{query.ToLower()}%";
            dbQuery = dbQuery.Where(l =>
                EF.Functions.Like(l.Title.ToLower(), search) ||
                EF.Functions.Like(l.Description.ToLower(), search));
        }

        var total = await dbQuery.CountAsync();
        var listings = await dbQuery
            .OrderByDescending(l => l.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return new PaginatedResponse<ListingResponse>(
            listings.Select(MapListingToResponse).ToList(),
            total,
            page,
            pageSize);
    }

    public async Task<bool> ToggleListingPauseAsync(Guid listingId)
    {
        var listing = await _context.Listings.FirstOrDefaultAsync(l => l.Id == listingId && !l.IsDeleted);
        if (listing == null)
        {
            return false;
        }

        listing.IsPaused = !listing.IsPaused;
        listing.UpdatedAt = DateTime.UtcNow;
        await _context.SaveChangesAsync();
        return true;
    }

    public async Task<bool> DeleteListingAsync(Guid listingId)
    {
        var listing = await _context.Listings.FirstOrDefaultAsync(l => l.Id == listingId && !l.IsDeleted);
        if (listing == null)
        {
            return false;
        }

        listing.IsDeleted = true;
        listing.UpdatedAt = DateTime.UtcNow;
        await _context.SaveChangesAsync();
        return true;
    }

    public async Task<bool> ApproveListingAsync(Guid listingId)
    {
        var listing = await _context.Listings.FirstOrDefaultAsync(l => l.Id == listingId && !l.IsDeleted);
        if (listing == null)
        {
            return false;
        }

        listing.Status = ListingStatus.Approved;
        listing.UpdatedAt = DateTime.UtcNow;
        await _context.SaveChangesAsync();

        _ = Task.Run(async () =>
        {
            try
            {
                await _notificationService.SendNotificationToUserAsync(
                    listing.OwnerId,
                    "Listing Approved",
                    $"Your listing '{listing.Title}' has been approved and is now public.",
                    new Dictionary<string, string>
                    {
                        { "listingId", listing.Id.ToString() },
                        { "type", "listing_approved" }
                    });
            }
            catch { }
        });

        return true;
    }

    public async Task<bool> RejectListingAsync(Guid listingId)
    {
        var listing = await _context.Listings.FirstOrDefaultAsync(l => l.Id == listingId && !l.IsDeleted);
        if (listing == null)
        {
            return false;
        }

        listing.Status = ListingStatus.Rejected;
        listing.UpdatedAt = DateTime.UtcNow;
        await _context.SaveChangesAsync();

        _ = Task.Run(async () =>
        {
            try
            {
                await _notificationService.SendNotificationToUserAsync(
                    listing.OwnerId,
                    "Listing Rejected",
                    $"Your listing '{listing.Title}' was rejected by moderation.",
                    new Dictionary<string, string>
                    {
                        { "listingId", listing.Id.ToString() },
                        { "type", "listing_rejected" }
                    });
            }
            catch { }
        });

        return true;
    }

    public async Task<IEnumerable<UserResponse>> GetKycQueueAsync()
    {
        var users = await _context.Users
            .AsNoTracking()
            .Where(u => u.VerificationLevel == VerificationLevel.Level2 && !u.IsBanned)
            .OrderBy(u => u.UpdatedAt ?? u.CreatedAt)
            .ToListAsync();

        return users.Select(MapUserToResponse);
    }

    public async Task<bool> ApproveKycAsync(Guid userId)
    {
        var user = await _context.Users.FirstOrDefaultAsync(u => u.Id == userId);
        if (user == null || user.VerificationLevel != VerificationLevel.Level2)
        {
            return false;
        }

        user.VerificationLevel = VerificationLevel.Level3;
        user.IsTrustedUser = true;
        user.UpdatedAt = DateTime.UtcNow;
        await _context.SaveChangesAsync();

        _ = Task.Run(async () =>
        {
            try
            {
                await _notificationService.SendNotificationToUserAsync(
                    userId,
                    "KYC Verified",
                    "Congratulations! Your KYC documents have been verified. You can now rent equipment.",
                    new Dictionary<string, string>
                    {
                        { "userId", userId.ToString() },
                        { "type", "kyc_approved" }
                    });
            }
            catch { }
        });

        return true;
    }

    public async Task<bool> RejectKycAsync(Guid userId)
    {
        var user = await _context.Users.FirstOrDefaultAsync(u => u.Id == userId);
        if (user == null || user.VerificationLevel != VerificationLevel.Level2)
        {
            return false;
        }

        user.VerificationLevel = VerificationLevel.Level1;
        user.NICNumber = null;
        user.NicDocumentUrl = null;
        user.UpdatedAt = DateTime.UtcNow;
        await _context.SaveChangesAsync();

        _ = Task.Run(async () =>
        {
            try
            {
                await _notificationService.SendNotificationToUserAsync(
                    userId,
                    "KYC Rejected",
                    "Your KYC verification was rejected. Please re-submit valid documents.",
                    new Dictionary<string, string>
                    {
                        { "userId", userId.ToString() },
                        { "type", "kyc_rejected" }
                    });
            }
            catch { }
        });

        return true;
    }

    public async Task<AdminDashboardStats> GetDashboardStatsAsync()
    {
        var totalUsers = await _context.Users.CountAsync();
        var activeListings = await _context.Listings.CountAsync(l => !l.IsDeleted && !l.IsPaused);
        var pendingKycCount = await _context.Users.CountAsync(u => u.VerificationLevel == VerificationLevel.Level2 && !u.IsBanned);
        var totalBookings = await _context.Bookings.CountAsync();

        return new AdminDashboardStats(
            totalUsers,
            activeListings,
            pendingKycCount,
            totalBookings,
            0
        );
    }

    private static UserResponse MapUserToResponse(User user)
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

    private static ListingResponse MapListingToResponse(Listing listing)
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
            listing.Location?.Y ?? 0,
            listing.Location?.X ?? 0,
            listing.District,
            listing.Images,
            listing.IsPaused,
            listing.Status.ToString(),
            listing.CreatedAt,
            listing.UpdatedAt);
    }
}
