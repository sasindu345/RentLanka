using System;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using RentLanka.Api.Models.Requests;
using RentLanka.Api.Services.Interfaces;

namespace RentLanka.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ListingsController : AuthorizedControllerBase
{
    private readonly IListingService _listingService;
    private readonly IBookingService _bookingService;

    public ListingsController(IListingService listingService, IBookingService bookingService)
    {
        _listingService = listingService;
        _bookingService = bookingService;
    }

    [Authorize]
    [HttpPost]
    public async Task<IActionResult> CreateListing([FromBody] CreateListingRequest request)
    {
        try
        {
            var response = await _listingService.CreateListingAsync(GetUserId(), request);
            return CreatedAtAction(nameof(GetListingById), new { id = response.Id }, response);
        }
        catch (UnauthorizedAccessException ex)
        {
            return Unauthorized(new { Error = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { Error = ex.Message });
        }
        catch (Exception ex)
        {
            return BadRequest(new { Error = ex.Message });
        }
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetListingById(Guid id)
    {
        Guid? ownerId = null;
        if (User.Identity?.IsAuthenticated == true)
        {
            try
            {
                ownerId = GetUserId();
            }
            catch (UnauthorizedAccessException)
            {
                ownerId = null;
            }
        }

        var response = await _listingService.GetListingByIdAsync(id, ownerId: ownerId);
        if (response == null)
        {
            return NotFound(new { Error = "Listing not found." });
        }

        return Ok(response);
    }

    [HttpGet("search")]
    public async Task<IActionResult> SearchListings(
        [FromQuery] string? query,
        [FromQuery] string? category,
        [FromQuery] string? district,
        [FromQuery] double? lat,
        [FromQuery] double? lon,
        [FromQuery] double? distanceMeters,
        [FromQuery] decimal? minPrice,
        [FromQuery] decimal? maxPrice,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        [FromQuery] string? sortBy = "newest")
    {
        try
        {
            var results = await _listingService.SearchListingsAsync(
                query, category, district, lat, lon, distanceMeters,
                minPrice, maxPrice, page, pageSize, sortBy);
            return Ok(results);
        }
        catch (Exception ex)
        {
            return BadRequest(new { Error = ex.Message });
        }
    }

    [Authorize]
    [HttpGet("mine")]
    public async Task<IActionResult> GetMyListings()
    {
        var results = await _listingService.GetMyListingsAsync(GetUserId());
        return Ok(results);
    }

    [Authorize]
    [HttpPut("{id:guid}")]
    public async Task<IActionResult> UpdateListing(Guid id, [FromBody] UpdateListingRequest request)
    {
        var (succeeded, listing, error) = await _listingService.UpdateListingAsync(GetUserId(), id, request);
        if (!succeeded)
        {
            return error == "Listing not found."
                ? NotFound(new { Error = error })
                : BadRequest(new { Error = error });
        }

        return Ok(listing);
    }

    [Authorize]
    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> DeleteListing(Guid id)
    {
        var (succeeded, error) = await _listingService.DeleteListingAsync(GetUserId(), id);
        if (!succeeded)
        {
            return error == "Listing not found."
                ? NotFound(new { Error = error })
                : BadRequest(new { Error = error });
        }

        return NoContent();
    }

    [Authorize]
    [HttpPatch("{id:guid}/pause")]
    public async Task<IActionResult> TogglePause(Guid id)
    {
        var (succeeded, listing, error) = await _listingService.TogglePauseAsync(GetUserId(), id);
        if (!succeeded)
        {
            return error == "Listing not found."
                ? NotFound(new { Error = error })
                : BadRequest(new { Error = error });
        }

        return Ok(listing);
    }

    [HttpGet("{id:guid}/availability")]
    public async Task<IActionResult> GetListingAvailability(Guid id)
    {
        var blocks = await _bookingService.GetListingAvailabilityAsync(id);
        return Ok(blocks);
    }

    [Authorize]
    [HttpPost("{id:guid}/availability/block")]
    public async Task<IActionResult> CreateManualBlock(Guid id, [FromBody] ManualBlockRequest request)
    {
        var (succeeded, error) = await _bookingService.CreateManualBlockAsync(GetUserId(), id, request.StartDate, request.EndDate);
        if (!succeeded)
        {
            return error == "Unauthorized" ? Forbid() : BadRequest(new { Error = error });
        }

        return NoContent();
    }

    [Authorize]
    [HttpDelete("{id:guid}/availability/block/{blockId:guid}")]
    public async Task<IActionResult> DeleteManualBlock(Guid id, Guid blockId)
    {
        var (succeeded, error) = await _bookingService.DeleteManualBlockAsync(GetUserId(), blockId);
        if (!succeeded)
        {
            return error == "Unauthorized" ? Forbid() : BadRequest(new { Error = error });
        }

        return NoContent();
    }
}
