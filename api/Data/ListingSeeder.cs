using System;
using System.Collections.Generic;
using NetTopologySuite;
using NetTopologySuite.Geometries;
using RentLanka.Api.Models.Entities;

namespace RentLanka.Api.Data;

/// <summary>
/// Provides the set of real-world demo listings used to seed the database.
/// Keep all seed data here — never in controllers or services.
/// </summary>
public static class ListingSeeder
{
    public static List<Listing> GetSeedListings(Guid ownerId)
    {
        var gf = NtsGeometryServices.Instance.CreateGeometryFactory(srid: 4326);

        return new List<Listing>
        {
            new Listing
            {
                Id = Guid.NewGuid(),
                OwnerId = ownerId,
                Title = "Sony Alpha 7 IV Mirrorless Camera",
                Description = "A professional-grade mirrorless camera with a 33MP sensor, perfect for high-quality photography and 4K video recording. Includes 2 batteries and a charger.",
                Category = "Photography",
                PricePerDay = 8000,
                SecurityDeposit = 50000,
                Rules = "Handle with care. Return on time. Any physical damage will be charged to the security deposit.",
                District = "Colombo",
                Location = gf.CreatePoint(new Coordinate(79.8612, 6.9272)),
                Images = new List<string> { "https://images.unsplash.com/photo-1617005082133-548c4dd27f35?q=80&w=600" },
                Status = ListingStatus.Approved,
                CreatedAt = DateTime.UtcNow
            },
            new Listing
            {
                Id = Guid.NewGuid(),
                OwnerId = ownerId,
                Title = "Sigma 24-70mm f/2.8 DG DN Art Lens",
                Description = "High-performance standard zoom lens for Sony E-mount. Perfect for portraits, landscapes, and event photography. Outstanding sharpness throughout the zoom range.",
                Category = "Photography",
                PricePerDay = 4000,
                SecurityDeposit = 20000,
                Rules = "Use protective lens cap when not shooting. Do not touch lens glass.",
                District = "Colombo",
                Location = gf.CreatePoint(new Coordinate(79.8650, 6.9300)),
                Images = new List<string> { "https://images.unsplash.com/photo-1616422285623-13ff0162193c?q=80&w=600" },
                Status = ListingStatus.Approved,
                CreatedAt = DateTime.UtcNow
            },
            new Listing
            {
                Id = Guid.NewGuid(),
                OwnerId = ownerId,
                Title = "Quechua 4-Person Camping Tent",
                Description = "Spacious waterproof camping tent, ideal for weekend trips. Easy to set up and take down. Double-roof design for ventilation and condensation protection.",
                Category = "Camping",
                PricePerDay = 1500,
                SecurityDeposit = 10000,
                Rules = "Return clean and dry. Make sure all poles and pegs are included upon return.",
                District = "Kandy",
                Location = gf.CreatePoint(new Coordinate(80.6350, 7.2906)),
                Images = new List<string> { "https://images.unsplash.com/photo-1510312305653-8ed496efae75?q=80&w=600" },
                Status = ListingStatus.Approved,
                CreatedAt = DateTime.UtcNow
            },
            new Listing
            {
                Id = Guid.NewGuid(),
                OwnerId = ownerId,
                Title = "Deuter Aircontact Lite 50+10 Backpack",
                Description = "A lightweight trekking backpack designed for long-distance hikes and multi-day camping trips. Ergonomic fit and superior load transfer support.",
                Category = "Camping",
                PricePerDay = 1000,
                SecurityDeposit = 8000,
                Rules = "Do not wash in machine. Clean dirt with a damp cloth.",
                District = "Ella",
                Location = gf.CreatePoint(new Coordinate(81.0466, 6.8724)),
                Images = new List<string> { "https://images.unsplash.com/photo-1553062407-98eeb64c6a62?q=80&w=600" },
                Status = ListingStatus.Approved,
                CreatedAt = DateTime.UtcNow
            },
            new Listing
            {
                Id = Guid.NewGuid(),
                OwnerId = ownerId,
                Title = "DJI Mini 3 Pro Drone (with RC Controller)",
                Description = "Ultralight folding camera drone with 4K HDR video capability and 34-min flight time. Perfect for stunning aerial shots. Smart controller screen included.",
                Category = "Photography",
                PricePerDay = 12000,
                SecurityDeposit = 60000,
                Rules = "Ensure CAA rules are followed. Do not fly in rainy or heavy wind conditions.",
                District = "Colombo",
                Location = gf.CreatePoint(new Coordinate(79.8500, 6.9150)),
                Images = new List<string> { "https://images.unsplash.com/photo-1508614589041-895b88991e3e?q=80&w=600" },
                Status = ListingStatus.Approved,
                CreatedAt = DateTime.UtcNow
            },
            new Listing
            {
                Id = Guid.NewGuid(),
                OwnerId = ownerId,
                Title = "Bosch Professional Demolition Jackhammer",
                Description = "Heavy-duty electric breaker for demolition work. High impact rate and demolition performance. Comes with point and flat chisels.",
                Category = "Tools",
                PricePerDay = 3500,
                SecurityDeposit = 15000,
                Rules = "Wear proper safety gear. Use on concrete only. Clean after use.",
                District = "Gampaha",
                Location = gf.CreatePoint(new Coordinate(79.9918, 7.0873)),
                Images = new List<string> { "https://images.unsplash.com/photo-1504148455328-c376907d081c?q=80&w=600" },
                Status = ListingStatus.Approved,
                CreatedAt = DateTime.UtcNow
            },
            new Listing
            {
                Id = Guid.NewGuid(),
                OwnerId = ownerId,
                Title = "JBL PartyBox 310 Portable Bluetooth Speaker",
                Description = "Powerful party speaker with dynamic light shows, deep bass, and 240W of signature sound. Telescopic handle and built-in wheels for easy transport.",
                Category = "Electronics",
                PricePerDay = 5000,
                SecurityDeposit = 30000,
                Rules = "Do not submerge in water. Charge fully before returning.",
                District = "Negombo",
                Location = gf.CreatePoint(new Coordinate(79.8358, 7.2081)),
                Images = new List<string> { "https://images.unsplash.com/photo-1608043152269-423dbba4e7e1?q=80&w=600" },
                Status = ListingStatus.Approved,
                CreatedAt = DateTime.UtcNow
            },
            new Listing
            {
                Id = Guid.NewGuid(),
                OwnerId = ownerId,
                Title = "Epson EH-TW750 Full HD Projector",
                Description = "Brilliant Full HD home theater projector. Perfect for movie nights, sports screenings, and gaming. 3,400 lumens brightness for clear images.",
                Category = "Electronics",
                PricePerDay = 6000,
                SecurityDeposit = 25000,
                Rules = "Do not block the cooling fan. Transport only inside the padded carry bag.",
                District = "Colombo",
                Location = gf.CreatePoint(new Coordinate(79.8700, 6.9400)),
                Images = new List<string> { "https://images.unsplash.com/photo-1535016120720-40c646be5580?q=80&w=600" },
                Status = ListingStatus.Approved,
                CreatedAt = DateTime.UtcNow
            },
            new Listing
            {
                Id = Guid.NewGuid(),
                OwnerId = ownerId,
                Title = "Spalding TF-1000 Professional Basketball",
                Description = "Official size and weight composite leather indoor basketball. Features deep channels and moisture-wicking grip for advanced control.",
                Category = "Sports",
                PricePerDay = 800,
                SecurityDeposit = 5000,
                Rules = "Indoor court use only. Do not use on rough concrete.",
                District = "Colombo",
                Location = gf.CreatePoint(new Coordinate(79.8800, 6.9500)),
                Images = new List<string> { "https://images.unsplash.com/photo-1546519638-68e109498ffc?q=80&w=600" },
                Status = ListingStatus.Approved,
                CreatedAt = DateTime.UtcNow
            },
            new Listing
            {
                Id = Guid.NewGuid(),
                OwnerId = ownerId,
                Title = "High-Pressure Car Washer (2000W)",
                Description = "Powerful electric pressure washer, ideal for cleaning cars, decks, patios, and walls. Includes high-pressure hose, foam nozzle, and spray gun.",
                Category = "Tools",
                PricePerDay = 2000,
                SecurityDeposit = 10000,
                Rules = "Ensure continuous water supply during operation. Do not run dry.",
                District = "Kurunegala",
                Location = gf.CreatePoint(new Coordinate(80.3647, 7.4863)),
                Images = new List<string> { "https://images.unsplash.com/photo-1520607162513-77705c0f0d4a?q=80&w=600" },
                Status = ListingStatus.Approved,
                CreatedAt = DateTime.UtcNow
            },
        };
    }
}
