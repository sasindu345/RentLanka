using System;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using RentLanka.Api.Models.Requests;
using RentLanka.Api.Services.Interfaces;

namespace RentLanka.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ReviewsController : AuthorizedControllerBase
{
    private readonly IReviewService _reviewService;

    public ReviewsController(IReviewService reviewService)
    {
        _reviewService = reviewService;
    }

    [HttpPost("bookings/{bookingId}")]
    [Authorize]
    public async Task<IActionResult> CreateReview(Guid bookingId, [FromBody] CreateReviewRequest request)
    {
        try
        {
            var review = await _reviewService.CreateReviewAsync(bookingId, GetUserId(), request);
            return Ok(review);
        }
        catch (ArgumentException ex)
        {
            return NotFound(new { Error = ex.Message });
        }
        catch (UnauthorizedAccessException)
        {
            return Forbid();
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { Error = ex.Message });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { Error = "An unexpected error occurred: " + ex.Message });
        }
    }

    [HttpGet("users/{userId}")]
    [AllowAnonymous]
    public async Task<IActionResult> GetUserReviews(Guid userId)
    {
        var reviews = await _reviewService.GetReviewsByTargetUserAsync(userId);
        return Ok(reviews);
    }

    [HttpGet("listings/{listingId}")]
    [AllowAnonymous]
    public async Task<IActionResult> GetListingReviews(Guid listingId)
    {
        var reviews = await _reviewService.GetReviewsByListingAsync(listingId);
        return Ok(reviews);
    }

    [HttpGet("bookings/{bookingId}")]
    [AllowAnonymous]
    public async Task<IActionResult> GetBookingReviews(Guid bookingId)
    {
        var reviews = await _reviewService.GetReviewsByBookingAsync(bookingId);
        return Ok(reviews);
    }

    [HttpGet("users/{userId}/average")]
    [AllowAnonymous]
    public async Task<IActionResult> GetUserAverageRating(Guid userId)
    {
        var average = await _reviewService.GetAverageUserRatingAsync(userId);
        return Ok(new { AverageRating = average });
    }

    [HttpGet("listings/{listingId}/average")]
    [AllowAnonymous]
    public async Task<IActionResult> GetListingAverageRating(Guid listingId)
    {
        var average = await _reviewService.GetAverageListingRatingAsync(listingId);
        return Ok(new { AverageRating = average });
    }
}
