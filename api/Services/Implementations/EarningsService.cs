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

public class EarningsService : IEarningsService
{
    private readonly AppDbContext _context;
    private readonly ISettingsService _settingsService;

    public EarningsService(AppDbContext context, ISettingsService settingsService)
    {
        _context = context;
        _settingsService = settingsService;
    }

    public async Task<EarningsResponse> GetHostEarningsAsync(Guid hostId)
    {
        // 1. Get all bookings for listing owned by this host
        var bookings = await _context.Bookings
            .Include(b => b.Listing)
            .AsNoTracking()
            .Where(b => b.Listing.OwnerId == hostId)
            .ToListAsync();

        var settings = await _settingsService.GetSettingsAsync();
        var commissionRate = settings.CommissionRate;

        // 2. Total Earned = (1 - commissionRate) of TotalPrice for Completed bookings
        var completedBookings = bookings.Where(b => b.Status == BookingStatus.Completed);
        var totalEarned = completedBookings.Sum(b => b.TotalPrice) * (1 - commissionRate);

        // 3. Escrowed Balance = (1 - commissionRate) of TotalPrice for Paid and Active bookings
        var escrowedBookings = bookings.Where(b => b.Status == BookingStatus.Paid || b.Status == BookingStatus.Active);
        var escrowedBalance = escrowedBookings.Sum(b => b.TotalPrice) * (1 - commissionRate);

        // 4. Get all payouts for this host
        var payouts = await _context.Payouts
            .Include(p => p.Owner)
            .AsNoTracking()
            .Where(p => p.OwnerId == hostId)
            .OrderByDescending(p => p.CreatedAt)
            .ToListAsync();

        // 5. Available Balance = Total Earned - Sum of non-rejected payouts
        var nonRejectedPayoutsTotal = payouts
            .Where(p => p.Status != PayoutStatus.Rejected)
            .Sum(p => p.Amount);
        
        var availableBalance = Math.Max(0, totalEarned - nonRejectedPayoutsTotal);

        var payoutResponses = payouts.Select(p => new PayoutResponse(
            p.Id,
            p.OwnerId,
            $"{p.Owner.FirstName} {p.Owner.LastName}",
            p.Amount,
            p.BankName,
            p.AccountNumber,
            p.AccountName,
            p.Status.ToString(),
            p.CreatedAt,
            p.UpdatedAt));

        return new EarningsResponse(availableBalance, totalEarned, escrowedBalance, payoutResponses);
    }

    public async Task<(bool Succeeded, string? Error)> RequestPayoutAsync(Guid hostId, PayoutRequest request)
    {
        var user = await _context.Users.FindAsync(hostId);
        if (user == null) return (false, "User not found.");

        if (user.VerificationLevel < VerificationLevel.Level2)
        {
            return (false, "NIC verification (Level 2) is required to request payouts.");
        }

        if (request.Amount <= 0)
        {
            return (false, "Payout amount must be greater than zero.");
        }

        if (string.IsNullOrWhiteSpace(request.BankName) || 
            string.IsNullOrWhiteSpace(request.AccountNumber) || 
            string.IsNullOrWhiteSpace(request.AccountName))
        {
            return (false, "Bank details (Bank Name, Account Number, Account Name) are required.");
        }

        // Calculate available balance
        var hostEarnings = await GetHostEarningsAsync(hostId);
        if (request.Amount > hostEarnings.AvailableBalance)
        {
            return (false, $"Insufficient balance. Your available balance is LKR {hostEarnings.AvailableBalance:N2}.");
        }

        var payout = new Payout
        {
            Id = Guid.NewGuid(),
            OwnerId = hostId,
            Amount = request.Amount,
            BankName = request.BankName.Trim(),
            AccountNumber = request.AccountNumber.Trim(),
            AccountName = request.AccountName.Trim(),
            Status = PayoutStatus.Pending,
            CreatedAt = DateTime.UtcNow
        };

        _context.Payouts.Add(payout);
        await _context.SaveChangesAsync();

        return (true, null);
    }

    public async Task<IEnumerable<PayoutResponse>> GetAllPayoutsAsync()
    {
        var payouts = await _context.Payouts
            .Include(p => p.Owner)
            .AsNoTracking()
            .OrderByDescending(p => p.CreatedAt)
            .ToListAsync();

        return payouts.Select(p => new PayoutResponse(
            p.Id,
            p.OwnerId,
            $"{p.Owner.FirstName} {p.Owner.LastName}",
            p.Amount,
            p.BankName,
            p.AccountNumber,
            p.AccountName,
            p.Status.ToString(),
            p.CreatedAt,
            p.UpdatedAt));
    }

    public async Task<IEnumerable<PaymentResponse>> GetAllPaymentsAsync()
    {
        var payments = await _context.Payments
            .Include(p => p.Booking)
            .ThenInclude(b => b.Listing)
            .Include(p => p.Booking.Renter)
            .AsNoTracking()
            .OrderByDescending(p => p.CreatedAt)
            .ToListAsync();

        return payments.Select(p => new PaymentResponse(
            p.Id,
            p.BookingId,
            p.Booking.Listing.Title,
            $"{p.Booking.Renter.FirstName} {p.Booking.Renter.LastName}",
            p.Amount,
            p.Status.ToString(),
            p.TransactionReference,
            p.CreatedAt));
    }

    public async Task<(bool Succeeded, string? Error)> ApprovePayoutAsync(Guid payoutId)
    {
        var payout = await _context.Payouts.FindAsync(payoutId);
        if (payout == null) return (false, "Payout request not found.");

        if (payout.Status != PayoutStatus.Pending)
        {
            return (false, "Only pending payout requests can be approved.");
        }

        payout.Status = PayoutStatus.Paid;
        payout.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();
        return (true, null);
    }
}
