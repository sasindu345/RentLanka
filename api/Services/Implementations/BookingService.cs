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

public class BookingService : IBookingService
{
    private readonly AppDbContext _context;
    private readonly INotificationService _notificationService;

    public BookingService(AppDbContext context, INotificationService notificationService)
    {
        _context = context;
        _notificationService = notificationService;
    }

    public async Task<(bool Succeeded, BookingResponse? Booking, string? Error)> CreateBookingAsync(Guid renterId, BookingRequest request)
    {
        var user = await _context.Users.FindAsync(renterId);
        if (user == null) return (false, null, "User not found.");

        if (user.Role == "Owner")
        {
            return (false, null, "Owner accounts are not allowed to rent or request bookings.");
        }

        // Renter KYC requirement bypassed as per request (only owner needs KYC verification).

        var listing = await _context.Listings.Include(l => l.Owner).FirstOrDefaultAsync(l => l.Id == request.ListingId && !l.IsDeleted);
        if (listing == null) return (false, null, "Listing not found.");

        if (listing.Owner.VerificationLevel < VerificationLevel.Level2)
        {
            return (false, null, "The owner of this listing must have KYC verification completed (Level 2) to accept bookings.");
        }

        if (listing.OwnerId == renterId)
        {
            return (false, null, "You cannot book your own gear.");
        }

        var start = request.StartDate.ToUniversalTime();
        var end = request.EndDate.ToUniversalTime();

        if (start.Date < DateTime.UtcNow.Date)
        {
            return (false, null, "Start date cannot be in the past.");
        }

        var days = (int)Math.Ceiling((end - start).TotalDays);
        if (days <= 0)
        {
            return (false, null, "End date must be after start date.");
        }

        // Overlap check
        var isBlocked = await _context.AvailabilityBlocks.AnyAsync(ab =>
            ab.ListingId == request.ListingId &&
            ((start >= ab.StartDate && start < ab.EndDate) ||
             (end > ab.StartDate && end <= ab.EndDate) ||
             (start <= ab.StartDate && end >= ab.EndDate)));

        if (isBlocked)
        {
            return (false, null, "Requested dates overlap with an existing booking or block.");
        }

        var strategy = _context.Database.CreateExecutionStrategy();
        try
        {
            return await strategy.ExecuteAsync(async () =>
            {
                using var transaction = await _context.Database.BeginTransactionAsync();
                try
                {
                    // Check if duplicate request was already processed
                    var existingBooking = await _context.Bookings.FirstOrDefaultAsync(b =>
                        b.RenterId == renterId &&
                        b.ListingId == listing.Id &&
                        b.StartDate == start &&
                        b.EndDate == end);

                    if (existingBooking != null)
                    {
                        return (true, MapToResponse(existingBooking, listing, user), (string)null);
                    }

                    var totalPrice = listing.PricePerDay * days;
                    var securityDeposit = listing.SecurityDeposit;

                    var booking = new Booking
                    {
                        Id = Guid.NewGuid(),
                        ListingId = listing.Id,
                        RenterId = renterId,
                        StartDate = start,
                        EndDate = end,
                        TotalPrice = totalPrice,
                        SecurityDeposit = securityDeposit,
                        Status = BookingStatus.Pending,
                        RenterAgreementSigned = true,
                        OwnerAgreementSigned = false,
                        CreatedAt = DateTime.UtcNow
                    };

                    _context.Bookings.Add(booking);

                    // Block these dates
                    var block = new AvailabilityBlock
                    {
                        Id = Guid.NewGuid(),
                        ListingId = listing.Id,
                        StartDate = start,
                        EndDate = end,
                        Type = AvailabilityBlockType.Booking,
                        BookingId = booking.Id,
                        CreatedAt = DateTime.UtcNow
                    };

                    _context.AvailabilityBlocks.Add(block);

                    await _context.SaveChangesAsync();
                    await transaction.CommitAsync();

                    // Notify owner of new booking request
                    _ = Task.Run(async () =>
                    {
                        try
                        {
                            await _notificationService.SendNotificationToUserAsync(
                                listing.OwnerId,
                                "New Booking Request",
                                $"You have a new request for your {listing.Title}.",
                                new Dictionary<string, string>
                                {
                                    { "bookingId", booking.Id.ToString() },
                                    { "listingId", listing.Id.ToString() },
                                    { "type", "booking_request" }
                                });
                        }
                        catch { }
                    });

                    return (true, MapToResponse(booking, listing, user), (string)null);
                }
                catch
                {
                    await transaction.RollbackAsync();
                    throw;
                }
            });
        }
        catch (Exception ex)
        {
            return (false, null, ex.Message);
        }
    }

    public async Task<BookingResponse?> GetBookingByIdAsync(Guid bookingId, Guid userId)
    {
        var booking = await _context.Bookings
            .Include(b => b.Renter)
            .Include(b => b.Listing)
            .ThenInclude(l => l.Owner)
            .AsNoTracking()
            .FirstOrDefaultAsync(b => b.Id == bookingId);

        if (booking == null) return null;

        // Check ownership
        if (booking.RenterId != userId && booking.Listing.OwnerId != userId)
        {
            return null;
        }

        return MapToResponse(booking, booking.Listing, booking.Renter);
    }

    public async Task<IEnumerable<BookingResponse>> GetRenterBookingsAsync(Guid renterId)
    {
        var bookings = await _context.Bookings
            .Include(b => b.Renter)
            .Include(b => b.Listing)
            .ThenInclude(l => l.Owner)
            .AsNoTracking()
            .Where(b => b.RenterId == renterId)
            .OrderByDescending(b => b.CreatedAt)
            .ToListAsync();

        return bookings.Select(b => MapToResponse(b, b.Listing, b.Renter));
    }

    public async Task<IEnumerable<BookingResponse>> GetOwnerBookingsAsync(Guid ownerId)
    {
        var bookings = await _context.Bookings
            .Include(b => b.Renter)
            .Include(b => b.Listing)
            .ThenInclude(l => l.Owner)
            .AsNoTracking()
            .Where(b => b.Listing.OwnerId == ownerId)
            .OrderByDescending(b => b.CreatedAt)
            .ToListAsync();

        return bookings.Select(b => MapToResponse(b, b.Listing, b.Renter));
    }

    public async Task<(bool Succeeded, string? Error)> ApproveBookingAsync(Guid ownerId, Guid bookingId)
    {
        var booking = await _context.Bookings
            .Include(b => b.Listing)
            .FirstOrDefaultAsync(b => b.Id == bookingId);

        if (booking == null) return (false, "Booking not found.");
        if (booking.Listing.OwnerId != ownerId) return (false, "Unauthorized.");
        if (booking.Status != BookingStatus.Pending) return (false, "Only pending bookings can be approved.");

        booking.Status = BookingStatus.Approved;
        booking.OwnerAgreementSigned = true;
        booking.UpdatedAt = DateTime.UtcNow;
        await _context.SaveChangesAsync();

        _ = Task.Run(async () =>
        {
            try
            {
                await _notificationService.SendNotificationToUserAsync(
                    booking.RenterId,
                    "Booking Approved",
                    $"Your booking request for {booking.Listing.Title} has been approved. Please proceed to payment.",
                    new Dictionary<string, string>
                    {
                        { "bookingId", booking.Id.ToString() },
                        { "listingId", booking.ListingId.ToString() },
                        { "type", "booking_approved" }
                    });
            }
            catch { }
        });

        return (true, null);
    }

    public async Task<(bool Succeeded, string? Error)> RejectBookingAsync(Guid ownerId, Guid bookingId)
    {
        var strategy = _context.Database.CreateExecutionStrategy();
        try
        {
            return await strategy.ExecuteAsync(async () =>
            {
                using var transaction = await _context.Database.BeginTransactionAsync();
                try
                {
                    var booking = await _context.Bookings
                        .Include(b => b.Listing)
                        .FirstOrDefaultAsync(b => b.Id == bookingId);

                    if (booking == null) return (false, "Booking not found.");
                    if (booking.Listing.OwnerId != ownerId) return (false, "Unauthorized.");
                    if (booking.Status != BookingStatus.Pending) return (false, "Only pending bookings can be rejected.");

                    booking.Status = BookingStatus.Rejected;
                    booking.UpdatedAt = DateTime.UtcNow;

                    // Remove availability block
                    var block = await _context.AvailabilityBlocks.FirstOrDefaultAsync(ab => ab.BookingId == bookingId);
                    if (block != null)
                    {
                        _context.AvailabilityBlocks.Remove(block);
                    }

                    await _context.SaveChangesAsync();
                    await transaction.CommitAsync();

                    _ = Task.Run(async () =>
                    {
                        try
                        {
                            await _notificationService.SendNotificationToUserAsync(
                                booking.RenterId,
                                "Booking Rejected",
                                $"Your booking request for {booking.Listing.Title} was rejected.",
                                new Dictionary<string, string>
                                {
                                    { "bookingId", booking.Id.ToString() },
                                    { "listingId", booking.ListingId.ToString() },
                                    { "type", "booking_rejected" }
                                });
                        }
                        catch { }
                    });

                    return (true, (string?)null);
                }
                catch
                {
                    await transaction.RollbackAsync();
                    throw;
                }
            });
        }
        catch (Exception ex)
        {
            return (false, ex.Message);
        }
    }

    public async Task<(bool Succeeded, string? Error)> PayBookingAsync(Guid renterId, Guid bookingId)
    {
        var booking = await _context.Bookings
            .Include(b => b.Listing)
            .FirstOrDefaultAsync(b => b.Id == bookingId);

        if (booking == null) return (false, "Booking not found.");
        if (booking.RenterId != renterId) return (false, "Unauthorized.");
        if (booking.Status != BookingStatus.Approved) return (false, "Booking must be approved before paying.");

        booking.Status = BookingStatus.Paid;
        booking.UpdatedAt = DateTime.UtcNow;

        var payment = new Payment
        {
            Id = Guid.NewGuid(),
            BookingId = bookingId,
            Amount = booking.TotalPrice + booking.SecurityDeposit,
            Status = PaymentStatus.Authorized,
            TransactionReference = $"MOCK_PAYHERE_AUTH_{Guid.NewGuid():N}",
            CreatedAt = DateTime.UtcNow
        };

        _context.Payments.Add(payment);
        await _context.SaveChangesAsync();

        _ = Task.Run(async () =>
        {
            try
            {
                await _notificationService.SendNotificationToUserAsync(
                    booking.Listing.OwnerId,
                    "Booking Paid",
                    $"Payment received for {booking.Listing.Title}. Prepare the gear for handover.",
                    new Dictionary<string, string>
                    {
                        { "bookingId", booking.Id.ToString() },
                        { "listingId", booking.ListingId.ToString() },
                        { "type", "booking_paid" }
                    });
            }
            catch { }
        });

        return (true, null);
    }

    public async Task<(bool Succeeded, string? Error)> HandoverBookingAsync(Guid renterId, Guid bookingId)
    {
        var booking = await _context.Bookings
            .Include(b => b.Listing)
            .FirstOrDefaultAsync(b => b.Id == bookingId);

        if (booking == null) return (false, "Booking not found.");
        if (booking.RenterId != renterId) return (false, "Unauthorized.");
        if (booking.Status != BookingStatus.Paid) return (false, "Booking must be paid before confirming handover.");

        booking.Status = BookingStatus.Active;
        booking.UpdatedAt = DateTime.UtcNow;

        // Capture payment
        var payment = await _context.Payments.FirstOrDefaultAsync(p => p.BookingId == bookingId);
        if (payment != null)
        {
            payment.Status = PaymentStatus.Captured;
        }

        await _context.SaveChangesAsync();

        _ = Task.Run(async () =>
        {
            try
            {
                await _notificationService.SendNotificationToUserAsync(
                    booking.Listing.OwnerId,
                    "Gear Handover Confirmed",
                    $"The renter confirmed handover of {booking.Listing.Title}. The booking is now active.",
                    new Dictionary<string, string>
                    {
                        { "bookingId", booking.Id.ToString() },
                        { "listingId", booking.ListingId.ToString() },
                        { "type", "booking_handover" }
                    });
            }
            catch { }
        });

        return (true, null);
    }

    public async Task<(bool Succeeded, string? Error)> ReturnBookingAsync(Guid ownerId, Guid bookingId)
    {
        var booking = await _context.Bookings
            .Include(b => b.Listing)
            .FirstOrDefaultAsync(b => b.Id == bookingId);

        if (booking == null) return (false, "Booking not found.");
        if (booking.Listing.OwnerId != ownerId) return (false, "Unauthorized.");
        if (booking.Status != BookingStatus.Active) return (false, "Booking must be active before return.");

        booking.Status = BookingStatus.Completed;
        booking.UpdatedAt = DateTime.UtcNow;

        // Release deposit (update payment status)
        var payment = await _context.Payments.FirstOrDefaultAsync(p => p.BookingId == bookingId);
        if (payment != null)
        {
            payment.Status = PaymentStatus.Released;
        }

        await _context.SaveChangesAsync();

        _ = Task.Run(async () =>
        {
            try
            {
                await _notificationService.SendNotificationToUserAsync(
                    booking.RenterId,
                    "Gear Return Confirmed",
                    $"Return of {booking.Listing.Title} was confirmed. Security deposit will be processed.",
                    new Dictionary<string, string>
                    {
                        { "bookingId", booking.Id.ToString() },
                        { "listingId", booking.ListingId.ToString() },
                        { "type", "booking_returned" }
                    });
            }
            catch { }
        });

        return (true, null);
    }

    public async Task<IEnumerable<AvailabilityBlockResponse>> GetListingAvailabilityAsync(Guid listingId)
    {
        var blocks = await _context.AvailabilityBlocks
            .AsNoTracking()
            .Where(ab => ab.ListingId == listingId)
            .OrderBy(ab => ab.StartDate)
            .ToListAsync();

        return blocks.Select(ab => new AvailabilityBlockResponse(
            ab.Id,
            ab.ListingId,
            ab.StartDate,
            ab.EndDate,
            ab.Type.ToString(),
            ab.BookingId));
    }

    public async Task<(bool Succeeded, string? Error)> CreateManualBlockAsync(Guid ownerId, Guid listingId, DateTime start, DateTime end)
    {
        var listing = await _context.Listings.FirstOrDefaultAsync(l => l.Id == listingId && !l.IsDeleted);
        if (listing == null) return (false, "Listing not found.");
        if (listing.OwnerId != ownerId) return (false, "Unauthorized.");

        var blockStart = start.ToUniversalTime();
        var blockEnd = end.ToUniversalTime();

        if (blockEnd <= blockStart) return (false, "End date must be after start date.");

        // Overlap check
        var isBlocked = await _context.AvailabilityBlocks.AnyAsync(ab =>
            ab.ListingId == listingId &&
            ((blockStart >= ab.StartDate && blockStart < ab.EndDate) ||
             (blockEnd > ab.StartDate && blockEnd <= ab.EndDate) ||
             (blockStart <= ab.StartDate && blockEnd >= ab.EndDate)));

        if (isBlocked)
        {
            return (false, "Requested range overlaps with an existing booking or block.");
        }

        var block = new AvailabilityBlock
        {
            Id = Guid.NewGuid(),
            ListingId = listingId,
            StartDate = blockStart,
            EndDate = blockEnd,
            Type = AvailabilityBlockType.Manual,
            CreatedAt = DateTime.UtcNow
        };

        _context.AvailabilityBlocks.Add(block);
        await _context.SaveChangesAsync();

        return (true, null);
    }

    public async Task<(bool Succeeded, string? Error)> DeleteManualBlockAsync(Guid ownerId, Guid blockId)
    {
        var block = await _context.AvailabilityBlocks
            .Include(ab => ab.Listing)
            .FirstOrDefaultAsync(ab => ab.Id == blockId);

        if (block == null) return (false, "Block not found.");
        if (block.Listing.OwnerId != ownerId) return (false, "Unauthorized.");
        if (block.Type != AvailabilityBlockType.Manual)
        {
            return (false, "Cannot delete booking blocks directly. Reject or cancel the booking instead.");
        }

        _context.AvailabilityBlocks.Remove(block);
        await _context.SaveChangesAsync();

        return (true, null);
    }

    public async Task<IEnumerable<BookingResponse>> GetAllBookingsAsync()
    {
        var bookings = await _context.Bookings
            .Include(b => b.Renter)
            .Include(b => b.Listing)
            .ThenInclude(l => l.Owner)
            .AsNoTracking()
            .OrderByDescending(b => b.CreatedAt)
            .ToListAsync();

        return bookings.Select(b => MapToResponse(b, b.Listing, b.Renter));
    }

    private static BookingResponse MapToResponse(Booking booking, Listing listing, User renter)
    {
        var listingImage = listing.Images != null && listing.Images.Count > 0 ? listing.Images[0] : null;
        return new BookingResponse(
            booking.Id,
            booking.ListingId,
            listing.Title,
            listingImage,
            booking.RenterId,
            $"{renter.FirstName} {renter.LastName}",
            listing.OwnerId,
            listing.Owner != null ? $"{listing.Owner.FirstName} {listing.Owner.LastName}" : "Unknown Owner",
            booking.StartDate,
            booking.EndDate,
            booking.TotalPrice,
            booking.SecurityDeposit,
            booking.Status.ToString(),
            booking.RenterAgreementSigned,
            booking.OwnerAgreementSigned,
            booking.CreatedAt,
            booking.UpdatedAt);
    }
}
