using System;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using RentLanka.Api.Data;
using RentLanka.Api.Models.Entities;
using RentLanka.Api.Services.Implementations;
using Xunit;
using BC = BCrypt.Net.BCrypt;

namespace RentLanka.Api.Tests;

public class IdentityServiceTests
{
    private DbContextOptions<AppDbContext> CreateInMemoryDatabaseOptions()
    {
        return new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(databaseName: Guid.NewGuid().ToString())
            .Options;
    }

    private IConfiguration CreateMockConfiguration()
    {
        var settings = new System.Collections.Generic.Dictionary<string, string>
        {
            {"JwtSettings:Secret", "super_secret_key_rentlanka_1234567890_long_enough"},
            {"JwtSettings:Issuer", "RentLanka"},
            {"JwtSettings:Audience", "RentLankaUsers"},
            {"JwtSettings:ExpiryInMinutes", "5"} // short lifetime for testing
        };

        return new ConfigurationBuilder()
            .AddInMemoryCollection(settings)
            .Build();
    }

    [Fact]
    public async Task LoginAsync_ShouldGenerateTokenAndStoreHashedRefreshToken_WhenCredentialsAreValid()
    {
        // Arrange
        var options = CreateInMemoryDatabaseOptions();
        using var context = new AppDbContext(options);
        var config = CreateMockConfiguration();
        
        var user = new User
        {
            Id = Guid.NewGuid(),
            Email = "test@example.com",
            PasswordHash = BC.HashPassword("Password123!"),
            FirstName = "John",
            LastName = "Doe",
            Role = "Renter"
        };
        context.Users.Add(user);
        await context.SaveChangesAsync();

        var service = new IdentityService(context, config);

        // Act
        var (succeeded, token, refreshToken, error) = await service.LoginAsync("test@example.com", "Password123!");

        // Assert
        Assert.True(succeeded);
        Assert.NotNull(token);
        Assert.NotNull(refreshToken);
        Assert.Null(error);

        // Verify the database has the HASHED refresh token (not plaintext)
        var updatedUser = await context.Users.FirstAsync(u => u.Id == user.Id);
        Assert.NotNull(updatedUser.RefreshTokenHash);
        Assert.NotEqual(refreshToken, updatedUser.RefreshTokenHash);
        Assert.NotNull(updatedUser.RefreshTokenExpiry);
        Assert.True(updatedUser.RefreshTokenExpiry > DateTime.UtcNow);
    }

    [Fact]
    public async Task RefreshTokenAsync_ShouldRotateTokens_WhenValidTokensAreProvided()
    {
        // Arrange
        var options = CreateInMemoryDatabaseOptions();
        using var context = new AppDbContext(options);
        var config = CreateMockConfiguration();
        
        var user = new User
        {
            Id = Guid.NewGuid(),
            Email = "test@example.com",
            PasswordHash = BC.HashPassword("Password123!"),
            FirstName = "John",
            LastName = "Doe",
            Role = "Renter"
        };
        context.Users.Add(user);
        await context.SaveChangesAsync();

        var service = new IdentityService(context, config);

        // Log in first to generate initial tokens
        var (_, loginToken, loginRefreshToken, _) = await service.LoginAsync("test@example.com", "Password123!");

        // Act
        var (refreshSucceeded, newToken, newRefreshToken, refreshError) = 
            await service.RefreshTokenAsync(loginToken!, loginRefreshToken!);

        // Assert
        Assert.True(refreshSucceeded);
        Assert.NotNull(newToken);
        Assert.NotNull(newRefreshToken);
        Assert.NotEqual(loginToken, newToken);
        Assert.NotEqual(loginRefreshToken, newRefreshToken);
        Assert.Null(refreshError);

        // Verify the old refresh token is revoked (immediate rotation)
        var (retrySucceeded, _, _, retryError) = 
            await service.RefreshTokenAsync(loginToken!, loginRefreshToken!);
        Assert.False(retrySucceeded);
        Assert.Equal("Invalid or expired refresh token.", retryError);
    }
}
