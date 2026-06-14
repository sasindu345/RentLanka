using System;
using System.Security.Claims;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using RentLanka.Api.Data;
using RentLanka.Api.Services.Interfaces;

namespace RentLanka.Api.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public class FileController : ControllerBase
{
    private readonly IFileStorageService _fileStorage;
    private readonly AppDbContext _dbContext;

    public FileController(IFileStorageService fileStorage, AppDbContext dbContext)
    {
        _fileStorage = fileStorage;
        _dbContext = dbContext;
    }

    [HttpPost("avatar")]
    public async Task<IActionResult> UploadAvatar(IFormFile file)
    {
        if (file == null || file.Length == 0)
        {
            return BadRequest(new { Error = "No file uploaded." });
        }

        if (!file.ContentType.StartsWith("image/"))
        {
            return BadRequest(new { Error = "Only image uploads are allowed." });
        }

        var userIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrEmpty(userIdClaim))
        {
            return Unauthorized();
        }

        var userId = Guid.Parse(userIdClaim);
        var dbUser = await _dbContext.Users.FirstOrDefaultAsync(u => u.Id == userId);
        if (dbUser == null)
        {
            return NotFound(new { Error = "User not found." });
        }

        // Delete old avatar if exists
        if (!string.IsNullOrEmpty(dbUser.AvatarUrl))
        {
            await _fileStorage.DeleteFileAsync(dbUser.AvatarUrl);
        }

        // Upload new avatar
        using var stream = file.OpenReadStream();
        var avatarUrl = await _fileStorage.UploadFileAsync(stream, file.FileName, file.ContentType);

        dbUser.AvatarUrl = avatarUrl;
        dbUser.UpdatedAt = DateTime.UtcNow;
        await _dbContext.SaveChangesAsync();

        return Ok(new { AvatarUrl = avatarUrl, Message = "Avatar updated successfully." });
    }
}
