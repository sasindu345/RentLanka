using System;
using System.Text.Json;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using RentLanka.Api.Data;
using RentLanka.Api.Models.Entities;
using RentLanka.Api.Models.Requests;
using RentLanka.Api.Services.Interfaces;

namespace RentLanka.Api.Services.Implementations;

public class SettingsService : ISettingsService
{
    private readonly AppDbContext _context;
    private static readonly Guid SettingsId = Guid.Parse("00000000-0000-0000-0000-000000000001");

    public SettingsService(AppDbContext context)
    {
        _context = context;
    }

    public async Task<PlatformSetting> GetSettingsAsync()
    {
        var settings = await _context.PlatformSettings.FirstOrDefaultAsync(s => s.Id == SettingsId);
        if (settings == null)
        {
            // Fallback default in case seeding failed or row was deleted
            settings = new PlatformSetting
            {
                Id = SettingsId,
                CommissionRate = 0.1000m,
                CategoriesJson = "[\"Photography\", \"Tools\", \"Camping\", \"Electronics\", \"Sports\", \"Other\"]"
            };
            _context.PlatformSettings.Add(settings);
            await _context.SaveChangesAsync();
        }
        return settings;
    }

    public async Task<PlatformSetting> UpdateSettingsAsync(UpdateSettingsRequest request)
    {
        var settings = await GetSettingsAsync();

        if (request.CommissionRate < 0 || request.CommissionRate > 1)
        {
            throw new ArgumentException("Commission rate must be between 0 and 1.");
        }

        settings.CommissionRate = request.CommissionRate;
        if (request.Categories != null && request.Categories.Count > 0)
        {
            settings.CategoriesJson = JsonSerializer.Serialize(request.Categories);
        }
        
        settings.UpdatedAt = DateTime.UtcNow;
        await _context.SaveChangesAsync();
        return settings;
    }
}
