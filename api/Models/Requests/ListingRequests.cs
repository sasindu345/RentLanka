using System.Collections.Generic;

namespace RentLanka.Api.Models.Requests;

public record CreateListingRequest(
    string Title,
    string Description,
    string Category,
    decimal PricePerDay,
    decimal SecurityDeposit,
    string Rules,
    double Latitude,
    double Longitude,
    string District,
    List<string> Images);
