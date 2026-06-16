using System;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using RentLanka.Api.Services.Interfaces;

namespace RentLanka.Api.Controllers;

[Authorize]
[ApiController]
[Route("api/wishlist")]
public class WishlistController : AuthorizedControllerBase
{
    private readonly IWishlistService _wishlistService;

    public WishlistController(IWishlistService wishlistService)
    {
        _wishlistService = wishlistService;
    }

    [HttpGet]
    public async Task<IActionResult> GetWishlist([FromQuery] int page = 1, [FromQuery] int pageSize = 20)
    {
        var result = await _wishlistService.GetWishlistAsync(GetUserId(), page, pageSize);
        return Ok(result);
    }

    [HttpPost("{listingId:guid}")]
    public async Task<IActionResult> AddToWishlist(Guid listingId)
    {
        var (succeeded, error) = await _wishlistService.AddToWishlistAsync(GetUserId(), listingId);
        if (!succeeded)
        {
            return BadRequest(new { Error = error });
        }

        return Ok(new { Message = "Listing saved to wishlist." });
    }

    [HttpDelete("{listingId:guid}")]
    public async Task<IActionResult> RemoveFromWishlist(Guid listingId)
    {
        var (succeeded, error) = await _wishlistService.RemoveFromWishlistAsync(GetUserId(), listingId);
        if (!succeeded)
        {
            return NotFound(new { Error = error });
        }

        return NoContent();
    }
}
