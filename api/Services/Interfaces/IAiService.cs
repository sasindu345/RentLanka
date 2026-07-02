using System;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace RentLanka.Api.Services.Interfaces;

public interface IAiService
{
    Task<ListingGenerationResponse> GenerateListingFromImageAsync(string? imageUrl, string? categoryHint);
    Task<List<SemanticSearchResult>> SemanticSearchAsync(string query, List<ListingSearchSummaryDto> listings);
}

public record ListingGenerationResponse(
    string Title,
    string Description,
    string Category,
    decimal SuggestedPricePerDay,
    decimal SuggestedSecurityDeposit
);

public record ListingSearchSummaryDto(
    Guid Id,
    string Title,
    string Description,
    string Category,
    decimal PricePerDay,
    string District
);

public record SemanticSearchResult(
    Guid ListingId,
    double MatchScore,
    string Reason
);
