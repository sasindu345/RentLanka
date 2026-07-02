using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using RentLanka.Api.Data;
using RentLanka.Api.Models.DTOs;
using RentLanka.Api.Models.Entities;
using RentLanka.Api.Services.Interfaces;

namespace RentLanka.Api.Controllers;

[ApiController]
[Route("api/ai")]
public class AiController : ControllerBase
{
    private readonly IAiService _aiService;
    private readonly AppDbContext _context;

    public AiController(IAiService aiService, AppDbContext context)
    {
        _aiService = aiService;
        _context = context;
    }

    [Authorize]
    [HttpPost("generate-listing")]
    public async Task<IActionResult> GenerateListing([FromBody] GenerateListingRequest request)
    {
        if (string.IsNullOrEmpty(request.ImageUrl) && string.IsNullOrEmpty(request.CategoryHint))
        {
            return BadRequest(new { Error = "Either ImageUrl or CategoryHint must be provided." });
        }

        try
        {
            var result = await _aiService.GenerateListingFromImageAsync(request.ImageUrl, request.CategoryHint);
            return Ok(result);
        }
        catch (Exception ex)
        {
            return BadRequest(new { Error = ex.Message });
        }
    }

    [AllowAnonymous]
    [HttpGet("search")]
    public async Task<IActionResult> Search([FromQuery] string query)
    {
        if (string.IsNullOrEmpty(query))
        {
            return BadRequest(new { Error = "Search query is required." });
        }

        try
        {
            // 1. Fetch active approved listings summaries from database
            var listingsSummary = await _context.Listings
                .Where(l => !l.IsDeleted && !l.IsPaused && l.Status == ListingStatus.Approved)
                .Select(l => new ListingSearchSummaryDto(
                    l.Id,
                    l.Title,
                    l.Description,
                    l.Category,
                    l.PricePerDay,
                    l.District
                ))
                .ToListAsync();

            // 2. Perform AI re-ranking and semantic match filtering
            var aiMatches = await _aiService.SemanticSearchAsync(query, listingsSummary);

            if (aiMatches == null || aiMatches.Count == 0)
            {
                return Ok(new List<AiSearchListingResponse>());
            }

            // 3. Fetch detailed listings matching AI matched IDs
            var matchedIds = aiMatches.Select(m => m.ListingId).ToList();
            var detailedListings = await _context.Listings
                .Include(l => l.Owner)
                .Where(l => matchedIds.Contains(l.Id))
                .ToListAsync();

            // 4. Map to custom AI search response, sorted by score descending
            var response = aiMatches
                .Select(match =>
                {
                    var listing = detailedListings.FirstOrDefault(l => l.Id == match.ListingId);
                    if (listing == null) return null;

                    var ownerSummary = new OwnerSummary(
                        listing.Owner.Id,
                        listing.Owner.FirstName,
                        listing.Owner.LastName,
                        listing.Owner.AvatarUrl,
                        listing.Owner.IsTrustedUser,
                        (int)listing.Owner.VerificationLevel
                    );

                    return new AiSearchListingResponse(
                        listing.Id,
                        listing.Title,
                        listing.Description,
                        listing.Category,
                        listing.PricePerDay,
                        listing.SecurityDeposit,
                        listing.District,
                        listing.Images,
                        match.MatchScore,
                        match.Reason,
                        ownerSummary
                    );
                })
                .Where(res => res != null)
                .OrderByDescending(res => res!.MatchScore)
                .ToList();

            return Ok(response);
        }
        catch (Exception ex)
        {
            return BadRequest(new { Error = ex.Message });
        }
    }
}

public record GenerateListingRequest(string? ImageUrl, string? CategoryHint);

public record AiSearchListingResponse(
    Guid Id,
    string Title,
    string Description,
    string Category,
    decimal PricePerDay,
    decimal SecurityDeposit,
    string District,
    List<string> Images,
    double MatchScore,
    string MatchReason,
    OwnerSummary Owner
);
