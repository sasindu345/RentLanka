using System;
using System.Collections.Generic;
using NetTopologySuite.Geometries;

namespace RentLanka.Api.Models.Entities;

public class Listing
{
    public Guid Id { get; set; }
    public Guid OwnerId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string Category { get; set; } = string.Empty;
    public decimal PricePerDay { get; set; }
    public decimal SecurityDeposit { get; set; }
    public string Rules { get; set; } = string.Empty;
    
    // NetTopologySuite spatial geometry index
    public Point Location { get; set; } = null!; // SRID 4326 (X = Longitude, Y = Latitude)

    public string District { get; set; } = string.Empty;
    public List<string> Images { get; set; } = new();
    public bool IsPaused { get; set; } = false;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAt { get; set; }
}
