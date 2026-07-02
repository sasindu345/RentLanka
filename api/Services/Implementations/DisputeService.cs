using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using RentLanka.Api.Data;
using RentLanka.Api.Models.DTOs;
using RentLanka.Api.Models.Entities;
using RentLanka.Api.Models.Requests;
using RentLanka.Api.Services.Interfaces;

namespace RentLanka.Api.Services.Implementations;

public class DisputeService : IDisputeService
{
    private readonly AppDbContext _context;
    private readonly INotificationService _notificationService;

    public DisputeService(AppDbContext context, INotificationService notificationService)
    {
        _context = context;
        _notificationService = notificationService;
    }

    public async Task<DisputeResponse> CreateDisputeAsync(Guid userId, CreateDisputeRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Reason))
        {
            throw new ArgumentException("Reason is required to file a dispute.");
        }

        var booking = await _context.Bookings
            .Include(b => b.Listing)
            .FirstOrDefaultAsync(b => b.Id == request.BookingId);

        if (booking == null)
        {
            throw new KeyNotFoundException("Booking not found.");
        }

        if (booking.RenterId != userId && booking.Listing.OwnerId != userId)
        {
            throw new UnauthorizedAccessException("You are not authorized to open a dispute for this booking.");
        }

        if (booking.Status != BookingStatus.Paid && 
            booking.Status != BookingStatus.Active && 
            booking.Status != BookingStatus.Completed)
        {
            throw new InvalidOperationException("You can only file a dispute on paid, active, or completed bookings.");
        }

        var existingDispute = await _context.Disputes.AnyAsync(d => d.BookingId == request.BookingId);
        if (existingDispute)
        {
            throw new InvalidOperationException("A dispute has already been filed for this booking.");
        }

        booking.Status = BookingStatus.Disputed;
        booking.UpdatedAt = DateTime.UtcNow;

        var dispute = new Dispute
        {
            Id = Guid.NewGuid(),
            BookingId = request.BookingId,
            CreatedById = userId,
            Reason = request.Reason.Trim(),
            IsResolved = false,
            CreatedAt = DateTime.UtcNow
        };

        _context.Disputes.Add(dispute);
        await _context.SaveChangesAsync();

        // Notify the other participant
        var recipientId = booking.RenterId == userId ? booking.Listing.OwnerId : booking.RenterId;
        _ = Task.Run(async () =>
        {
            try
            {
                await _notificationService.SendNotificationToUserAsync(
                    recipientId,
                    "Dispute Opened",
                    $"A dispute was opened on your booking for {booking.Listing.Title}.",
                    new Dictionary<string, string>
                    {
                        { "disputeId", dispute.Id.ToString() },
                        { "bookingId", booking.Id.ToString() },
                        { "type", "dispute_opened" }
                    });
            }
            catch { }
        });

        var creator = await _context.Users.FindAsync(userId);

        return new DisputeResponse(
            dispute.Id,
            dispute.BookingId,
            booking.Listing.Title,
            dispute.CreatedById,
            $"{creator?.FirstName} {creator?.LastName}",
            dispute.Reason,
            dispute.IsResolved,
            dispute.AdminDecision,
            dispute.CreatedAt,
            dispute.ResolvedAt,
            null
        );
    }

    public async Task<List<DisputeResponse>> GetMyDisputesAsync(Guid userId)
    {
        var list = await _context.Disputes
            .AsNoTracking()
            .Include(d => d.Booking)
                .ThenInclude(b => b.Listing)
            .Include(d => d.CreatedBy)
            .Include(d => d.ResolvedBy)
            .Where(d => d.CreatedById == userId || d.Booking.RenterId == userId || d.Booking.Listing.OwnerId == userId)
            .OrderByDescending(d => d.CreatedAt)
            .ToListAsync();

        return list.Select(MapToResponse).ToList();
    }

    public async Task<List<DisputeResponse>> GetAdminDisputesAsync()
    {
        var list = await _context.Disputes
            .AsNoTracking()
            .Include(d => d.Booking)
                .ThenInclude(b => b.Listing)
            .Include(d => d.CreatedBy)
            .Include(d => d.ResolvedBy)
            .OrderByDescending(d => d.CreatedAt)
            .ToListAsync();

        return list.Select(MapToResponse).ToList();
    }

    public async Task<DisputeResponse> ResolveDisputeAsync(Guid disputeId, Guid adminId, ResolveDisputeRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.AdminDecision))
        {
            throw new ArgumentException("Admin decision notes are required to resolve a dispute.");
        }

        var dispute = await _context.Disputes
            .Include(d => d.Booking)
                .ThenInclude(b => b.Listing)
            .Include(d => d.CreatedBy)
            .Include(d => d.ResolvedBy)
            .FirstOrDefaultAsync(d => d.Id == disputeId);

        if (dispute == null)
        {
            throw new KeyNotFoundException("Dispute record not found.");
        }

        if (dispute.IsResolved)
        {
            throw new InvalidOperationException("This dispute has already been resolved.");
        }

        var admin = await _context.Users.FindAsync(adminId);
        if (admin == null || admin.Role != "Admin")
        {
            throw new UnauthorizedAccessException("Only administrators can resolve disputes.");
        }

        dispute.IsResolved = true;
        dispute.AdminDecision = request.AdminDecision.Trim();
        dispute.ResolvedById = adminId;
        dispute.ResolvedAt = DateTime.UtcNow;

        if (request.RefundRenter)
        {
            dispute.Booking.Status = BookingStatus.Rejected;
        }
        else
        {
            dispute.Booking.Status = BookingStatus.Completed;
        }

        dispute.Booking.UpdatedAt = DateTime.UtcNow;
        await _context.SaveChangesAsync();

        // Notify both parties about resolution
        var renterId = dispute.Booking.RenterId;
        var ownerId = dispute.Booking.Listing.OwnerId;
        _ = Task.Run(async () =>
        {
            try
            {
                var data = new Dictionary<string, string>
                {
                    { "disputeId", dispute.Id.ToString() },
                    { "bookingId", dispute.BookingId.ToString() },
                    { "type", "dispute_resolved" }
                };

                await _notificationService.SendNotificationToUserAsync(
                    renterId,
                    "Dispute Resolved",
                    $"The dispute on {dispute.Booking.Listing.Title} has been resolved by admin.",
                    data);

                await _notificationService.SendNotificationToUserAsync(
                    ownerId,
                    "Dispute Resolved",
                    $"The dispute on {dispute.Booking.Listing.Title} has been resolved by admin.",
                    data);
            }
            catch { }
        });

        return MapToResponse(dispute);
    }

    private static DisputeResponse MapToResponse(Dispute d)
    {
        var resolvedByName = d.ResolvedBy != null 
            ? $"{d.ResolvedBy.FirstName} {d.ResolvedBy.LastName}" 
            : null;

        return new DisputeResponse(
            d.Id,
            d.BookingId,
            d.Booking.Listing.Title,
            d.CreatedById,
            $"{d.CreatedBy.FirstName} {d.CreatedBy.LastName}",
            d.Reason,
            d.IsResolved,
            d.AdminDecision,
            d.CreatedAt,
            d.ResolvedAt,
            resolvedByName
        );
    }
}
