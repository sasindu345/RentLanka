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

public class ReviewService : IReviewService
{
    private readonly AppDbContext _context;

    public ReviewService(AppDbContext context)
    {
        _context = context;
    }

    public async Task<ReviewResponse> CreateReviewAsync(Guid bookingId, Guid reviewerId, CreateReviewRequest request)
    {
        var booking = await _context.Bookings
            .Include(b => b.Listing)
            .FirstOrDefaultAsync(b => b.Id == bookingId);

        if (booking == null)
        {
            throw new ArgumentException("Booking not found.");
        }

        if (booking.Status != BookingStatus.Completed)
        {
            throw new InvalidOperationException("Reviews can only be submitted for completed bookings.");
        }

        bool isRenter = booking.RenterId == reviewerId;
        bool isOwner = booking.Listing.OwnerId == reviewerId;

        if (!isRenter && !isOwner)
        {
            throw new UnauthorizedAccessException("You are not authorized to review this booking.");
        }

        // Verify user has not reviewed already
        var alreadyReviewed = await _context.Reviews
            .AnyAsync(r => r.BookingId == bookingId && r.ReviewerId == reviewerId);

        if (alreadyReviewed)
        {
            throw new InvalidOperationException("You have already submitted a review for this booking.");
        }

        var reviewer = await _context.Users.FindAsync(reviewerId);
        if (reviewer == null)
        {
            throw new ArgumentException("Reviewer not found.");
        }

        Guid targetUserId = isRenter ? booking.Listing.OwnerId : booking.RenterId;

        var review = new Review
        {
            Id = Guid.NewGuid(),
            BookingId = bookingId,
            ReviewerId = reviewerId,
            TargetUserId = targetUserId,
            Rating = request.Rating,
            Comment = request.Comment ?? string.Empty,
            IsRenterReview = isRenter,
            CreatedAt = DateTime.UtcNow
        };

        _context.Reviews.Add(review);
        await _context.SaveChangesAsync();

        return new ReviewResponse(
            review.Id,
            review.BookingId,
            review.ReviewerId,
            $"{reviewer.FirstName} {reviewer.LastName}",
            review.TargetUserId,
            review.Rating,
            review.Comment,
            review.IsRenterReview,
            review.CreatedAt
        );
    }

    public async Task<List<ReviewResponse>> GetReviewsByTargetUserAsync(Guid userId)
    {
        return await _context.Reviews
            .AsNoTracking()
            .Where(r => r.TargetUserId == userId)
            .Include(r => r.Reviewer)
            .OrderByDescending(r => r.CreatedAt)
            .Select(r => new ReviewResponse(
                r.Id,
                r.BookingId,
                r.ReviewerId,
                $"{r.Reviewer.FirstName} {r.Reviewer.LastName}",
                r.TargetUserId,
                r.Rating,
                r.Comment,
                r.IsRenterReview,
                r.CreatedAt
            ))
            .ToListAsync();
    }

    public async Task<List<ReviewResponse>> GetReviewsByListingAsync(Guid listingId)
    {
        return await _context.Reviews
            .AsNoTracking()
            .Where(r => r.Booking.ListingId == listingId && r.IsRenterReview)
            .Include(r => r.Reviewer)
            .OrderByDescending(r => r.CreatedAt)
            .Select(r => new ReviewResponse(
                r.Id,
                r.BookingId,
                r.ReviewerId,
                $"{r.Reviewer.FirstName} {r.Reviewer.LastName}",
                r.TargetUserId,
                r.Rating,
                r.Comment,
                r.IsRenterReview,
                r.CreatedAt
            ))
            .ToListAsync();
    }

    public async Task<List<ReviewResponse>> GetReviewsByBookingAsync(Guid bookingId)
    {
        return await _context.Reviews
            .AsNoTracking()
            .Where(r => r.BookingId == bookingId)
            .Include(r => r.Reviewer)
            .Select(r => new ReviewResponse(
                r.Id,
                r.BookingId,
                r.ReviewerId,
                $"{r.Reviewer.FirstName} {r.Reviewer.LastName}",
                r.TargetUserId,
                r.Rating,
                r.Comment,
                r.IsRenterReview,
                r.CreatedAt
            ))
            .ToListAsync();
    }

    public async Task<double> GetAverageUserRatingAsync(Guid userId)
    {
        var ratings = await _context.Reviews
            .AsNoTracking()
            .Where(r => r.TargetUserId == userId)
            .Select(r => r.Rating)
            .ToListAsync();

        return ratings.Any() ? Math.Round(ratings.Average(), 1) : 0.0;
    }

    public async Task<double> GetAverageListingRatingAsync(Guid listingId)
    {
        var ratings = await _context.Reviews
            .AsNoTracking()
            .Where(r => r.Booking.ListingId == listingId && r.IsRenterReview)
            .Select(r => r.Rating)
            .ToListAsync();

        return ratings.Any() ? Math.Round(ratings.Average(), 1) : 0.0;
    }
}
