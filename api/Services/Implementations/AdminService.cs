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
            .Where(u => u.KycStatus == KycStatus.PendingApproval && !u.IsBanned)
            .OrderBy(u => u.UpdatedAt ?? u.CreatedAt)
            .ToListAsync();

        return users.Select(MapUserToResponse);
    }

    public async Task<bool> ApproveKycAsync(Guid userId)
    {
        var user = await _context.Users.FirstOrDefaultAsync(u => u.Id == userId);
        if (user == null || user.KycStatus != KycStatus.PendingApproval)
        {
            return false;
        }

        user.VerificationLevel = VerificationLevel.Level3;
        user.KycStatus = KycStatus.Approved;
        user.KycRejectionReason = null;
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

    public async Task<bool> RejectKycAsync(Guid userId, string reason)
    {
        var user = await _context.Users.FirstOrDefaultAsync(u => u.Id == userId);
        if (user == null || user.KycStatus != KycStatus.PendingApproval)
        {
            return false;
        }

        user.VerificationLevel = VerificationLevel.Level0;
        user.KycStatus = KycStatus.Rejected;
        user.KycRejectionReason = reason;
        user.UpdatedAt = DateTime.UtcNow;
        await _context.SaveChangesAsync();

        _ = Task.Run(async () =>
        {
            try
            {
                await _notificationService.SendNotificationToUserAsync(
                    userId,
                    "KYC Rejected",
                    $"Your KYC verification was rejected. Reason: {reason}. Please re-submit valid documents.",
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
        var pendingKycCount = await _context.Users.CountAsync(u => u.KycStatus == KycStatus.PendingApproval && !u.IsBanned);
        var totalBookings = await _context.Bookings.CountAsync();
        var openDisputes = await _context.Disputes.CountAsync(d => !d.IsResolved);

        // 7-day timeseries (daily)
        var today = DateTime.UtcNow.Date;
        var timeSeries7d = new List<TimeSeriesPoint>();
        for (int i = 6; i >= 0; i--)
        {
            var day = today.AddDays(-i);
            var dayStart = day;
            var dayEnd = day.AddDays(1);
            var bookings = await _context.Bookings
                .Where(b => b.CreatedAt >= dayStart && b.CreatedAt < dayEnd)
                .ToListAsync();
            var bookingsCount = bookings.Count;
            var revenue = bookings.Sum(b => b.TotalPrice);
            timeSeries7d.Add(new TimeSeriesPoint(day.ToString("ddd"), bookingsCount, revenue, day.ToString("yyyy-MM-dd")));
        }

        // 30-day timeseries grouped by week (5 weeks)
        var timeSeries30d = new List<TimeSeriesPoint>();
        var start30 = today.AddDays(-29);
        for (int w = 0; w < 5; w++)
        {
            var weekStart = start30.AddDays(w * 7);
            var weekEnd = weekStart.AddDays(7);
            var bookings = await _context.Bookings
                .Where(b => b.CreatedAt >= weekStart && b.CreatedAt < weekEnd)
                .ToListAsync();
            var bookingsCount = bookings.Count;
            var revenue = bookings.Sum(b => b.TotalPrice);
            var label = $"W{w + 1}";
            var rangeLabel = weekStart.ToString("MMM d") + " - " + weekEnd.AddDays(-1).ToString("MMM d");
            timeSeries30d.Add(new TimeSeriesPoint(label, bookingsCount, revenue, rangeLabel));
        }

        // Category share
        var categoryGroups = await _context.Listings
            .Where(l => !l.IsDeleted)
            .GroupBy(l => l.Category)
            .Select(g => new { Category = g.Key, Count = g.Count() })
            .ToListAsync();
        var totalCat = categoryGroups.Sum(g => g.Count);
        var categories = categoryGroups.Select(g => new CategoryShare(g.Category, g.Count, totalCat == 0 ? 0 : (int)Math.Round((double)g.Count / totalCat * 100))).ToList();

        // Verification distribution
        var fullyTrusted = await _context.Users.CountAsync(u => u.KycStatus == KycStatus.Approved);
        var unverified = await _context.Users.CountAsync(u => u.KycStatus == KycStatus.None);
        var basic = totalUsers - fullyTrusted - unverified;
        var verifs = new List<VerificationSegment>
        {
            new VerificationSegment("Fully Trusted (KYC Verified)", totalUsers == 0 ? 0 : (int)Math.Round((double)fullyTrusted / totalUsers * 100)),
            new VerificationSegment("Basic Authenticated (Email/Phone)", totalUsers == 0 ? 0 : (int)Math.Round((double)basic / totalUsers * 100)),
            new VerificationSegment("Unverified (New Registrants)", totalUsers == 0 ? 0 : (int)Math.Round((double)unverified / totalUsers * 100)),
        };

        // Escrow / payments
        var totalPayments = await _context.Payments.SumAsync(p => (decimal?)p.Amount) ?? 0m;
        var escrowReserves = await _context.Payments.Where(p => p.Status == PaymentStatus.Authorized || p.Status == PaymentStatus.Captured).SumAsync(p => (decimal?)p.Amount) ?? 0m;
        var releasedPayments = await _context.Payments.Where(p => p.Status == PaymentStatus.Released).SumAsync(p => (decimal?)p.Amount) ?? 0m;
        var payoutsPaid = await _context.Payouts.Where(p => p.Status == PayoutStatus.Paid).SumAsync(p => (decimal?)p.Amount) ?? 0m;
        var releasedToOwners = releasedPayments + payoutsPaid;
        var escrowPercent = totalPayments == 0 ? 0 : (int)Math.Round((double)escrowReserves / (double)totalPayments * 100);
        var payoutsPercent = totalPayments == 0 ? 0 : (int)Math.Round((double)payoutsPaid / (double)totalPayments * 100);
        var disputesPercent = 100 - escrowPercent - payoutsPercent;
        var escrowStats = new EscrowStats(totalPayments, escrowReserves, releasedToOwners, escrowPercent, payoutsPercent, disputesPercent);

        // Recent events (simple synthesized list)
        var recentEvents = new List<SystemEvent>();
        var recentKyc = await _context.Users.Where(u => u.KycStatus == KycStatus.PendingApproval).OrderByDescending(u => u.UpdatedAt ?? u.CreatedAt).Take(2).ToListAsync();
        foreach (var u in recentKyc)
        {
            recentEvents.Add(new SystemEvent($"Verification requested by {u.FirstName} {u.LastName}", ((u.UpdatedAt ?? u.CreatedAt).ToLocalTime()).ToString("g"), "kyc"));
        }
        var recentListings = await _context.Listings.Where(l => !l.IsDeleted).OrderByDescending(l => l.CreatedAt).Take(2).ToListAsync();
        foreach (var l in recentListings)
        {
            recentEvents.Add(new SystemEvent($"New Listing: {l.Title} registered", l.CreatedAt.ToLocalTime().ToString("g"), "listing"));
        }
        var recentPayouts = await _context.Payouts.OrderByDescending(p => p.CreatedAt).Take(2).ToListAsync();
        foreach (var p in recentPayouts)
        {
            recentEvents.Add(new SystemEvent($"Payout {p.Id.ToString().Split('-').First()} amount LKR {p.Amount} status {p.Status}", p.CreatedAt.ToLocalTime().ToString("g"), "payout"));
        }

        return new AdminDashboardStats(
            totalUsers,
            activeListings,
            pendingKycCount,
            totalBookings,
            openDisputes,
            timeSeries7d,
            timeSeries30d,
            categories,
            verifs,
            escrowStats,
            recentEvents);
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
            user.NicDocumentUrl,
            user.NicFrontUrl,
            user.NicBackUrl,
            user.FaceCaptureUrl,
            user.KycStatus.ToString(),
            user.KycRejectionReason);
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
            listing.Address,
            listing.District,
            listing.Images,
            listing.IsPaused,
            listing.Status.ToString(),
            listing.CreatedAt,
            listing.UpdatedAt);
    }
}
