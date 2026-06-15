using System;
using System.Security.Claims;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using RentLanka.Api.Models.Requests;
using RentLanka.Api.Services.Interfaces;

namespace RentLanka.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ListingsController : ControllerBase
{
    private readonly IListingService _listingService;

    public ListingsController(IListingService listingService)
    {
        _listingService = listingService;
    }

    [Authorize]
    [HttpPost]
    public async Task<IActionResult> CreateListing([FromBody] CreateListingRequest request)
    {
        try
        {
            var userId = GetUserId();
            var response = await _listingService.CreateListingAsync(userId, request);
            return CreatedAtAction(nameof(GetListingById), new { id = response.Id }, response);
        }
        catch (UnauthorizedAccessException ex)
        {
            return Unauthorized(new { Error = ex.Message });
        }
        catch (Exception ex)
        {
            return BadRequest(new { Error = ex.Message });
        }
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetListingById(Guid id)
    {
        var response = await _listingService.GetListingByIdAsync(id);
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
        [FromQuery] double? distanceMeters)
    {
        try
        {
            var results = await _listingService.SearchListingsAsync(query, category, district, lat, lon, distanceMeters);
            return Ok(results);
        }
        catch (Exception ex)
        {
            return BadRequest(new { Error = ex.Message });
        }
    }

    private Guid GetUserId()
    {
        var claimValue = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrEmpty(claimValue))
        {
            throw new UnauthorizedAccessException("User is not authenticated.");
        }
        return Guid.Parse(claimValue);
    }
}
