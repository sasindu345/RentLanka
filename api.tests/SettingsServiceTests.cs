using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using RentLanka.Api.Data;
using RentLanka.Api.Models.Requests;
using RentLanka.Api.Services.Implementations;
using Xunit;

namespace RentLanka.Api.Tests;

public class SettingsServiceTests
{
    private DbContextOptions<AppDbContext> CreateInMemoryDatabaseOptions()
    {
        // Use a unique database name per test to avoid state sharing
        return new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(databaseName: Guid.NewGuid().ToString())
            .Options;
    }

    [Fact]
    public async Task GetSettingsAsync_ShouldReturnDefaultSettings_WhenDatabaseIsEmpty()
    {
        // Arrange
        var options = CreateInMemoryDatabaseOptions();
        using var context = new AppDbContext(options);
        var service = new SettingsService(context);

        // Act
        var settings = await service.GetSettingsAsync();

        // Assert
        Assert.NotNull(settings);
        Assert.Equal(0.1000m, settings.CommissionRate);
        Assert.Contains("Photography", settings.CategoriesJson);
    }

    [Fact]
    public async Task UpdateSettingsAsync_ShouldUpdateCommissionRate_WhenValidRateIsProvided()
    {
        // Arrange
        var options = CreateInMemoryDatabaseOptions();
        using var context = new AppDbContext(options);
        var service = new SettingsService(context);

        var request = new UpdateSettingsRequest(
            0.1500m,
            new List<string> { "Electronics", "Camping" }
        );

        // Act
        var updated = await service.UpdateSettingsAsync(request);

        // Assert
        Assert.NotNull(updated);
        Assert.Equal(0.1500m, updated.CommissionRate);
        Assert.Contains("Electronics", updated.CategoriesJson);
    }

    [Fact]
    public async Task UpdateSettingsAsync_ShouldThrowArgumentException_WhenCommissionRateIsInvalid()
    {
        // Arrange
        var options = CreateInMemoryDatabaseOptions();
        using var context = new AppDbContext(options);
        var service = new SettingsService(context);

        var request = new UpdateSettingsRequest(
            1.50m, // Invalid (must be between 0 and 1)
            new List<string>()
        );

        // Act & Assert
        var exception = await Assert.ThrowsAsync<ArgumentException>(() => service.UpdateSettingsAsync(request));
        Assert.Equal("Commission rate must be between 0 and 1.", exception.Message);
    }
}
