using System;

namespace RentLanka.Api.Models.Entities;

public class PlatformSetting
{
    public Guid Id { get; set; }
    public decimal CommissionRate { get; set; } = 0.10m; // 10% default
    public string CategoriesJson { get; set; } = "[\"Photography\", \"Tools\", \"Camping\", \"Electronics\", \"Sports\", \"Other\"]";
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}
