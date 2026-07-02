using System;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using RentLanka.Api.Data;
using RentLanka.Api.Models.Entities;
using RentLanka.Api.Models.Requests;

namespace RentLanka.Api.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public class NotificationsController : AuthorizedControllerBase
{
    private readonly AppDbContext _dbContext;

    public NotificationsController(AppDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    [HttpPost("token")]
    public async Task<IActionResult> RegisterDeviceToken([FromBody] RegisterDeviceTokenRequest request)
    {
        if (!ModelState.IsValid)
        {
            return BadRequest(ModelState);
        }

        var userId = GetUserId();

        // Check if the user exists
        var userExists = await _dbContext.Users.AnyAsync(u => u.Id == userId);
        if (!userExists)
        {
            return NotFound(new { Error = "User not found." });
        }

        // Check if this token is already registered
        var existingToken = await _dbContext.DeviceTokens.FirstOrDefaultAsync(dt => dt.Token == request.Token);

        if (existingToken != null)
        {
            // Update mapping to current user and platform
            existingToken.UserId = userId;
            existingToken.Platform = request.Platform;
            existingToken.CreatedAt = DateTime.UtcNow;
            _dbContext.DeviceTokens.Update(existingToken);
        }
        else
        {
            // Register new device token
            var newDeviceToken = new DeviceToken
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                Token = request.Token,
                Platform = request.Platform,
                CreatedAt = DateTime.UtcNow
            };
            await _dbContext.DeviceTokens.AddAsync(newDeviceToken);
        }

        await _dbContext.SaveChangesAsync();

        return Ok(new { Message = "Device token registered successfully." });
    }
}
